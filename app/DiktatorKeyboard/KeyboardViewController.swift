import UIKit

/// Dijagnostika tastature ide u njen sopstveni container; posle testa se
/// fajl izvuče preko devicectl-a.
private enum Dnevnik {
    static let putanja: URL = {
        let folder = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        return folder.appendingPathComponent("diktator-tastatura-dnevnik.txt")
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

/// Imenovani pasteboard-i dele aplikacija i tastatura (isti Team ID), pa ne
/// treba App Group. Preko njih tastatura šalje start/stop, a aplikacija vraća
/// status i gotov tekst.
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
    /// Ključ lokalnog servera koji aplikacija upisuje u status.
    static let serverToken = "serverToken"

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

    static func imeKomandeFiksno(_ komanda: String, broj: Int) -> String {
        "\(notifKomanda).\(komanda).\(broj)"
    }

    static func imeStanjaFiksno(sesija: Bool, stanje: String) -> String {
        "\(notifStanje).\(sesija ? 1 : 0).\(stanje)"
    }
}

final class KeyboardViewController: UIInputViewController {
    private enum TipTastature {
        case slova
        case brojevi
        case simboli
    }

    private let gornjaTraka = UIStackView()
    private let tastatura = UIStackView()
    private let status = UILabel()
    private let spinnerObrade = UIActivityIndicatorView(style: .medium)
    private var dugmeDiktiraj: UIButton?
    private var dugmeNalepi: UIButton?
    private var tekstSpreman = false
    private var poslednjiPrepis = ""

    private var tip: TipTastature = .slova
    private var velikaSlova = false
    private var slovaDugmad: [(dugme: UIButton, osnovni: String)] = []
    private var dugmeShift: UIButton?
    private let zadnjiTokenKey = "diktator.zadnjiToken"
    private let cekaDiktatKey = "diktator.cekaDiktat"
    private let diktatPocetakKey = "diktator.diktatPocetak"
    private let cekaSesijuKey = "diktator.cekaSesiju"
    private let cekaSesijuVremeKey = "diktator.cekaSesijuVreme"
    private var autoNalepiUToku = false
    private var timerAutoNalepi: Timer?
    private var timerIPC: Timer?
    private var timerSesijaTimeout: Timer?
    private var sesijaAktivna = false
    private var sesijaDo: Double = 0
    private var snimaSesijom = false
    private var obradaSesije = false
    private var cekaStartSesije = false
    private var zadnjiKomandniId: String?
    private var komandniBrojac = 0
    private var diktatPocetakVreme: TimeInterval = 0

    /// Vreme kada je diktat pokrenut. Čuva se i u `UserDefaults`, jer iOS
    /// ume da ugasi keyboard extension dok je aplikacija u pozadini.
    private var pocetakDiktata: TimeInterval {
        let upisano = UserDefaults.standard.double(forKey: diktatPocetakKey)
        return upisano > 0 ? upisano : diktatPocetakVreme
    }
    private var privremeniStatus: String?
    private var privremeniStatusVreme: Date?
    private var zadnjeStanjeVreme: Double = 0
    private var zadnjiStatusVreme: Double = 0
    private var zadnjaNotifikacija: Date?
    private var darwinRegistrovan = false
    private var zadnjiDnevnikStanja = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        postaviVisinu()
        postaviGlavni()
        napraviTastaturu()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Dnevnik.pisi(
            "viewWillAppear, cekaSesiju=\(UserDefaults.standard.bool(forKey: cekaSesijuKey)), cekaDiktat=\(UserDefaults.standard.bool(forKey: cekaDiktatKey))"
        )
        NSLog("Diktator tastatura: viewWillAppear")
        registrujDarwin()
        pokreniIPCPolling()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NSLog("Diktator tastatura: viewDidAppear")
        // Tastatura se posle povratka iz aplikacije ponekad pojavi pre nego
        // što je textDocumentProxy spreman; kratak delay rešava taj slučaj.
        osveziIPCStanje()
        // Ako je tekst stigao dok tastatura nije bila na ekranu, nalepi ga
        // odmah po povratku.
        autoNalepiAkoTreba()
        // Traži svež status od aplikacije. Bez ovoga tastatura može da
        // nasledi zastareo status iz prethodne sesije.
        posaljiKomandu("ping")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timerAutoNalepi?.invalidate()
        timerAutoNalepi = nil
        timerIPC?.invalidate()
        timerIPC = nil
        timerSesijaTimeout?.invalidate()
        timerSesijaTimeout = nil
        NotificationCenter.default.removeObserver(
            self,
            name: UIPasteboard.changedNotification,
            object: UIPasteboard.general
        )
        odjaviDarwin()
    }

    private func registrujDarwin() {
        guard !darwinRegistrovan else { return }
        darwinRegistrovan = true
        let centar = CFNotificationCenterGetDarwinNotifyCenter()
        let osmatrac = Unmanaged.passUnretained(self).toOpaque()
        for sesija in [false, true] {
            for stanje in ["mirno", "snima", "obrada", "greska"] {
                CFNotificationCenterAddObserver(
                    centar,
                    osmatrac,
                    { _, observer, ime, _, _ in
                        guard let observer, let ime else { return }
                        let tastatura = Unmanaged<KeyboardViewController>
                            .fromOpaque(observer)
                            .takeUnretainedValue()
                        let tekst = ime.rawValue as String
                        Task { @MainActor in
                            tastatura.primljenaNotifikacija(tekst)
                        }
                    },
                    DiktatorIPC.imeStanjaFiksno(sesija: sesija, stanje: stanje) as CFString,
                    nil,
                    .deliverImmediately
                )
            }
        }

        // Tekst stiže u imenu notifikacije, kao base64. Imenovani pasteboard
        // i opšti clipboard umeju da vrate keširanu vrednost u extension-u.
        CFNotificationCenterAddObserver(
            centar,
            osmatrac,
            { _, observer, ime, _, _ in
                guard let observer, let ime else { return }
                let tastatura = Unmanaged<KeyboardViewController>
                    .fromOpaque(observer)
                    .takeUnretainedValue()
                let tekst = ime.rawValue as String
                guard tekst.hasPrefix("com.cedomirovic.diktator.tekst.") else { return }
                Task { @MainActor in
                    tastatura.primljenaNotifikacija(tekst)
                }
            },
            nil,
            nil,
            .deliverImmediately
        )
    }

