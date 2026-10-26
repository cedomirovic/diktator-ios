import Foundation
import UIKit

@MainActor
final class AppStanje: ObservableObject {
    @Published var stanje: StanjeAplikacije = .mirno
    @Published var izabraniTab = 0
    @Published var poslednjiTekst = ""
    @Published var nivo: Float = 0
    @Published var poruka: String?
    @Published var podesavanja: Podesavanja = SkladistePodesavanja.ucitaj()
    @Published var istorija: [Zapis] = IstorijaSkladiste.ucitaj()
    @Published var recnik: String = Recnik.ucitaj()
    @Published var modelSePreuzima = false
    @Published var napredakPreuzimanja: Double?

    private let snimac = Snimac()
    private let prepisivac = Prepisivac()
    private var preuzimac: Preuzimac?
    private var timerOslobadjanja: Timer?
    private var timerSnimanja: Timer?

    init() {
        Prepisivac.utisajLog()
        snimac.naNivo = { [weak self] nivo in
            self?.nivo = nivo
        }
    }

    deinit {
        timerOslobadjanja?.invalidate()
        timerSnimanja?.invalidate()
        prepisivac.oslobodiSada()
    }

    // MARK: - URL scheme

    func obradiURL(_ url: URL) {
        guard url.scheme?.lowercased() == "diktator-ios" else { return }
        if url.host?.lowercased() == "dictate" {
            izabraniTab = 0
            pocniSnimanje()
        }
    }

    // MARK: - Snimanje i prepis

    func pocniSnimanje() {
        guard !stanje.jeSnimanje, !stanje.jeZauzet else { return }
        if case .greska = stanje {
            stanje = .mirno
        }

        Task { @MainActor in
            if Snimac.dozvola != .authorized {
                let dozvoljeno = await Snimac.traziDozvolu()
                guard dozvoljeno else {
                    stanje = .greska(
                        "Diktator nema dozvolu za mikrofon. Otvori Podešavanja → Privatnost i bezbednost → Mikrofon."
                    )
                    return
                }
            }

            do {
                try snimac.pocni()
                stanje = .snima
                poruka = nil
                pokreniTimerSnimanja()
            } catch {
                stanje = .greska(error.localizedDescription)
            }
        }
    }

