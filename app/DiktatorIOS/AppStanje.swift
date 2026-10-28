import Foundation
import Network
import UIKit

/// Dijagnostika ide i u fajl, jer se NSLog iz aplikacije i tastature na
/// iOS 26 ne pojavljuje uvek u idevicesyslog toku.
enum Dnevnik {
    static let putanja: URL = {
        let folder = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        return folder.appendingPathComponent("diktator-dnevnik.txt")
    }()

    static func pisi(_ tekst: String) {
        let red = "\(Date().formatted(date: .numeric, time: .standard)) \(tekst)\n"
        guard let podaci = red.data(using: .utf8) else { return }
        if FileManager.default.fileExists(atPath: putanja.path) {
            guard let rucica = try? FileHandle(forWritingTo: putanja) else { return }
            rucica.seekToEndOfFile()
            rucica.write(podaci)
            try? rucica.close()
        } else {
            try? podaci.write(to: putanja)
        }
    }
}

private enum DiktatorClipboard {
    static let tekst = "public.utf8-plain-text"
    static let token = "com.cedomirovic.diktator.token"
    static let vreme = "com.cedomirovic.diktator.vreme"
}

/// Imenovani pasteboard-i su dostupni aplikaciji i njenom extension-u sa
/// istim Team ID-jem, pa ne zahtevaju App Group. Koristimo ih za komande
/// tastature i za status sesije, da ne diramo korisnikov clipboard.
private enum DiktatorIPC {
    static let komande = UIPasteboard.Name(rawValue: "com.cedomirovic.diktator.komande")
    static let stanje = UIPasteboard.Name(rawValue: "com.cedomirovic.diktator.stanje")
    static let komanda = "komanda"
    static let id = "id"
    static let vreme = "vreme"
    static let sesija = "sesija"
    static let sesijaDo = "sesijaDo"
    static let stanjeKljuc = "stanje"
    static let token = "token"
    static let tokenVreme = "tokenVreme"
    static let tekst = "tekst"
    static let greska = "greska"

    /// Darwin notifikacije prenose samo ime, pa u njega pakujemo kratku
    /// poruku. Tako tastatura i aplikacija rade i ako imenovani pasteboard
    /// nije dostupan u extension-u.
    static let notifPrefiks = "com.cedomirovic.diktator"
    static let notifKomanda = "com.cedomirovic.diktator.cmd"
    static let notifStanje = "com.cedomirovic.diktator.st"

    static func tabla(_ ime: UIPasteboard.Name) -> UIPasteboard? {
        UIPasteboard(name: ime, create: true)
    }

    static func pisi(_ ime: UIPasteboard.Name, _ vrednosti: [String: String]) {
        guard let tabla = tabla(ime) else { return }
        tabla.items = [vrednosti.mapValues { Data($0.utf8) }]
    }

    static func citaj(_ ime: UIPasteboard.Name) -> [String: String] {
        guard let predmet = tabla(ime)?.items.first else { return [:] }
        var rezultat: [String: String] = [:]
        for (kljuc, vrednost) in predmet {
            if let tekst = vrednost as? String {
                rezultat[kljuc] = tekst
            } else if let podaci = vrednost as? Data,
                      let tekst = String(data: podaci, encoding: .utf8) {
                rezultat[kljuc] = tekst
            }
        }
        return rezultat
    }

    static func posaljiNotifikaciju(_ ime: String) {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(rawValue: ime as CFString),
            nil,
            nil,
            true
        )
    }

    static func imeKomande(_ komanda: String, id: String, vreme: Double) -> String {
        let ms = Int(vreme * 1000)
        return "\(notifKomanda).\(komanda).\(id).\(ms)"
    }

    /// Fiksna imena su pouzdana za Darwin opserver koji se registruje na
    /// tačan naziv. Dinamički deo (ID, vreme) ide preko pasteboard-a.
    static func imeKomandeFiksno(_ komanda: String, broj: Int) -> String {
        "\(notifKomanda).\(komanda).\(broj)"
    }

    static func imeStanjaFiksno(sesija: Bool, stanje: String) -> String {
        "\(notifStanje).\(sesija ? 1 : 0).\(stanje)"
    }

    static func imeStanja(
        sesija: Bool,
        stanje: String,
        vreme: Double,
        sesijaDo: Double
    ) -> String {
        let ms = Int(vreme * 1000)
        let doMs = Int(sesijaDo * 1000)
        return "\(notifStanje).\(sesija ? 1 : 0).\(stanje).\(ms).\(doMs)"
    }
}

@MainActor
final class AppStanje: ObservableObject {
    @Published var stanje: StanjeAplikacije = .mirno
    @Published var izabraniTab = 0
    @Published var poslednjiTekst = ""
    @Published var nivo: Float = 0
    @Published var poruka: String?
    @Published var podesavanja: Podesavanja = SkladistePodesavanja.ucitaj()
    @Published var istorija: [Zapis] = IstorijaSkladiste.ucitaj()
    @Published var statistika: Statistika = StatistikaSkladiste.ucitaj()
    @Published var recnik: String = Recnik.ucitaj()
    @Published var modelSePreuzima = false
    @Published var napredakPreuzimanja: Double?
    @Published var sesijaAktivna = false
    @Published var sesijaPreostalo = 0
    @Published var dostupnoAzuriranje: Azuriranje?
    @Published var proveravaAzuriranja = false
    @Published var porukaAzuriranja: String?
    @Published var porukaObavestenja: String?
    @Published var obavestenjaOdbijena = false
    @Published var kljucDoterivanja = ""
    @Published var testiraDoterivanje = false
    @Published var porukaDoterivanja: String?
    @Published var kljucOblaka = ""
    @Published var testiraOblak = false
    @Published var porukaOblaka: String?