    private func odjaviDarwin() {
        guard darwinRegistrovan else { return }
        darwinRegistrovan = false
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            nil,
            nil
        )
    }

    @objc private func pasteboardPromenjen() {
        DispatchQueue.main.async { [weak self] in
            self?.autoNalepiAkoTreba()
        }
    }

    private func postaviVisinu() {
        let visina = view.heightAnchor.constraint(equalToConstant: 300)
        visina.priority = .defaultHigh
        visina.isActive = true
    }

    private func postaviGlavni() {
        gornjaTraka.axis = .horizontal
        gornjaTraka.spacing = 8
        gornjaTraka.alignment = .center
        gornjaTraka.distribution = .fill
        gornjaTraka.translatesAutoresizingMaskIntoConstraints = false

        let diktiraj = napraviDugme(
            "Diktiraj",
            id: "diktiraj",
            akcija: #selector(diktiraj)
        )
        diktiraj.backgroundColor = .systemBlue
        diktiraj.setTitleColor(.white, for: .normal)
        diktiraj.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        diktiraj.widthAnchor.constraint(equalToConstant: 92).isActive = true
        dugmeDiktiraj = diktiraj

        let nalepi = napraviDugme(
            "Nalepi",
            id: "nalepi",
            akcija: #selector(nalepi)
        )
        nalepi.backgroundColor = .systemGreen
        nalepi.setTitleColor(.white, for: .normal)
        nalepi.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        nalepi.widthAnchor.constraint(equalToConstant: 80).isActive = true
        dugmeNalepi = nalepi

        status.font = .systemFont(ofSize: 11)
        status.textColor = .secondaryLabel
        status.textAlignment = .right
        status.numberOfLines = 1
        status.adjustsFontSizeToFitWidth = true
        status.minimumScaleFactor = 0.75
        status.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        status.setContentHuggingPriority(.defaultLow, for: .horizontal)

        spinnerObrade.hidesWhenStopped = true
        spinnerObrade.color = .systemOrange
        spinnerObrade.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

        gornjaTraka.addArrangedSubview(diktiraj)
        gornjaTraka.addArrangedSubview(nalepi)
        gornjaTraka.addArrangedSubview(spinnerObrade)
        gornjaTraka.addArrangedSubview(status)
        gornjaTraka.heightAnchor.constraint(equalToConstant: 36).isActive = true

        tastatura.axis = .vertical
        tastatura.spacing = 6
        tastatura.distribution = .fillEqually
        tastatura.translatesAutoresizingMaskIntoConstraints = false

        let glavni = UIStackView(arrangedSubviews: [gornjaTraka, tastatura])
        glavni.axis = .vertical
        glavni.spacing = 6
        glavni.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(glavni)

        NSLayoutConstraint.activate([
            glavni.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            glavni.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            glavni.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            glavni.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -4),
        ])
    }

    private func napraviTastaturu() {
        tastatura.arrangedSubviews.forEach { $0.removeFromSuperview() }
        slovaDugmad.removeAll()
        dugmeShift = nil

        switch tip {
        case .slova:
            napraviSlova()
        case .brojevi:
            napraviBrojeve()
        case .simboli:
            napraviSimbole()
        }
    }

    private func napraviSlova() {
        tastatura.addArrangedSubview(redSlova(["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]))
        tastatura.addArrangedSubview(redSlova(["a", "s", "d", "f", "g", "h", "j", "k", "l"]))

        let treci = UIStackView()
        treci.axis = .horizontal
        treci.spacing = 5
        treci.distribution = .fillEqually

        let shift = napraviDugme("⇧", id: "shift")
        dugmeShift = shift
        treci.addArrangedSubview(shift)
        for slovo in ["z", "x", "c", "v", "b", "n", "m"] {
            treci.addArrangedSubview(napraviSlovo(slovo))
        }
        treci.addArrangedSubview(napraviDugme("⌫", id: "delete"))
        tastatura.addArrangedSubview(treci)

        let cetvrti = UIStackView()
        cetvrti.axis = .horizontal
        cetvrti.spacing = 5
        cetvrti.distribution = .fillEqually
        cetvrti.addArrangedSubview(napraviDugme("123", id: "123"))
        cetvrti.addArrangedSubview(napraviDugme("🌐", id: "globe"))
        for slovo in ["č", "ć", "ž", "š", "đ"] {
            cetvrti.addArrangedSubview(napraviSlovo(slovo))
        }
        cetvrti.addArrangedSubview(napraviDugme("razmak", id: "space"))
        cetvrti.addArrangedSubview(napraviDugme("return", id: "return"))
        tastatura.addArrangedSubview(cetvrti)

        azurirajSlova()
    }

    private func napraviBrojeve() {
        tastatura.addArrangedSubview(redTekst(["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]))
        tastatura.addArrangedSubview(redTekst(["-", "/", ":", ";", "(", ")", "€", "&", "@", "\""]))

        let treci = UIStackView()
        treci.axis = .horizontal
        treci.spacing = 5
        treci.distribution = .fillEqually
        treci.addArrangedSubview(napraviDugme("#+=", id: "simboli"))
        for znak in [".", ",", "?", "!", "'"] {
            treci.addArrangedSubview(napraviDugme(znak, id: "tekst:\(znak)"))
        }
        treci.addArrangedSubview(napraviDugme("⌫", id: "delete"))
        tastatura.addArrangedSubview(treci)

        tastatura.addArrangedSubview(donjaTraka())
    }

    private func napraviSimbole() {
        tastatura.addArrangedSubview(redTekst(["[", "]", "{", "}", "#", "%", "^", "*", "+", "="]))
        tastatura.addArrangedSubview(redTekst(["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"]))

        let treci = UIStackView()
        treci.axis = .horizontal
        treci.spacing = 5
        treci.distribution = .fillEqually
        treci.addArrangedSubview(napraviDugme("123", id: "123"))
        for znak in [".", ",", "?", "!", "'"] {
            treci.addArrangedSubview(napraviDugme(znak, id: "tekst:\(znak)"))
        }
        treci.addArrangedSubview(napraviDugme("⌫", id: "delete"))
        tastatura.addArrangedSubview(treci)

        tastatura.addArrangedSubview(donjaTraka())
    }

    private func donjaTraka() -> UIStackView {
        let red = UIStackView()
        red.axis = .horizontal
        red.spacing = 5
        red.distribution = .fillEqually
        red.addArrangedSubview(napraviDugme("ABC", id: "abc"))
        red.addArrangedSubview(napraviDugme("🌐", id: "globe"))
        red.addArrangedSubview(napraviDugme("razmak", id: "space"))
        red.addArrangedSubview(napraviDugme("return", id: "return"))
        return red
    }

    private func redSlova(_ slova: [String]) -> UIStackView {
        let red = UIStackView()
        red.axis = .horizontal
        red.spacing = 5
        red.distribution = .fillEqually
        for slovo in slova {
            red.addArrangedSubview(napraviSlovo(slovo))
        }
        return red
    }

    private func redTekst(_ tekstovi: [String]) -> UIStackView {
        let red = UIStackView()
        red.axis = .horizontal
        red.spacing = 5
        red.distribution = .fillEqually
        for tekst in tekstovi {
            red.addArrangedSubview(napraviDugme(tekst, id: "tekst:\(tekst)"))
        }
        return red
    }

    private func napraviSlovo(_ osnovni: String) -> UIButton {
        let dugme = napraviDugme(osnovni, id: "slovo:\(osnovni)")
        slovaDugmad.append((dugme, osnovni))
        return dugme
    }

    private func napraviDugme(
        _ naslov: String,
        id: String,
        akcija: Selector = #selector(tapKey(_:))
    ) -> UIButton {
        let dugme = UIButton(type: .system)
        dugme.setTitle(naslov, for: .normal)
        dugme.titleLabel?.font = .systemFont(
            ofSize: naslov.count > 1 ? 13 : 22,
            weight: .regular
        )
        dugme.setTitleColor(.label, for: .normal)
        dugme.backgroundColor = .secondarySystemBackground
        dugme.layer.cornerRadius = 6
        dugme.accessibilityIdentifier = id
        dugme.addTarget(self, action: akcija, for: .touchUpInside)
        return dugme
    }

    @objc private func tapKey(_ sender: UIButton) {
        guard let id = sender.accessibilityIdentifier else { return }

        switch id {
        case "shift":
            velikaSlova.toggle()
            azurirajSlova()
        case "delete":
            textDocumentProxy.deleteBackward()
        case "space":
            textDocumentProxy.insertText(" ")
        case "return":
            textDocumentProxy.insertText("\n")
        case "globe":
            advanceToNextInputMode()
        case "123":
            tip = .brojevi
            napraviTastaturu()
        case "abc":
            tip = .slova
            napraviTastaturu()
        case "simboli":
            tip = .simboli
            napraviTastaturu()
        default:
            if id.hasPrefix("slovo:") {
                let osnovni = String(id.dropFirst("slovo:".count))
                let tekst = velikaSlova ? osnovni.uppercased() : osnovni
                textDocumentProxy.insertText(tekst)
                if velikaSlova {
                    velikaSlova = false
                    azurirajSlova()
                }
            } else if id.hasPrefix("tekst:") {
                let tekst = String(id.dropFirst("tekst:".count))
                textDocumentProxy.insertText(tekst)
            }
        }
    }

    private func azurirajSlova() {
        for (dugme, osnovni) in slovaDugmad {
            dugme.setTitle(velikaSlova ? osnovni.uppercased() : osnovni, for: .normal)
        }
        if let shift = dugmeShift {
            shift.backgroundColor = velikaSlova ? .systemBlue : .secondarySystemBackground
            shift.setTitleColor(velikaSlova ? .white : .label, for: .normal)
        }
    }

    @objc private func diktiraj() {
        guard hasFullAccess else {
            prikaziStatus("Uključi Full Access.")
            return
        }

        Dnevnik.pisi(
            "Diktiraj: sesija=\(sesijaAktivna), snima=\(snimaSesijom), obrada=\(obradaSesije)"
        )
        osveziIPCStanje()

        if snimaSesijom {
            posaljiKomandu("stop")
            snimaSesijom = false
            obradaSesije = true
            prikaziStatus("Obrada…")
            azurirajPrikaz()
            return
        }

        if obradaSesije {
            prikaziStatus("Sačekaj da se završi prepis.")
            return
        }

        if !sesijaAktivna {
            // Prvi put, dok sesija nije uključena, otvaramo Diktator da
            // korisnik uključi sesiju. Kad je sesija aktivna, Diktiraj
            // snima odmah i ne dira drugu aplikaciju.
            prikaziStatus("Otvori Diktator i uključi sesiju.")
            // I ovaj prvi diktat treba da se nalepi sam po povratku, ako
            // aplikacija uspe da ga završi dok je tastatura na ekranu.
            diktatPocetakVreme = Date().timeIntervalSince1970
            UserDefaults.standard.set(diktatPocetakVreme, forKey: diktatPocetakKey)
            UserDefaults.standard.set(true, forKey: cekaDiktatKey)
            otvoriAplikaciju("diktator-ios://sesija-prikaz")
            return
        }

        posaljiKomandu("start")
        snimaSesijom = true
        obradaSesije = false
        cekaStartSesije = false
        diktatPocetakVreme = Date().timeIntervalSince1970
        UserDefaults.standard.set(diktatPocetakVreme, forKey: diktatPocetakKey)
        UserDefaults.standard.set(true, forKey: cekaDiktatKey)
        prikaziStatus("Snimam…")
        pustiZvukDiktata()
        azurirajPrikaz()
    }

    /// Blagi haptički odziv odmah na dodir. Zvuk pušta aplikacija kada
    /// stvarno počne snimanje — tastatura ne sme da dira AVAudioSession, a
    /// sistemski zvuk se ne čuje kada je telefon na tihom.
    private func pustiZvukDiktata() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    private func posaljiKomandu(_ komanda: String) {
        let id = UUID().uuidString
        let vreme = Date().timeIntervalSince1970
        zadnjiKomandniId = id
        // Lokalna akcija je novija od svakog statusa koji je stigao pre nje.
        // Tako tastatura neće vratiti staro stanje dok aplikacija ne odgovori.
        zadnjeStanjeVreme = max(zadnjeStanjeVreme, vreme)
        DiktatorIPC.pisi(DiktatorIPC.komande, [
            DiktatorIPC.komanda: komanda,
            DiktatorIPC.id: id,
            DiktatorIPC.vreme: String(vreme)
        ])
        komandniBrojac = (komandniBrojac + 1) % 10
        DiktatorIPC.posaljiNotifikaciju(
            DiktatorIPC.imeKomandeFiksno(komanda, broj: komandniBrojac)
        )
        Dnevnik.pisi("Poslata komanda \(komanda) (\(id))")
        NSLog("Diktator tastatura: poslata komanda %@ (%@).", komanda, id)
    }

    private func otvoriAplikaciju(_ adresa: String) {
        guard let url = URL(string: adresa) else { return }
        Dnevnik.pisi("Otvaram \(adresa), Full Access=\(hasFullAccess)")
        NSLog(
            "Diktator tastatura: otvaram %@, Full Access = %@",
            url.absoluteString,
            hasFullAccess ? "da" : "ne"
        )

        guard let kontekst = extensionContext else {
            if !otvoriPrekoResponderLanca(url) {
                UserDefaults.standard.set(false, forKey: cekaDiktatKey)
                ocistiCekanjeSesije()
                prikaziStatus("Otvori app ručno.")
            }
            return
        }

        kontekst.open(url) { [weak self] uspeh in
            guard let self else { return }
            if uspeh {
                NSLog("Diktator tastatura: aplikacija je otvorena preko extensionContext.")
                return
            }

            NSLog("Diktator tastatura: extensionContext.open nije uspeo, pokušavam fallback.")
            DispatchQueue.main.async {
                if self.otvoriPrekoResponderLanca(url) {
                    self.prikaziStatus("Otvaram…")
                } else {
                    UserDefaults.standard.set(false, forKey: self.cekaDiktatKey)
                    self.ocistiCekanjeSesije()
                    self.prikaziStatus("Otvori app ručno.")
                }
            }
        }
    }

    private func pokreniTimeoutSesije() {
        timerSesijaTimeout?.invalidate()
        let cekanjeSesije = UserDefaults.standard.bool(forKey: cekaSesijuKey)
        timerSesijaTimeout = Timer.scheduledTimer(
            withTimeInterval: cekanjeSesije ? 8 : 6,
            repeats: false
        ) { [weak self] _ in
            guard let self else { return }

            if UserDefaults.standard.bool(forKey: self.cekaSesijuKey) {
                self.ocistiCekanjeSesije()
                NSLog("Diktator tastatura: sesija nije odgovorila, otvaram app.")
                self.prikaziStatus("Otvaram…")
                self.otvoriAplikaciju("diktator-ios://dictate")
                return
            }

            // Start je poslat, ali aplikacija nije javila „snima“. Verovatno
            // je ugašena ili suspendovana, pa je otvaramo.
            if self.cekaStartSesije {
                self.cekaStartSesije = false
                self.snimaSesijom = false
                self.obradaSesije = false
                NSLog("Diktator tastatura: start nije odgovorio, otvaram app.")
                self.prikaziStatus("Nema odgovora — otvaram app.")
                self.otvoriAplikaciju("diktator-ios://dictate")
                return
            }

            // Stop je poslat, ali nema statusa „obrada“. Aplikacija verovatno
            // ne radi, pa je otvaramo da se prepis ipak završi.
            if self.obradaSesije && !UserDefaults.standard.bool(forKey: self.cekaDiktatKey) {
                self.obradaSesije = false
                NSLog("Diktator tastatura: stop nije odgovorio, otvaram app.")
                self.prikaziStatus("Nema odgovora — otvaram app.")
                self.otvoriAplikaciju("diktator-ios://dictate")
            }
        }
    }

    /// iOS 18 je ukinuo stari `openURL:` put preko responder lanca, a iOS 26
    /// traži Full Access. Ovo je samo rezerva ako `extensionContext.open`
    /// iz nekog razloga vrati false dok je Full Access uključen.
    @discardableResult
    private func otvoriPrekoResponderLanca(_ url: URL) -> Bool {
        // iOS 18+ put: pronađi UIApplication u responder lancu i koristi
        // `open(_:options:completionHandler:)`.
        var responder: UIResponder? = self
        while let trenutni = responder {
            if let aplikacija = trenutni as? UIApplication {
                aplikacija.open(url, options: [:], completionHandler: nil)
                return true
            }
            responder = trenutni.next
        }

        // iOS 17 rezerva: stari `openURL:` selektor.
        let selektor = NSSelectorFromString("openURL:")
        responder = self
        while let trenutni = responder {
            if trenutni.responds(to: selektor) {
                trenutni.perform(selektor, with: url)
                return true
            }
            responder = trenutni.next
        }
        return false
    }

    @objc private func nalepi() {
        nalepiSaServera()
    }

    private func nalepiSaServera() {
        guard hasFullAccess else {
            prikaziStatus("Uključi Full Access.")
            return
        }
        guard let url = URL(string: "http://127.0.0.1:8765/tekst") else {
            nalepiIzRezerve()
            return
        }

        // Server traži ključ koji aplikacija upisuje u status. Bez njega
        // odmah idemo na rezervni put preko imenovanog pasteboard-a.
        let serverToken = DiktatorIPC.citaj(DiktatorIPC.stanje)[DiktatorIPC.serverToken]
        guard let serverToken, !serverToken.isEmpty else {
            Dnevnik.pisi("Nalepi server: nema ključa, prelazim na rezervu.")
            nalepiIzRezerve()
            return
        }

        prikaziStatus("Nalepi…")
        var zahtev = URLRequest(url: url)
        zahtev.timeoutInterval = 2
        zahtev.httpMethod = "GET"
        zahtev.setValue(serverToken, forHTTPHeaderField: "X-Diktator-Token")
        URLSession.shared.dataTask(with: zahtev) { [weak self] podaci, odgovor, greska in
            DispatchQueue.main.async {
                guard let self else { return }
                let kod = (odgovor as? HTTPURLResponse)?.statusCode ?? 0
                if greska == nil,
                   kod == 200,
                   let podaci,
                   let tekst = String(data: podaci, encoding: .utf8),
                   !tekst.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Dnevnik.pisi("Nalepi server: duzina=\(tekst.count)")
                    self.umetniTekst(tekst)
                } else {
                    Dnevnik.pisi(
                        "Nalepi server: nema teksta, kod=\(kod), greska=\(greska?.localizedDescription ?? "-")"
                    )
                    self.nalepiIzRezerve()
                }
            }
        }.resume()
    }

    private func umetniTekst(_ tekst: String) {
        textDocumentProxy.insertText(tekst)
        poslednjiPrepis = ""
        tekstSpreman = false
        // Ručni Nalepi završava čekanje, da ga automatsko lepljenje ne bi
        // ponovilo isti tekst.
        UserDefaults.standard.set(false, forKey: cekaDiktatKey)
        timerAutoNalepi?.invalidate()
        timerAutoNalepi = nil
        prikaziStatus("Nalepljeno.")
        azurirajPrikaz()
    }

    private func nalepiIzRezerve() {
        guard hasFullAccess else {
            prikaziStatus("Uključi Full Access.")
            return
        }

        var tekst = poslednjiPrepis
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let notifikacijaDuzina = tekst.count

        if tekst.isEmpty {
            tekst = tekstIzIPCBezTokena() ?? ""
        }
        let ipcDuzina = tekst.count

        if tekst.isEmpty {
            tekst = UIPasteboard.general.string?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        let opstiDuzina = tekst.count

        if tekst.isEmpty,
           let predmet = UIPasteboard.general.items.first,
           let izPredmeta = stringIz(predmet[DiktatorClipboard.tekst])?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !izPredmeta.isEmpty {
            tekst = izPredmeta
        }

        Dnevnik.pisi(
            "Nalepi izvori: notifikacija=\(notifikacijaDuzina), ipc=\(ipcDuzina), opsti=\(opstiDuzina), izabrano=\(tekst.count), changeCount=\(UIPasteboard.general.changeCount)"
        )

        guard !tekst.isEmpty else {
            Dnevnik.pisi("Nalepi: clipboard je prazan.")
            prikaziStatus("Clipboard je prazan.")
            return
        }

        Dnevnik.pisi("Nalepi: duzina=\(tekst.count)")
        umetniTekst(tekst)
    }

    private func pokreniIPCPolling() {
        timerIPC?.invalidate()
        osveziIPCStanje()
        timerIPC = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.osveziIPCStanje()
        }
    }

    /// Čita status iz imenovanog pasteboard-a. Ako je sesija živa, ovde se
    /// automatski šalje start posle prvog otvaranja aplikacije.
    private func osveziIPCStanje() {
        let vrednosti = DiktatorIPC.citaj(DiktatorIPC.stanje)
        let sada = Date().timeIntervalSince1970

        if let vremeString = vrednosti[DiktatorIPC.vreme],
           let vreme = Double(vremeString) {
            let sesija = vrednosti[DiktatorIPC.sesija] == "1"
            let stanjeApp = vrednosti[DiktatorIPC.stanjeKljuc] ?? "mirno"
            let doKada = Double(vrednosti[DiktatorIPC.sesijaDo] ?? "") ?? 0
            primeniStanje(
                sesija: sesija,
                stanje: stanjeApp,
                vreme: vreme,
                sesijaDo: doKada
            )
        } else if zadnjaNotifikacija == nil
                    || Date().timeIntervalSince(zadnjaNotifikacija!) > 10 {
            obradiStaleStanje()
        }

        // Sesija traje 15 minuta. Ako aplikacija u pozadini ne stigne da
        // pošalje novi status, tastatura i dalje zna do kada je sesija živa.
        if sesijaAktivna, sesijaDo > 0, sada >= sesijaDo {
            Dnevnik.pisi("Sesija je istekla (sesijaDo).")
            obradiStaleStanje()
        }

        // Ako status „snima“ nije osvežen bar 8 sekundi, aplikacija verovatno
        // više ne snima. Bolje je vratiti Diktiraj nego poslati pogrešan stop.
        if snimaSesijom, !cekaStartSesije, sada - zadnjiStatusVreme > 8 {
            Dnevnik.pisi("Status snimanja je zastareo — vraćam Diktiraj.")
            snimaSesijom = false
            obradaSesije = false
            timerSesijaTimeout?.invalidate()
            timerSesijaTimeout = nil
        }

        // Stariji statusi nemaju sesijaDo. Ako su zastareli, ne verujemo im.
        if sesijaAktivna, sesijaDo == 0, sada - zadnjiStatusVreme > 8 {
            Dnevnik.pisi("Sesija nema važenje i status je zastareo — gasim.")
            obradiStaleStanje()
        }

        // Dok čekamo tekst iz aplikacije, svaki prolaz pokušava i automatsko
        // lepljenje. Tako se tekst ubaci čim stigne, bez dodatnog dodira.
        if UserDefaults.standard.bool(forKey: cekaDiktatKey) {
            autoNalepiAkoTreba()
        }

        azurirajPrikaz()
    }

    private func primeniStanje(
        sesija: Bool,
        stanje: String,
        vreme: Double,
        sesijaDo noviSesijaDo: Double = 0
    ) {
        guard vreme > zadnjeStanjeVreme else { return }
        zadnjeStanjeVreme = vreme
        zadnjiStatusVreme = vreme
        sesijaAktivna = sesija
        let prethodniSesijaDo = sesijaDo
        sesijaDo = sesija ? noviSesijaDo : 0
        if sesija, noviSesijaDo > 0, noviSesijaDo != prethodniSesijaDo {
            Dnevnik.pisi("Sesija važi do \(Int(noviSesijaDo)).")
        }

        ocistiCekanjeSesije()
        let jeBilaObrada = obradaSesije

        let kljuc = "\(sesija)-\(stanje)"
        if kljuc != zadnjiDnevnikStanja {
            zadnjiDnevnikStanja = kljuc
            Dnevnik.pisi("Stanje: sesija=\(sesija) stanje=\(stanje)")
        }

        switch stanje {
        case "snima":
            snimaSesijom = true
            obradaSesije = false
            tekstSpreman = false
            cekaStartSesije = false
            timerSesijaTimeout?.invalidate()
            timerSesijaTimeout = nil
        case "obrada":
            snimaSesijom = false
            obradaSesije = true
            tekstSpreman = false
            cekaStartSesije = false
            timerSesijaTimeout?.invalidate()
            timerSesijaTimeout = nil
        case "mirno":
            snimaSesijom = false
            obradaSesije = false
            cekaStartSesije = false
            timerSesijaTimeout?.invalidate()
            timerSesijaTimeout = nil
            if jeBilaObrada {
                let noviTekst = poslednjiPrepis.isEmpty
                    ? (tekstIzIPCBezTokena() ?? UIPasteboard.general.string)
                    : poslednjiPrepis
                let duzina = noviTekst?.count ?? -1
                Dnevnik.pisi("Mirno posle obrade: tekst duzina=\(duzina)")
                // „mirno“ posle obrade znači da je prepis uspeo i da tekst
                // postoji na lokalnom serveru, čak i ako ga tastatura nije
                // našla u clipboard-u. Prvo probamo da nalepimo sami, a
                // Nalepi ostaje ako to ne uspe.
                tekstSpreman = true
                autoNalepiAkoTreba()
                if UserDefaults.standard.bool(forKey: cekaDiktatKey) {
                    prikaziStatus("Spremno je, nalepi.")
                }
            }
        case "greska":
            snimaSesijom = false
            obradaSesije = false
            tekstSpreman = false
            cekaStartSesije = false
            UserDefaults.standard.set(false, forKey: cekaDiktatKey)
            timerAutoNalepi?.invalidate()
            timerAutoNalepi = nil
            timerSesijaTimeout?.invalidate()
            timerSesijaTimeout = nil
            prikaziStatus("Greška — otvori Diktator.")
        default:
            break
        }
    }

    private func obradiStaleStanje() {
        let sada = Date().timeIntervalSince1970
        if sesijaAktivna, sesijaDo > 0, sada < sesijaDo {
            return
        }
        if sesijaAktivna {
            Dnevnik.pisi("Status je zastareo — sesija se gasi u tastaturi.")
        }
        sesijaAktivna = false
        sesijaDo = 0
        if snimaSesijom && !cekaStartSesije {
            snimaSesijom = false
        }
        if obradaSesije && !UserDefaults.standard.bool(forKey: cekaDiktatKey) {
            obradaSesije = false
        }
        if UserDefaults.standard.bool(forKey: cekaSesijuKey) && !cekanjeSesijeTraje {
            ocistiCekanjeSesije()
            UserDefaults.standard.set(false, forKey: cekaDiktatKey)
            prikaziStatus("Sesija nije počela — tapni Diktiraj.")
        }
        azurirajPrikaz()
    }

    private func primljenaNotifikacija(_ ime: String) {
        if ime.hasPrefix("com.cedomirovic.diktator.tekst.") {
            primljenTekst(ime)
            return
        }
        guard ime.hasPrefix(DiktatorIPC.notifStanje + ".") else { return }
        let delovi = ime.components(separatedBy: ".")
        zadnjaNotifikacija = Date()

        // Fiksno ime: com.cedomirovic.diktator.st.<sesija>.<stanje>
        if delovi.count == 6 {
            let sesija = delovi[4] == "1"
            let stanje = delovi[5]
            let vrednosti = DiktatorIPC.citaj(DiktatorIPC.stanje)
            let sada = Date().timeIntervalSince1970
            let doKada = Double(vrednosti[DiktatorIPC.sesijaDo] ?? "") ?? 0
            let vazeceDo = doKada > sada ? doKada : 0
            Dnevnik.pisi(
                "Darwin fiksni status: sesija=\(sesija) stanje=\(stanje)"
            )
            // Notifikacija je svež signal; vreme uzimamo sada, da pasteboard
            // ne može da vrati staro stanje.
            primeniStanje(
                sesija: sesija,
                stanje: stanje,
                vreme: sada,
                sesijaDo: vazeceDo
            )
            azurirajPrikaz()
            return
        }

        // Stariji dinamički format: ...st.<sesija>.<stanje>.<ms>.<sesijaDoMs>
        guard delovi.count >= 8,
              let ms = Double(delovi[6]),
              let doMs = Double(delovi[7]) else {
            osveziIPCStanje()
            return
        }

        let sesija = delovi[4] == "1"
        let stanje = delovi[5]
        Dnevnik.pisi(
            "Darwin status: sesija=\(sesija) stanje=\(stanje) do=\(Int(doMs / 1000))"
        )
        primeniStanje(
            sesija: sesija,
            stanje: stanje,
            vreme: ms / 1000,
            sesijaDo: doMs / 1000
        )
        azurirajPrikaz()
    }

    /// Stiže kao `com.cedomirovic.diktator.tekst.<broj>.<base64>`.
    /// Tekst je u imenu notifikacije, pa ne zavisimo od pasteboard keša.
    private func primljenTekst(_ ime: String) {
        let prefiks = "com.cedomirovic.diktator.tekst."
        guard ime.hasPrefix(prefiks) else { return }
        let ostatak = ime.dropFirst(prefiks.count)
        guard let tacka = ostatak.firstIndex(of: ".") else { return }
        let base64Deo = String(ostatak[ostatak.index(after: tacka)...])
        var base64 = base64Deo
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64 += "="
        }

        guard let podaci = Data(base64Encoded: base64),
              let tekst = String(data: podaci, encoding: .utf8),
              !tekst.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            Dnevnik.pisi(
                "Tekst notifikacija: base64 nije dekodiran, duzina=\(base64Deo.count)"
            )
            return
        }

        poslednjiPrepis = tekst
        tekstSpreman = true
        Dnevnik.pisi("Tekst notifikacija: duzina=\(tekst.count)")
        autoNalepiAkoTreba()
        if UserDefaults.standard.bool(forKey: cekaDiktatKey) {
            prikaziStatus("Spremno je, nalepi.")
        }
        azurirajPrikaz()
    }

    private var cekanjeSesijeTraje: Bool {
        let vreme = UserDefaults.standard.double(forKey: cekaSesijuVremeKey)
        if vreme <= 0 { return true }
        return Date().timeIntervalSince1970 - vreme < 15
    }

    private func postaviCekanjeSesije() {
        UserDefaults.standard.set(true, forKey: cekaSesijuKey)
        UserDefaults.standard.set(
            Date().timeIntervalSince1970,
            forKey: cekaSesijuVremeKey
        )
    }

    private func ocistiCekanjeSesije() {
        UserDefaults.standard.set(false, forKey: cekaSesijuKey)
        UserDefaults.standard.removeObject(forKey: cekaSesijuVremeKey)
    }

    /// Ako je diktat pokrenut iz tastature, sačekaj da aplikacija završi
    /// prepis i upiše clipboard. Ovo pokriva i slučaj kada se korisnik vrati
    /// u drugu aplikaciju pre nego što je prepis gotov.
    private func pokreniCekanjeAkoTreba() {
        autoNalepiAkoTreba()
        guard UserDefaults.standard.bool(forKey: cekaDiktatKey) else { return }
        NSLog(
            "Diktator tastatura: čekam automatsko lepljenje (itema=%d).",
            UIPasteboard.general.items.count
        )

        timerAutoNalepi?.invalidate()
        var pokusaja = 0
        timerAutoNalepi = Timer.scheduledTimer(
            withTimeInterval: 0.75,
            repeats: true
        ) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            pokusaja += 1
            self.autoNalepiAkoTreba()
            if !UserDefaults.standard.bool(forKey: self.cekaDiktatKey) || pokusaja >= 800 {
                if pokusaja >= 800 {
                    UserDefaults.standard.set(false, forKey: self.cekaDiktatKey)
                    self.ocistiCekanjeSesije()
                }
                timer.invalidate()
                self.timerAutoNalepi = nil
            }
        }
    }

    /// Automatski nalepi novi diktat. Prvo probaj imenovani pasteboard, pa
    /// generalni clipboard (stariji put i ručno kopiran tekst).
    private func autoNalepiAkoTreba() {
        guard hasFullAccess, !autoNalepiUToku else { return }
        guard UserDefaults.standard.bool(forKey: cekaDiktatKey)
                || snimaSesijom
                || obradaSesije else {
            return
        }

        // Ako se tekst ne pojavi (aplikacija ugašena, snimak odbijen),
        // ne čekamo zauvek.
        let pocetak = pocetakDiktata
        if pocetak > 0, Date().timeIntervalSince1970 - pocetak > 600 {
            UserDefaults.standard.set(false, forKey: cekaDiktatKey)
            Dnevnik.pisi("AutoNalepi: isteklo čekanje posle 10 minuta.")
            return
        }

        if let (tekst, token) = tekstIzIPC() {
            Dnevnik.pisi("AutoNalepi: IPC tekst duzina=\(tekst.count)")
            nalepiAutomatski(tekst, token: token, izvor: "IPC")
            return
        }

        let predmet = UIPasteboard.general.items.first
        Dnevnik.pisi(
            "AutoNalepi: ceka=\(UserDefaults.standard.bool(forKey: cekaDiktatKey)), snima=\(snimaSesijom), obrada=\(obradaSesije), opsti=\(predmet?.keys.sorted().joined(separator: ",") ?? "-")"
        )
        guard let predmet else { return }
        let token = stringIz(predmet[DiktatorClipboard.token])
        let vremeString = stringIz(predmet[DiktatorClipboard.vreme])
        let vreme = vremeString.flatMap(Double.init)
        let tekst = stringIz(predmet[DiktatorClipboard.tekst])
        Dnevnik.pisi(
            "AutoNalepi opsti: token=\(token?.prefix(8) ?? "-"), vreme=\(vremeString ?? "-"), tekst=\(tekst?.count ?? -1), pocetak=\(Int(pocetakDiktata))"
        )
        guard let token, let vreme, let tekst,
              !tekst.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        guard pocetak == 0 || vreme >= pocetak - 1 else {
            Dnevnik.pisi("AutoNalepi: preskačem stari clipboard")
            return
        }

        let starost = Date().timeIntervalSince1970 - vreme
        guard starost >= 0, starost <= 180 else {
            UserDefaults.standard.set(false, forKey: cekaDiktatKey)
            timerAutoNalepi?.invalidate()
            timerAutoNalepi = nil
            NSLog("Diktator tastatura: preskačem star clipboard (%.0f s).", starost)
            return
        }

        nalepiAutomatski(tekst, token: token, izvor: "clipboard")
    }

    private func nalepiAutomatski(_ tekst: String, token: String, izvor: String) {
        let podrazumevano = UserDefaults.standard
        guard podrazumevano.string(forKey: zadnjiTokenKey) != token else {
            Dnevnik.pisi("AutoNalepi: token je već nalepljen")
            return
        }
        NSLog("Diktator tastatura: pronađen token za automatsko lepljenje (%@, %@).", izvor, token)

        autoNalepiUToku = true
        defer { autoNalepiUToku = false }

        textDocumentProxy.insertText(tekst)
        Dnevnik.pisi("Automatski nalepljeno (\(izvor)), token=\(token)")
        podrazumevano.set(token, forKey: zadnjiTokenKey)
        podrazumevano.set(false, forKey: cekaDiktatKey)
        ocistiCekanjeSesije()
        timerAutoNalepi?.invalidate()
        timerAutoNalepi = nil
        timerSesijaTimeout?.invalidate()
        timerSesijaTimeout = nil
        cekaStartSesije = false
        snimaSesijom = false
        obradaSesije = false
        prikaziStatus("Nalepljeno automatski.")
        NSLog("Diktator tastatura: automatski nalepljen tekst (%@).", token)
    }

    /// Poslednji prepis iz imenovanog status pasteboard-a. Opšti clipboard
    /// ume da vrati zastarelu vrednost u keyboard extension-u, pa je ovo
    /// primarni izvor za dugme Nalepi.
    private func tekstIzIPCBezTokena() -> String? {
        let vrednosti = DiktatorIPC.citaj(DiktatorIPC.stanje)
        guard let tekst = vrednosti[DiktatorIPC.tekst]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !tekst.isEmpty else {
            Dnevnik.pisi(
                "IPC bez tokena: nema teksta, kljucevi=\(vrednosti.keys.sorted().joined(separator: ","))"
            )
            return nil
        }
        Dnevnik.pisi("IPC bez tokena: tekst=\(tekst.count), vreme=\(vrednosti[DiktatorIPC.vreme] ?? "-")")
        return tekst
    }

    private func tekstIzIPC() -> (tekst: String, token: String)? {
        let vrednosti = DiktatorIPC.citaj(DiktatorIPC.stanje)
        guard let token = vrednosti[DiktatorIPC.token],
              let tekst = vrednosti[DiktatorIPC.tekst],
              !tekst.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let vremeString = vrednosti[DiktatorIPC.tokenVreme],
              let vreme = Double(vremeString) else {
            if !vrednosti.isEmpty {
                Dnevnik.pisi(
                    "IPC tekst: nema, kljucevi=\(vrednosti.keys.sorted().joined(separator: ","))"
                )
            }
            return nil
        }

        let starost = Date().timeIntervalSince1970 - vreme
        guard starost >= 0, starost <= 180 else { return nil }
        let pocetak = pocetakDiktata
        guard pocetak == 0 || vreme >= pocetak - 1 else {
            Dnevnik.pisi("IPC tekst: preskačem stari tekst")
            return nil
        }
        Dnevnik.pisi("IPC tekst: duzina=\(tekst.count), token=\(token.prefix(8))")
        return (tekst, token)
    }

    private func tekstIzClipboarda() -> (tekst: String, token: String?)? {
        if UserDefaults.standard.bool(forKey: cekaDiktatKey),
           let ipc = tekstIzIPC() {
            return (ipc.tekst, ipc.token)
        }

        if let predmet = UIPasteboard.general.items.first,
           let tekst = stringIz(predmet[DiktatorClipboard.tekst]) {
            let ociscen = tekst.trimmingCharacters(in: .whitespacesAndNewlines)
            if !ociscen.isEmpty {
                return (ociscen, stringIz(predmet[DiktatorClipboard.token]))
            }
        }

        if let tekst = UIPasteboard.general.string?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !tekst.isEmpty {
            return (tekst, nil)
        }

        if let ipc = tekstIzIPC() {
            return (ipc.tekst, ipc.token)
        }
        return nil
    }

    private func stringIz(_ vrednost: Any?) -> String? {
        if let tekst = vrednost as? String { return tekst }
        if let podaci = vrednost as? Data {
            return String(data: podaci, encoding: .utf8)
        }
        return nil
    }

    private func prikaziStatus(_ tekst: String) {
        privremeniStatus = tekst
        privremeniStatusVreme = Date()
        status.text = tekst
        status.textColor = .secondaryLabel
    }

    private func azurirajPrikaz() {
        if obradaSesije {
            spinnerObrade.startAnimating()
        } else {
            spinnerObrade.stopAnimating()
        }

        if let vreme = privremeniStatusVreme,
           Date().timeIntervalSince(vreme) < 1.5,
           let tekst = privremeniStatus {
            status.text = tekst
            status.textColor = .secondaryLabel
        } else {
            privremeniStatus = nil
            privremeniStatusVreme = nil

            if !hasFullAccess {
                status.text = "Full Access ✗"
                status.textColor = .systemOrange
            } else if obradaSesije {
                status.text = "Obrada…"
                status.textColor = .systemOrange
            } else if snimaSesijom {
                status.text = "Snimam…"
                status.textColor = .systemRed
            } else if tekstSpreman {
                status.text = "Spremno je, nalepi."
                status.textColor = .systemGreen
            } else if sesijaAktivna {
                status.text = "Sesija ✓"
                status.textColor = .systemGreen
            } else {
                status.text = "Sesija ✗"
                status.textColor = .systemOrange
            }
        }

        dugmeNalepi?.isEnabled = hasFullAccess && !obradaSesije && !snimaSesijom

        guard let dugme = dugmeDiktiraj else { return }

        if !hasFullAccess {
            dugme.isEnabled = false
            dugme.setTitle("Diktiraj", for: .normal)
            dugme.backgroundColor = .systemGray
            return
        }

        if obradaSesije {
            dugme.isEnabled = false
            dugme.setTitle("Obrada…", for: .normal)
            dugme.backgroundColor = .systemGray
            return
        }

        dugme.isEnabled = true
        if snimaSesijom {
            dugme.setTitle("Stop", for: .normal)
            dugme.backgroundColor = .systemRed
        } else {
            dugme.setTitle("Diktiraj", for: .normal)
            dugme.backgroundColor = .systemBlue
        }
    }
}