    func zaustaviSnimanje() {
        guard stanje.jeSnimanje else { return }
        timerSnimanja?.invalidate()
        timerSnimanja = nil

        let uzorci = snimac.zaustavi()
        nivo = 0
        let trajanje = Snimac.trajanje(uzorci.count)

        guard trajanje >= 0.6 else {
            stanje = .greska("Snimak je prekratak — drži mikrofon dok govoriš.")
            oslobodiModelPosle()
            return
        }

        let ocisceni = Snimac.skratiTisinu(uzorci)
        guard !ocisceni.isEmpty else {
            stanje = .greska("Nisam čuo govor. Pokušaj ponovo.")
            oslobodiModelPosle()
            return
        }

        guard let model = Modeli.nadji(podesavanja.model), model.preuzet else {
            stanje = .greska("Model nije preuzet. Otvori Podešavanja i preuzmi model.")
            return
        }

        let jezik = podesavanja.jezik
        let rezim = RezimPrepisa.iz(podesavanja.rezimPrepisa)
        let prompt = Recnik.kaoPrompt(recnik)
        stanje = .priprema

        let prepisivac = self.prepisivac
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try prepisivac.ucitaj(putanja: model.putanja.path)
                let tekst = try prepisivac.prepisi(
                    uzorci: ocisceni,
                    jezik: jezik,
                    recnik: prompt,
                    rezim: rezim
                )
                let jezikPrepisa = prepisivac.jezikZadnjegPrepisa()
                DispatchQueue.main.async { [weak self] in
                    self?.zavrsiPrepis(tekst, trajanje: trajanje, jezik: jezikPrepisa)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.stanje = .greska(error.localizedDescription)
                    self?.oslobodiModelPosle()
                }
            }
        }
    }

    private func zavrsiPrepis(_ tekst: String, trajanje: Double, jezik: String) {
        let sredjen = Tekst.sredi(tekst)
        guard !sredjen.isEmpty else {
            stanje = .greska("Nisam prepoznao govor. Pokušaj ponovo, malo glasnije.")
            oslobodiModelPosle()
            return
        }

        poslednjiTekst = sredjen
        UIPasteboard.general.string = sredjen

        if podesavanja.cuvajIstoriju {
            istorija.insert(
                Zapis(tekst: sredjen, trajanje: trajanje, jezik: jezik),
                at: 0
            )
            if istorija.count > 200 {
                istorija = Array(istorija.prefix(200))
            }
            IstorijaSkladiste.sacuvaj(istorija)
        }

        stanje = .mirno
        poruka = "Tekst je kopiran. Vrati se u aplikaciju i tapni Nalepi."
        oslobodiModelPosle()
    }

    private func pokreniTimerSnimanja() {
        timerSnimanja?.invalidate()
        timerSnimanja = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(Snimac.najduzeSekundi),
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor in
                self?.zaustaviSnimanje()
            }
        }
    }

    // MARK: - Modeli

    var modelJePreuzet: Bool {
        Modeli.nadji(podesavanja.model)?.preuzet == true
    }

    func preuzmiModel(_ model: PonudaModela) {
        guard !modelSePreuzima else { return }
        if model.preuzet {
            podesavanja.model = model.id
            SkladistePodesavanja.sacuvaj(podesavanja)
            poruka = "Model \(model.naziv) je već preuzet i izabran."
            return
        }

        modelSePreuzima = true
        napredakPreuzimanja = 0
        poruka = nil

        let p = Preuzimac()
        preuzimac = p
        p.naNapredak = { [weak self] napredak in
            Task { @MainActor [weak self] in
                self?.napredakPreuzimanja = napredak
            }
        }
        p.naKraj = { [weak self] rezultat in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.modelSePreuzima = false
                self.preuzimac = nil
                switch rezultat {
                case .success:
                    self.podesavanja.model = model.id
                    SkladistePodesavanja.sacuvaj(self.podesavanja)
                    self.napredakPreuzimanja = 1
                    self.poruka = "Model \(model.naziv) je preuzet."
                case .failure(let greska):
                    self.napredakPreuzimanja = nil
                    self.poruka = greska.localizedDescription
                }
            }
        }
        p.pocni(od: model.url, u: model.putanja, velicina: model.velicina)
    }

    func izaberiModel(_ model: PonudaModela) {
        if model.preuzet {
            podesavanja.model = model.id
            SkladistePodesavanja.sacuvaj(podesavanja)
            prepisivac.oslobodi()
            poruka = "Izabran je model \(model.naziv)."
        } else {
            preuzmiModel(model)
        }
    }

    func oslobodiModel() {
        timerOslobadjanja?.invalidate()
        timerOslobadjanja = nil
        prepisivac.oslobodi()
        poruka = "Model je oslobođen iz memorije."
    }

    private func oslobodiModelPosle() {
        timerOslobadjanja?.invalidate()
        timerOslobadjanja = nil
        guard let sekunde = OslobadjanjeModela.iz(podesavanja.oslobadjanjeModela).sekunde else {
            return
        }
        let prepisivac = self.prepisivac
        timerOslobadjanja = Timer.scheduledTimer(
            withTimeInterval: max(1, sekunde),
            repeats: false
        ) { _ in
            prepisivac.oslobodi()
        }
    }

    // MARK: - Podešavanja, istorija, rečnik

    func sacuvajPodesavanja() {
        SkladistePodesavanja.sacuvaj(podesavanja)
        prepisivac.oslobodi()
        oslobodiModelPosle()
    }

    func sacuvajRecnik() {
        Recnik.sacuvaj(recnik)
        poruka = "Rečnik je sačuvan."
    }

    func obrisiIstoriju() {
        istorija = []
        IstorijaSkladiste.sacuvaj([])
        poruka = "Istorija je obrisana."
    }

    func kopiraj(_ tekst: String) {
        guard !tekst.isEmpty else { return }
        UIPasteboard.general.string = tekst
        poruka = "Kopirano u clipboard."
    }

    func kopirajPoslednji() {
        kopiraj(poslednjiTekst)
    }

    func proveriModel() {
        guard !modelJePreuzet, !modelSePreuzima, poruka == nil else { return }
        poruka = "Model nije preuzet. Otvori Podešavanja i preuzmi Large v3."
    }
}