    private let snimac = Snimac()
    private let prepisivac = Prepisivac()
    private let server = ServerTeksta()
    private var preuzimac: Preuzimac?
    private var timerOslobadjanja: Timer?
    private var timerSnimanja: Timer?
    private var timerSesije: Timer?
    private var timerIPC: Timer?
    private var timerIPCHeartbeat: DispatchSourceTimer?
    private var sesijaKraj: Date?
    private var zadatakUPozadini: UIBackgroundTaskIdentifier = .invalid
    private var pokrenutSaTastature = false
    private var tekstBrojac = 0
    private var zadnjiIPCtoken: String?
    private var zadnjiIPCtokenVreme: Double?
    private var zadnjiKomandniId: String?
    private var zadnjiDnevnikStanja = ""
    private var proveraAzuriranjaUToku = false
    private var proveraObavestenjaUToku = false

    init() {
        Prepisivac.utisajLog()
        snimac.naNivo = { [weak self] nivo in
            self?.nivo = nivo
        }

        // Prvi put posle uvođenja statistike: izvedi je iz postojeće
        // istorije, da korisnik ne počne od nule.
        let kljucMigracije = "diktator.statistika.migrirana.v1"
        if !UserDefaults.standard.bool(forKey: kljucMigracije) {
            if statistika.ukupnoSnimaka == 0, !istorija.isEmpty {
                statistika = Statistika.iz(istorija)
                StatistikaSkladiste.sacuvaj(statistika)
            }
            UserDefaults.standard.set(true, forKey: kljucMigracije)
        }

        dostupnoAzuriranje = Azuriranja.kesirano()
        kljucDoterivanja = Kljuc.citaj(za: podesavanja.provajderDoterivanja) ?? ""
        kljucOblaka = Kljuc.citaj(za: "groq") ?? ""

        let centar = CFNotificationCenterGetDarwinNotifyCenter()
        let osmatrac = Unmanaged.passUnretained(self).toOpaque()
        for komanda in ["start", "stop", "ping"] {
            for broj in 0...9 {
                CFNotificationCenterAddObserver(
                    centar,
                    osmatrac,
                    { _, observer, ime, _, _ in
                        guard let observer, let ime else { return }
                        let stanje = Unmanaged<AppStanje>.fromOpaque(observer).takeUnretainedValue()
                        let tekst = ime.rawValue as String
                        Task { @MainActor in
                            stanje.primljenaNotifikacija(tekst)
                        }
                    },
                    DiktatorIPC.imeKomandeFiksno(komanda, broj: broj) as CFString,
                    nil,
                    .deliverImmediately
                )
            }
        }
    }

    deinit {
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            nil,
            nil
        )
        timerOslobadjanja?.invalidate()
        timerSnimanja?.invalidate()
        timerSesije?.invalidate()
        timerIPC?.invalidate()
        timerIPCHeartbeat?.cancel()
        snimac.zavrsiSesiju()
        server.zaustavi()
        prepisivac.oslobodiSada()
    }

    // MARK: - URL scheme

    func obradiURL(_ url: URL) {
        guard url.scheme?.lowercased() == "diktator-ios" else { return }
        Dnevnik.pisi("URL \(url.absoluteString), sesija=\(sesijaAktivna)")

        switch url.host?.lowercased() {
        case "dictate":
            izabraniTab = 0
            Task { @MainActor in
                if !sesijaAktivna {
                    guard await ukljuciSesijuAsync() else { return }
                }
                pocniSnimanje(saTastature: true)
            }
        case "sesija-prikaz":
            // Tastatura je otvorila aplikaciju jer sesija nije uključena.
            // Ne uključujemo je sami, nego pokažemo dugme i uputstvo.
            izabraniTab = 0
            if !sesijaAktivna {
                poruka = "Tapni Uključi sesiju, pa se vrati u aplikaciju i tapni Diktiraj."
            }
        case "sesija":
            izabraniTab = 0
            Task { @MainActor in
                if await ukljuciSesijuAsync() {
                    // Korisnik je već tapnuo Diktiraj, pa odmah počinjemo.
                    // Tastatura posle povratka samo preuzima status.
                    pocniSnimanje(saTastature: true)
                }
            }
        case "stop":
            if stanje.jeSnimanje {
                zaustaviSnimanje()
            }
        default:
            break
        }
    }

    // MARK: - Pozadinska sesija

    func ukljuciSesiju() {
        Task { @MainActor in
            _ = await ukljuciSesijuAsync()
        }
    }

    @discardableResult
    private func ukljuciSesijuAsync() async -> Bool {
        Dnevnik.pisi("ukljuciSesijuAsync početak, sesija=\(sesijaAktivna)")
        if sesijaAktivna {
            pisiIPCStanje()
            return true
        }
        guard !stanje.jeSnimanje else {
            Dnevnik.pisi("ukljuciSesijuAsync odbijeno: snimanje je u toku")
            return false
        }
        guard await osigurajDozvolu() else {
            Dnevnik.pisi("ukljuciSesijuAsync odbijeno: nema dozvole za mikrofon")
            return false
        }
        let model = modelZaPrepis
        guard (model?.preuzet == true) || oblakSpreman else {
            stanje = .greska("Model nije preuzet. Otvori Podešavanja i preuzmi model.")
            Dnevnik.pisi("ukljuciSesijuAsync odbijeno: model nije preuzet")
            pisiIPCStanje()
            return false
        }

        do {
            try snimac.pocniSesiju()
        } catch {
            stanje = .greska(error.localizedDescription)
            Dnevnik.pisi("ukljuciSesijuAsync greška: \(error.localizedDescription)")
            pisiIPCStanje()
            return false
        }

        if case .greska = stanje {
            stanje = .mirno
        }
        sesijaAktivna = true
        // Model se učitava odmah, dok korisnik prelazi u drugu aplikaciju, da
        // prvi Diktiraj ne čeka na učitavanje. U sesiji se koristi CPU, jer
        // Metal u pozadini nije dostupan.
        if !podesavanja.prepisOblak, let model, model.preuzet {
            let prepisivac = self.prepisivac
            let putanja = model.putanja.path
            DispatchQueue.global(qos: .utility).async {
                try? prepisivac.ucitaj(putanja: putanja, useGPU: false)
            }
        }
        sesijaPreostalo = Snimac.najduzeSesijeSekundi
        sesijaKraj = Date().addingTimeInterval(TimeInterval(Snimac.najduzeSesijeSekundi))
        pokreniTimerSesije()
        pokreniIPCHeartbeat()
        server.postaviTekst(poslednjiTekst)
        server.pokreni()
        pisiIPCStanje()
        Dnevnik.pisi("Sesija uključena, traje do \(Snimac.najduzeSesijeSekundi) s.")
        NSLog("Diktator: sesija uključena, traje do %d s.", Snimac.najduzeSesijeSekundi)
        poruka = "Sesija je aktivna. Pređi u drugu aplikaciju i tapni Diktiraj na tastaturi."
        return true
    }

    func zavrsiSesiju() {
        guard sesijaAktivna else { return }
        if stanje.jeSnimanje {
            zaustaviSnimanje()
        }

        timerSesije?.invalidate()
        timerSesije = nil
        timerIPC?.invalidate()
        timerIPC = nil
        timerIPCHeartbeat?.cancel()
        timerIPCHeartbeat = nil
        snimac.zavrsiSesiju()
        server.zaustavi()
        sesijaAktivna = false
        sesijaKraj = nil
        sesijaPreostalo = 0
        pisiIPCStanje()
        Dnevnik.pisi("Sesija završena.")
        NSLog("Diktator: sesija završena.")
        poruka = "Sesija je završena. Otvori Diktator i uključi sesiju ponovo."
        oslobodiModelPosle()
    }

    func osveziIPC() {
        pisiIPCStanje()
    }

    // MARK: - Ažuriranja

    func proveriAzuriranja(prisilno: Bool = false) {
        // „Proveri sada“ radi i kada je automatska provera isključena.
        guard prisilno || podesavanja.proveravajAzuriranja else { return }
        guard !proveraAzuriranjaUToku else { return }
        proveraAzuriranjaUToku = true
        proveravaAzuriranja = true
        if prisilno {
            porukaAzuriranja = nil
        }

        Task { @MainActor in
            defer {
                proveraAzuriranjaUToku = false
                proveravaAzuriranja = false
            }
            switch await Azuriranja.proveri(prisilno: prisilno) {
            case .dostupno(let azuriranje):
                dostupnoAzuriranje = azuriranje
                porukaAzuriranja = "Dostupna je verzija \(azuriranje.verzija)."
                await Azuriranja.posaljiNotifikaciju(azuriranje)
            case .nema:
                dostupnoAzuriranje = nil
                porukaAzuriranja = "Nema nove verzije. Trenutna je \(Azuriranja.trenutnaVerzija)."
            case .greska:
                porukaAzuriranja = "Provera nije uspela. Proveri internet vezu i pokušaj ponovo."
            }
        }
    }

    func testirajNotifikaciju() {
        guard !proveraObavestenjaUToku else { return }
        proveraObavestenjaUToku = true
        Task { @MainActor in
            defer { proveraObavestenjaUToku = false }
            let status = await Azuriranja.statusDozvole()
            obavestenjaOdbijena = (status == .denied)
            guard status != .denied else {
                porukaObavestenja = "Obaveštenja su isključena za Diktator u iOS Podešavanjima."
                return
            }
            guard Azuriranja.jeDozvoljeno(status) else {
                porukaObavestenja = "iOS nije dozvolio obaveštenja. Pokušaj ponovo u Podešavanjima iOS-a."
                obavestenjaOdbijena = true
                return
            }
            let uspeh = await Azuriranja.posaljiTestnuNotifikaciju()
            porukaObavestenja = uspeh
                ? "Testno obaveštenje je poslato — treba da se pojavi odmah."
                : "Obaveštenje nije poslato. Proveri dozvolu u iOS Podešavanjima."
            obavestenjaOdbijena = !uspeh
        }
    }

    func zatraziDozvoluZaObavestenja() {
        Task { @MainActor in
            let status = await Azuriranja.statusDozvole()
            obavestenjaOdbijena = (status == .denied)
            if status == .denied {
                porukaObavestenja = "Obaveštenja su isključena za Diktator u iOS Podešavanjima."
            }
        }
    }

    func otvoriPodesavanjaIOS() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func osigurajDozvolu() async -> Bool {
        if Snimac.dozvola == .authorized {
            return true
        }
        let dozvoljeno = await Snimac.traziDozvolu()
        if !dozvoljeno {
            stanje = .greska(
                "Diktator nema dozvolu za mikrofon. Otvori Podešavanja → Privatnost i bezbednost → Mikrofon."
            )
            pisiIPCStanje()
        }
        return dozvoljeno
    }

    // MARK: - Snimanje i prepis

    func pocniSnimanje(saTastature: Bool = false) {
        guard !stanje.jeSnimanje, !stanje.jeZauzet else { return }
        Dnevnik.pisi("pocniSnimanje(saTastature=\(saTastature))")
        pokrenutSaTastature = saTastature
        if case .greska = stanje {
            stanje = .mirno
        }

        Task { @MainActor in
            guard await osigurajDozvolu() else { return }

            do {
                try snimac.pocni()
                stanje = .snima
                poruka = nil
                pokreniTimerSnimanja()
                pisiIPCStanje()
            } catch {
                stanje = .greska(error.localizedDescription)
                pisiIPCStanje()
            }
        }
    }

    func zaustaviSnimanje() {
        guard stanje.jeSnimanje else { return }
        Dnevnik.pisi("zaustaviSnimanje")
        timerSnimanja?.invalidate()
        timerSnimanja = nil

        let uzorci = snimac.zaustavi()
        nivo = 0
        let trajanje = Snimac.trajanje(uzorci.count)
        Dnevnik.pisi(
            "Snimak: uzorci=\(uzorci.count), trajanje=\(String(format: "%.2f", trajanje)) s"
        )

        guard trajanje >= 0.6 else {
            stanje = .greska("Snimak je prekratak — drži mikrofon dok govoriš.")
            pisiIPCStanje()
            oslobodiModelPosle()
            return
        }

        let ocisceni = Snimac.skratiTisinu(uzorci)
        if let najmanji = ocisceni.min(), let najveci = ocisceni.max() {
            let rms = sqrt(
                ocisceni.reduce(0) { $0 + $1 * $1 } / Float(max(1, ocisceni.count))
            )
            let nekonacni = ocisceni.contains { !$0.isFinite }
            Dnevnik.pisi(
                "Uzorci: min=\(String(format: "%.4f", najmanji)), max=\(String(format: "%.4f", najveci)), rms=\(String(format: "%.4f", rms)), nekonacni=\(nekonacni)"
            )
        }
        Dnevnik.pisi("Posle skracivanja tisina: uzorci=\(ocisceni.count)")
        guard !ocisceni.isEmpty else {
            stanje = .greska("Nisam čuo govor. Pokušaj ponovo.")
            pisiIPCStanje()
            oslobodiModelPosle()
            return
        }

        let jezik = podesavanja.jezik
        let rezim = RezimPrepisa.iz(podesavanja.rezimPrepisa)
        let prompt = Recnik.kaoPrompt(recnik)
        // Metal u pozadini nije dostupan, a i prelazak GPU/CPU tera ponovno
        // učitavanje modela. Zato GPU koristimo samo za diktat direktno u
        // aplikaciji, dok sesija nije uključena.
        let useGPU = UIApplication.shared.applicationState == .active && !sesijaAktivna
        let kljucOblaka = self.kljucOblaka.trimmingCharacters(in: .whitespacesAndNewlines)

        stanje = .priprema
        pisiIPCStanje()
        pocniZadatakUPozadini()

        if podesavanja.prepisOblak, !kljucOblaka.isEmpty {
            Dnevnik.pisi("Prepis u oblaku (Groq), jezik=\(jezik)")
            pokreniOblakPrepis(
                uzorci: ocisceni,
                trajanje: trajanje,
                jezik: jezik,
                kljuc: kljucOblaka,
                prompt: prompt,
                rezim: rezim,
                useGPU: useGPU
            )
            return
        }

        guard let model = modelZaPrepis, model.preuzet else {
            zavrsiZadatakUPozadini()
            stanje = .greska("Model nije preuzet. Otvori Podešavanja i preuzmi model.")
            pisiIPCStanje()
            return
        }

        Dnevnik.pisi(
            "Prepis pocinje: model=\(model.id), jezik=\(jezik), GPU=\(useGPU), app=\(UIApplication.shared.applicationState.rawValue)"
        )
        pokreniLokalniPrepis(
            uzorci: ocisceni,
            trajanje: trajanje,
            jezik: jezik,
            prompt: prompt,
            rezim: rezim,
            useGPU: useGPU,
            model: model,
            napomena: nil
        )
    }

    /// Prepis u oblaku je najbrži, ali šalje zvuk Groq-u. Ako ne uspe, isti
    /// snimak se prepisuje lokalno, pa korisnik ne ostaje bez teksta.
    private func pokreniOblakPrepis(
        uzorci: [Float],
        trajanje: Double,
        jezik: String,
        kljuc: String,
        prompt: String,
        rezim: RezimPrepisa,
        useGPU: Bool
    ) {
        stanje = .prepisuje
        pisiIPCStanje()
        let model = modelOblaka

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let tekst = try await PrepisOblak.prepisi(
                    uzorci: uzorci,
                    jezik: jezik,
                    kljuc: kljuc,
                    model: model
                )
                Dnevnik.pisi("Oblak prepis gotov, duzina=\(tekst.count)")
                self.zavrsiPrepis(tekst, trajanje: trajanje, jezik: jezik)
            } catch {
                Dnevnik.pisi("Oblak greska: \(error.localizedDescription)")
                guard let lokalni = self.modelZaPrepis, lokalni.preuzet else {
                    self.zavrsiZadatakUPozadini()
                    self.stanje = .greska(
                        "\(error.localizedDescription) Lokalni model nije preuzet, pa nema rezervnog prepisa."
                    )
                    self.pisiIPCStanje()
                    return
                }
                self.stanje = .priprema
                self.pisiIPCStanje()
                self.pokreniLokalniPrepis(
                    uzorci: uzorci,
                    trajanje: trajanje,
                    jezik: jezik,
                    prompt: prompt,
                    rezim: rezim,
                    useGPU: useGPU,
                    model: lokalni,
                    napomena: "Groq nije odgovorio — prepis je urađen na uređaju."
                )
            }
        }
    }

    private func pokreniLokalniPrepis(
        uzorci: [Float],
        trajanje: Double,
        jezik: String,
        prompt: String,
        rezim: RezimPrepisa,
        useGPU: Bool,
        model: PonudaModela,
        napomena: String?
    ) {
        let prepisivac = self.prepisivac
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let pocetak = Date()
                try prepisivac.ucitaj(putanja: model.putanja.path, useGPU: useGPU)
                let ucitavanje = Date().timeIntervalSince(pocetak)
                let tekst = try prepisivac.prepisi(
                    uzorci: uzorci,
                    jezik: jezik,
                    recnik: prompt,
                    rezim: rezim
                )
                let jezikPrepisa = prepisivac.jezikZadnjegPrepisa()
                Dnevnik.pisi(
                    "Model spreman za \(String(format: "%.2f", ucitavanje))s"
                )
                DispatchQueue.main.async { [weak self] in
                    self?.zavrsiPrepis(
                        tekst,
                        trajanje: trajanje,
                        jezik: jezikPrepisa,
                        napomena: napomena
                    )
                }
            } catch {
                Dnevnik.pisi("Prepis greska: \(error.localizedDescription)")
                NSLog("Diktator: prepis greška: %@", error.localizedDescription)
                DispatchQueue.main.async { [weak self] in
                    self?.zavrsiZadatakUPozadini()
                    self?.stanje = .greska(error.localizedDescription)
                    self?.pisiIPCStanje()
                    self?.oslobodiModelPosle()
                }
            }
        }
    }

    private func zavrsiPrepis(
        _ tekst: String,
        trajanje: Double,
        jezik: String,
        napomena: String? = nil
    ) {
        let sredjen = Tekst.sredi(tekst)
        Dnevnik.pisi("Prepis tekst: duzina=\(sredjen.count)")
        guard !sredjen.isEmpty else {
            zavrsiZadatakUPozadini()
            stanje = .greska("Nisam prepoznao govor. Pokušaj ponovo, malo glasnije.")
            pisiIPCStanje()
            oslobodiModelPosle()
            return
        }

        let provajder = provajderDoterivanja
        let kljuc = kljucDoterivanja.trimmingCharacters(in: .whitespacesAndNewlines)
        let trebaKljuc = provajder.traziKljuc && kljuc.isEmpty

        guard podesavanja.doterivanje else {
            dovrsiPrepis(sredjen, trajanje: trajanje, jezik: jezik, napomena: napomena)
            return
        }

        guard !trebaKljuc else {
            dovrsiPrepis(
                sredjen,
                trajanje: trajanje,
                jezik: jezik,
                napomena: [napomena, "Doterivanje je preskočeno — \(provajder.naziv) ključ nije unet."]
                    .compactMap { $0 }
                    .joined(separator: " ")
            )
            return
        }

        stanje = .doteruje
        pisiIPCStanje()
        let model = modelDoterivanja
        let adresa = adresaDoterivanja

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let doteran = try await Doterivac.doteraj(
                    sredjen,
                    provajder: provajder,
                    kljuc: kljuc,
                    model: model,
                    adresa: adresa,
                    jezik: jezik
                )
                Dnevnik.pisi("Doterivanje gotovo, duzina=\(doteran.count)")
                self.dovrsiPrepis(
                    doteran,
                    trajanje: trajanje,
                    jezik: jezik,
                    napomena: napomena
                )
            } catch {
                Dnevnik.pisi("Doterivanje greska: \(error.localizedDescription)")
                let greska = "Doterivanje nije uspelo (\(provajder.naziv)) — ostavljen je sirov prepis."
                self.dovrsiPrepis(
                    sredjen,
                    trajanje: trajanje,
                    jezik: jezik,
                    napomena: napomena.map { "\($0) \(greska)" } ?? greska
                )
            }
        }
    }

    private func dovrsiPrepis(
        _ tekst: String,
        trajanje: Double,
        jezik: String,
        napomena: String?
    ) {
        let sredjen = Tekst.sredi(tekst)
        guard !sredjen.isEmpty else {
            zavrsiZadatakUPozadini()
            stanje = .greska("Doterivanje je vratilo prazan tekst.")
            pisiIPCStanje()
            oslobodiModelPosle()
            return
        }

        poslednjiTekst = sredjen
        server.postaviTekst(sredjen)
        statistika.dodaj(
            tekst: sredjen,
            trajanje: trajanje,
            jezik: jezik
        )
        StatistikaSkladiste.sacuvaj(statistika)
        Dnevnik.pisi("Prepis gotov, dužina=\(sredjen.count), saTastature=\(pokrenutSaTastature)")
        let token = postaviClipboard(sredjen, automatski: pokrenutSaTastature)
        zadnjiIPCtoken = token
        zadnjiIPCtokenVreme = token == nil ? nil : Date().timeIntervalSince1970

        if pokrenutSaTastature {
            posaljiTekstTastaturi(sredjen)
        }

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
        pisiIPCStanje()

        if let napomena, !napomena.isEmpty {
            poruka = napomena
        } else if pokrenutSaTastature {
            poruka = "Tekst je spreman. Vrati se u tastaturu i tapni Nalepi."
        } else {
            poruka = "Tekst je kopiran. Otvori tastaturu i tapni Nalepi."
        }
        zavrsiZadatakUPozadini()
        oslobodiModelPosle()
    }

    /// Tekst ide u opšti clipboard kao čist string. Tastatura ga čita
    /// dugmetom Nalepi; nema automatskog lepljenja ni tokena.
    @discardableResult
    private func postaviClipboard(_ tekst: String, automatski: Bool) -> String? {
        UIPasteboard.general.string = tekst
        Dnevnik.pisi("Clipboard spreman, duzina=\(tekst.count)")
        NSLog("Diktator: clipboard spreman, duzina=%d", tekst.count)
        return nil
    }

    /// Tekst šaljemo tastaturi preko zasebnog imenovanog pasteboard-a i
    /// Darwin notifikacije. Ime se menja po brojaču, a stari pasteboard se
    /// briše pre upisa, da keyboard extension ne bi vratio keširanu vrednost.
    private func posaljiTekstTastaturi(_ tekst: String) {
        tekstBrojac = (tekstBrojac + 1) % 10
        let base64 = Data(tekst.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let ime = "com.cedomirovic.diktator.tekst.\(tekstBrojac).\(base64)"
        DiktatorIPC.posaljiNotifikaciju(ime)
        Dnevnik.pisi(
            "Tekst poslat notifikacijom: duzina=\(tekst.count), ime=\(ime.count) znakova"
        )
    }

    private var stanjeIPC: String {
        switch stanje {
        case .snima:
            return "snima"
        case .priprema, .prepisuje, .doteruje:
            return "obrada"
        case .greska:
            return "greska"
        case .mirno:
            return "mirno"
        }
    }

    private func pisiIPCStanje() {
        let sada = Date().timeIntervalSince1970
        let stanjeTekst = stanjeIPC
        var vrednosti: [String: String] = [
            DiktatorIPC.sesija: sesijaAktivna ? "1" : "0",
            DiktatorIPC.stanjeKljuc: stanjeTekst,
            DiktatorIPC.vreme: String(sada)
        ]

        if sesijaAktivna, let kraj = sesijaKraj {
            vrednosti[DiktatorIPC.sesijaDo] = String(kraj.timeIntervalSince1970)
        }

        if let token = zadnjiIPCtoken {
            vrednosti[DiktatorIPC.token] = token
        }
        if let tokenVreme = zadnjiIPCtokenVreme {
            vrednosti[DiktatorIPC.tokenVreme] = String(tokenVreme)
        }
        if !poslednjiTekst.isEmpty {
            vrednosti[DiktatorIPC.tekst] = poslednjiTekst
        }
        if case .greska(let poruka) = stanje {
            vrednosti[DiktatorIPC.greska] = poruka
        }

        DiktatorIPC.pisi(DiktatorIPC.stanje, vrednosti)
        DiktatorIPC.posaljiNotifikaciju(
            DiktatorIPC.imeStanjaFiksno(sesija: sesijaAktivna, stanje: stanjeTekst)
        )

        let kljuc = "\(sesijaAktivna)-\(stanjeTekst)-\(zadnjiIPCtoken ?? "-")"
        if kljuc != zadnjiDnevnikStanja {
            zadnjiDnevnikStanja = kljuc
            Dnevnik.pisi(
                "Status: sesija=\(sesijaAktivna) stanje=\(stanjeTekst) token=\(zadnjiIPCtoken ?? "-") tekst=\(poslednjiTekst.count) kljucevi=\(vrednosti.keys.sorted().joined(separator: ","))"
            )
        }
    }

    /// Timer na glavnom run loop-u ume da stane kada aplikacija ode u pozadinu.
    /// Zato status šaljemo sa pozadinskog reda, a na main actor prelazimo tek
    /// radi pisanja statusa.
    private func pokreniIPCHeartbeat() {
        timerIPCHeartbeat?.cancel()
        let timer = DispatchSource.makeTimerSource(
            queue: DispatchQueue(label: "com.cedomirovic.diktator.ipc.heartbeat")
        )
        timer.schedule(deadline: .now() + 1, repeating: 1)
        timer.setEventHandler { [weak self] in
            Task { @MainActor in
                self?.pisiIPCStanje()
            }
        }
        timer.resume()
        timerIPCHeartbeat = timer
    }

    private func pokreniIPCPolling() {
        timerIPC?.invalidate()
        timerIPC = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.obradiIPCKomandu()
            }
        }
    }

    private func obradiIPCKomandu() {
        let komanda = DiktatorIPC.citaj(DiktatorIPC.komande)
        guard let id = komanda[DiktatorIPC.id],
              !id.isEmpty,
              id != zadnjiKomandniId,
              let vremeString = komanda[DiktatorIPC.vreme],
              let vreme = Double(vremeString),
              Date().timeIntervalSince1970 - vreme < 60 else {
            return
        }

        zadnjiKomandniId = id
        obradiKomandu(komanda[DiktatorIPC.komanda])
    }

    private func obradiKomandu(_ komanda: String?) {
        Dnevnik.pisi("Obrada komande \(komanda ?? "nil"), sesija=\(sesijaAktivna), snima=\(stanje.jeSnimanje)")
        switch komanda {
        case "start":
            if sesijaAktivna {
                pocniSnimanje(saTastature: true)
                pisiIPCStanje()
            } else {
                // Aplikacija je živa, pa može sama da obnovi sesiju. Tastatura
                // tako ne mora da otvori Diktator posle isteka sesije.
                Task { @MainActor in
                    if await ukljuciSesijuAsync() {
                        pocniSnimanje(saTastature: true)
                    }
                    pisiIPCStanje()
                }
            }
        case "stop":
            if stanje.jeSnimanje {
                zaustaviSnimanje()
            } else {
                pisiIPCStanje()
            }
        case "ping":
            pisiIPCStanje()
        default:
            break
        }
    }

    /// Stiže iz tastature preko Darwin notifikacije. Ime je oblika
    /// `com.cedomirovic.diktator.cmd.<komanda>.<id>.<vreme-u-ms>`.
    private func primljenaNotifikacija(_ ime: String) {
        guard ime.hasPrefix(DiktatorIPC.notifKomanda + ".") else { return }
        let delovi = ime.components(separatedBy: ".")

        // Fiksno ime sa rednim brojem: ...cmd.start.3
        if delovi.count == 6, let broj = Int(delovi[5]) {
            let komanda = delovi[4]
            Dnevnik.pisi("Darwin fiksna komanda \(komanda) #\(broj)")
            NSLog("Diktator: Darwin fiksna komanda %@ #%d", komanda, broj)
            // Komanda je u imenu, pa ne zavisimo od pasteboard-a.
            obradiKomandu(komanda)
            return
        }

        // Stariji fiksni format bez broja: ...cmd.start
        if delovi.count == 5 {
            let komanda = delovi[4]
            Dnevnik.pisi("Darwin fiksna komanda \(komanda)")
            NSLog("Diktator: Darwin fiksna komanda %@", komanda)
            obradiIPCKomandu()
            return
        }

        // Stariji dinamički format: ...cmd.start.<id>.<ms>
        guard delovi.count >= 7 else { return }
        let komanda = delovi[4]
        let id = delovi[5]
        guard id != zadnjiKomandniId,
              let ms = Double(delovi[6]),
              Date().timeIntervalSince1970 - ms / 1000 < 60 else {
            return
        }
        zadnjiKomandniId = id
        Dnevnik.pisi("Darwin komanda \(komanda) (\(id))")
        NSLog("Diktator: Darwin komanda %@ (%@)", komanda, id)
        obradiKomandu(komanda)
    }

    private func pokreniTimerSesije() {
        timerSesije?.invalidate()
        timerSesije = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.sesijaAktivna else { return }
                if let kraj = self.sesijaKraj {
                    self.sesijaPreostalo = max(
                        0,
                        Int(kraj.timeIntervalSinceNow.rounded())
                    )
                } else {
                    self.sesijaPreostalo = max(0, self.sesijaPreostalo - 1)
                }
                if self.sesijaPreostalo <= 0 {
                    self.zavrsiSesiju()
                }
            }
        }
    }

    /// Prepis ume da potraje i posle povratka u drugu aplikaciju. Kratak
    /// background task daje mu vremena da završi i upiše clipboard.
    private func pocniZadatakUPozadini() {
        zavrsiZadatakUPozadini()
        zadatakUPozadini = UIApplication.shared.beginBackgroundTask(
            withName: "Diktator prepis"
        ) { [weak self] in
            Task { @MainActor in
                self?.zavrsiZadatakUPozadini()
            }
        }
    }

    private func zavrsiZadatakUPozadini() {
        guard zadatakUPozadini != .invalid else { return }
        UIApplication.shared.endBackgroundTask(zadatakUPozadini)
        zadatakUPozadini = .invalid
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

    /// Model koji se stvarno koristi. U brzom režimu to je Turbo čim je
    /// preuzet, i ako je korisnik ranije izabrao Large v3.
    var modelZaPrepis: PonudaModela? {
        if RezimBrzine.iz(podesavanja.rezimBrzine) == .brzo,
           let turbo = Modeli.nadji("ggml-large-v3-turbo-q5_0.bin"),
           turbo.preuzet {
            return turbo
        }
        return Modeli.nadji(podesavanja.model)
    }

    var modelJePreuzet: Bool {
        modelZaPrepis?.preuzet == true || oblakSpreman
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
            if model.id == "ggml-large-v3-turbo-q5_0.bin" {
                podesavanja.rezimBrzine = RezimBrzine.brzo.rawValue
                podesavanja.prepisOblak = false
            } else if model.id == "ggml-large-v3-q5_0.bin" {
                podesavanja.rezimBrzine = RezimBrzine.tacno.rawValue
                podesavanja.prepisOblak = false
            }
            SkladistePodesavanja.sacuvaj(podesavanja)
            prepisivac.oslobodi()
            poruka = "Izabran je model \(model.naziv)."
        } else {
            preuzmiModel(model)
        }
    }

    /// Izbor u sekciji Brzina menja i model, da korisnik ne mora da bira na
    /// dva mesta. Ako Turbo nije preuzet, ostaje izabrani model.
    func postaviRezimBrzine(_ id: String) {
        let rezim = RezimBrzine.iz(id)
        podesavanja.rezimBrzine = rezim.rawValue
        podesavanja.prepisOblak = rezim == .oblak

        switch rezim {
        case .brzo:
            if let turbo = Modeli.nadji("ggml-large-v3-turbo-q5_0.bin"), turbo.preuzet {
                podesavanja.model = turbo.id
            }
        case .tacno:
            if let large = Modeli.nadji("ggml-large-v3-q5_0.bin"), large.preuzet {
                podesavanja.model = large.id
            }
        case .oblak:
            break
        }
        if !sesijaAktivna {
            prepisivac.oslobodi()
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
        guard !sesijaAktivna else { return }
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

    var provajderDoterivanja: ProvajderDoterivanja {
        ProvajderiDoterivanja.nadji(podesavanja.provajderDoterivanja)
            ?? ProvajderiDoterivanja.podrazumevani
    }

    var modelDoterivanja: String {
        let upisan = podesavanja.modeliDoterivanja[provajderDoterivanja.id]?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return upisan.isEmpty ? provajderDoterivanja.model : upisan
    }

    var adresaDoterivanja: String {
        let provajder = provajderDoterivanja
        guard provajder.id == ProvajderiDoterivanja.customId else {
            return provajder.adresa
        }
        let upisana = podesavanja.adresaCustomDoterivanja
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return upisana.isEmpty ? provajder.adresa : upisana
    }

    func postaviModelDoterivanja(_ vrednost: String) {
        let ocisceno = vrednost.trimmingCharacters(in: .whitespacesAndNewlines)
        let provajder = provajderDoterivanja
        if ocisceno.isEmpty || ocisceno == provajder.model {
            podesavanja.modeliDoterivanja.removeValue(forKey: provajder.id)
        } else {
            podesavanja.modeliDoterivanja[provajder.id] = ocisceno
        }
    }

    func izaberiProvajdera(_ id: String) {
        guard id != podesavanja.provajderDoterivanja,
              let provajder = ProvajderiDoterivanja.nadji(id) else { return }
        podesavanja.provajderDoterivanja = provajder.id
        kljucDoterivanja = Kljuc.citaj(za: provajder.id) ?? ""
    }

    @discardableResult
    func sacuvajKljuc() -> Bool {
        let ociscen = kljucDoterivanja.trimmingCharacters(in: .whitespacesAndNewlines)
        kljucDoterivanja = ociscen
        let uspeh = Kljuc.upisi(ociscen, za: provajderDoterivanja.id)
        porukaDoterivanja = uspeh
            ? "\(provajderDoterivanja.naziv) ključ je sačuvan u Keychain-u."
            : "\(provajderDoterivanja.naziv) ključ nije mogao da se sačuva u Keychain-u."
        return uspeh
    }

    func testirajDoterivanje() {
        guard !testiraDoterivanje else { return }
        let provajder = provajderDoterivanja
        let kljuc = kljucDoterivanja.trimmingCharacters(in: .whitespacesAndNewlines)
        let model = modelDoterivanja
        let adresa = adresaDoterivanja
        let jezik = podesavanja.jezik == "en" ? "en" : "sr"

        testiraDoterivanje = true
        Task { @MainActor in
            do {
                let rezultat = try await Doterivac.doteraj(
                    "Ovo je test veze. Vrati istu rečenicu.",
                    provajder: provajder,
                    kljuc: kljuc,
                    model: model,
                    adresa: adresa,
                    jezik: jezik
                )
                testiraDoterivanje = false
                porukaDoterivanja = "Veza radi: \(rezultat.prefix(100))"
            } catch {
                testiraDoterivanje = false
                porukaDoterivanja = "Test nije uspeo: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Prepis u oblaku

    var modelOblaka: String {
        let upisan = podesavanja.modelOblaka.trimmingCharacters(in: .whitespacesAndNewlines)
        return upisan.isEmpty ? PrepisOblak.podrazumevaniModel : upisan
    }

    var oblakSpreman: Bool {
        podesavanja.prepisOblak &&
            !kljucOblaka.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @discardableResult
    func sacuvajKljucOblaka() -> Bool {
        let ociscen = kljucOblaka.trimmingCharacters(in: .whitespacesAndNewlines)
        kljucOblaka = ociscen
        let uspeh = Kljuc.upisi(ociscen, za: "groq")
        porukaOblaka = uspeh
            ? "Groq ključ je sačuvan u Keychain-u."
            : "Groq ključ nije mogao da se sačuva u Keychain-u."
        return uspeh
    }

    func testirajOblak() {
        guard !testiraOblak else { return }
        let kljuc = kljucOblaka.trimmingCharacters(in: .whitespacesAndNewlines)
        testiraOblak = true
        Task { @MainActor in
            do {
                try await PrepisOblak.proveriKljuc(kljuc)
                testiraOblak = false
                porukaOblaka = "Veza radi. Model: \(modelOblaka)."
            } catch {
                testiraOblak = false
                porukaOblaka = "Test nije uspeo: \(error.localizedDescription)"
            }
        }
    }

    func sacuvajPodesavanja() {
        SkladistePodesavanja.sacuvaj(podesavanja)
        guard !sesijaAktivna else { return }
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

    func obrisiStatistiku() {
        statistika = Statistika()
        StatistikaSkladiste.sacuvaj(statistika)
        poruka = "Statistika je obrisana."
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

/// Minimalni HTTP server samo na loopback adresi. Tastatura ga koristi za
/// Nalepi, jer UIPasteboard u keyboard extension-u ume da vrati keširanu
/// vrednost. Server ne sluša spoljašnji saobraćaj.
final class ServerTeksta {
    private let port: UInt16 = 8765
    private let queue = DispatchQueue(label: "com.cedomirovic.diktator.server")
    private let brava = NSLock()
    private var poslednji = ""
    private var listener: NWListener?

    func postaviTekst(_ tekst: String) {
        brava.lock()
        poslednji = tekst
        brava.unlock()
    }

    func pokreni() {
        queue.async { [weak self] in
            self?.pokreniNaQueue()
        }
    }

    private func pokreniNaQueue() {
        guard listener == nil else { return }
        do {
            let parametri = NWParameters.tcp
            parametri.requiredLocalEndpoint = NWEndpoint.hostPort(
                host: "127.0.0.1",
                port: NWEndpoint.Port(rawValue: port)!
            )
            let novi = try NWListener(using: parametri)
            pokreniListener(novi, opis: "127.0.0.1:\(port)")
        } catch {
            Dnevnik.pisi(
                "ServerTeksta: loopback nije uspeo: \(error.localizedDescription)"
            )
            do {
                let novi = try NWListener(
                    using: .tcp,
                    on: NWEndpoint.Port(rawValue: port)!
                )
                pokreniListener(novi, opis: "port \(port)")
            } catch {
                Dnevnik.pisi(
                    "ServerTeksta: ne mogu da pokrenem: \(error.localizedDescription)"
                )
            }
        }
    }

    private func pokreniListener(_ novi: NWListener, opis: String) {
        novi.newConnectionHandler = { [weak self] veza in
            self?.obradi(veza)
        }
        novi.stateUpdateHandler = { stanje in
            if case .failed(let greska) = stanje {
                Dnevnik.pisi(
                    "ServerTeksta: listener greška \(greska.localizedDescription)"
                )
            }
        }
        novi.start(queue: queue)
        listener = novi
        Dnevnik.pisi("ServerTeksta: sluša na \(opis)")
    }

    func zaustavi() {
        queue.async { [weak self] in
            self?.listener?.cancel()
            self?.listener = nil
            Dnevnik.pisi("ServerTeksta: zaustavljen")
        }
    }

    private func obradi(_ veza: NWConnection) {
        veza.start(queue: queue)
        primaj(veza, podaci: Data())
    }

    private func primaj(_ veza: NWConnection, podaci: Data) {
        veza.receive(
            minimumIncompleteLength: 1,
            maximumLength: 8192
        ) { [weak self] deo, _, gotovo, greska in
            guard let self else {
                veza.cancel()
                return
            }
            var novi = podaci
            if let deo { novi.append(deo) }
            if novi.count > 16384 || greska != nil {
                veza.cancel()
                return
            }
            if let kraj = novi.range(of: Data("\r\n\r\n".utf8)) {
                let zaglavlje = String(
                    data: novi[..<kraj.lowerBound],
                    encoding: .utf8
                ) ?? ""
                let putanja = zaglavlje
                    .components(separatedBy: "\r\n")
                    .first?
                    .components(separatedBy: " ")
                    .dropFirst()
                    .first ?? ""
                self.odgovori(veza, putanja: putanja)
                return
            }
            if gotovo {
                veza.cancel()
                return
            }
            self.primaj(veza, podaci: novi)
        }
    }

    private func odgovori(_ veza: NWConnection, putanja: String) {
        let traziTekst = putanja.hasPrefix("/tekst")
        let tekst: String
        if traziTekst {
            brava.lock()
            tekst = poslednji
            brava.unlock()
        } else {
            tekst = ""
        }

        let kod = traziTekst ? "200 OK" : "404 Not Found"
        let telo = Data(tekst.utf8)
        var zaglavlje = "HTTP/1.1 \(kod)\r\n"
        zaglavlje += "Content-Type: text/plain; charset=utf-8\r\n"
        zaglavlje += "Content-Length: \(telo.count)\r\n"
        zaglavlje += "Connection: close\r\n\r\n"
        var odgovor = Data(zaglavlje.utf8)
        odgovor.append(telo)
        veza.send(content: odgovor, completion: .contentProcessed { _ in
            veza.cancel()
        })
    }
}
