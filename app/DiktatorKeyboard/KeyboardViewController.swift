import CryptoKit
import UIKit

/// Isti izračun kao u aplikaciji (`TajnaServera`). Obe strane dobijaju isti
/// ključ iz `identifierForVendor`, pa nema oslanjanja na pasteboard.
private enum TajnaServera {
    static var token: String {
        let identitet = UIDevice.current.identifierForVendor?.uuidString ?? "bez-identiteta"
        let podaci = Data("com.cedomirovic.diktator.server.\(identitet)".utf8)
        return SHA256.hash(data: podaci)
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

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
    static let sesijaNeogranicena = "sesijaNeogranicena"
    static let stanjeKljuc = "stanje"
    static let token = "token"
    static let tokenVreme = "tokenVreme"
    static let tekst = "tekst"
    static let greska = "greska"

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

    /// Iste boje kao na sistemskoj tastaturi. Dinamičke su, pa tastatura
    /// prati svetli i tamni režim bez posebnog koda.
    private enum BojeTastature {
        static let pozadina = UIColor { izgled in
            izgled.userInterfaceStyle == .dark
                ? UIColor(red: 0.13, green: 0.13, blue: 0.14, alpha: 1)
                : UIColor(red: 0.82, green: 0.83, blue: 0.85, alpha: 1)
        }

        static let slovo = UIColor { izgled in
            izgled.userInterfaceStyle == .dark
                ? UIColor(red: 0.42, green: 0.42, blue: 0.44, alpha: 1)
                : UIColor(white: 1, alpha: 1)
        }

        static let slovoPritisnuto = UIColor { izgled in
            izgled.userInterfaceStyle == .dark
                ? UIColor(white: 0.32, alpha: 1)
                : UIColor(white: 0.85, alpha: 1)
        }

        static let specijalno = UIColor { izgled in
            izgled.userInterfaceStyle == .dark
                ? UIColor(red: 0.30, green: 0.30, blue: 0.31, alpha: 1)
                : UIColor(red: 0.69, green: 0.71, blue: 0.75, alpha: 1)
        }

        static let specijalnoPritisnuto = UIColor { izgled in
            izgled.userInterfaceStyle == .dark
                ? UIColor(red: 0.24, green: 0.24, blue: 0.25, alpha: 1)
                : UIColor(red: 0.61, green: 0.63, blue: 0.67, alpha: 1)
        }
    }

    /// Tipka se ponaša kao sistemska: na dodir potamni, bez plavog tona
    /// koji `UIButton` inače dodaje. Dodatno blago uveća tipku i pusti
    /// haptički odziv, da se tačno oseti šta je pritisnuto.
    private final class Tipka: UIButton {
        private var osnovnaBoja = UIColor.white
        private var pritisnutaBoja = UIColor.lightGray
        private let generatorOdziva = UIImpactFeedbackGenerator(style: .light)

        init() {
            super.init(frame: .zero)
            titleLabel?.adjustsFontSizeToFitWidth = true
            titleLabel?.minimumScaleFactor = 0.6
            addTarget(self, action: #selector(dodirDole), for: [.touchDown, .touchDragEnter])
            addTarget(
                self,
                action: #selector(dodirGore),
                for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit]
            )
            generatorOdziva.prepare()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) nije podržan")
        }

        func postaviBoju(_ osnovna: UIColor, pritisnuta: UIColor) {
            osnovnaBoja = osnovna
            pritisnutaBoja = pritisnuta
            backgroundColor = osnovna
        }

        @objc private func dodirDole() {
            generatorOdziva.impactOccurred()
            generatorOdziva.prepare()
            UIView.animate(
                withDuration: 0.08,
                delay: 0,
                options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseOut]
            ) {
                self.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
            }
        }

        @objc private func dodirGore() {
            UIView.animate(
                withDuration: 0.12,
                delay: 0,
                options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseOut]
            ) {
                self.transform = .identity
            }
        }

        override var isHighlighted: Bool {
            didSet {
                backgroundColor = isHighlighted ? pritisnutaBoja : osnovnaBoja
            }
        }
    }

    private enum StilTipke {
        case slovo
        case specijalno
        case ikona
    }

    private let trakaStanja = UIStackView()
    private let tastatura = UIStackView()
    private let status = UILabel()
    private let spinnerObrade = UIActivityIndicatorView(style: .medium)
    private var dugmeDiktiraj: Tipka?
    private var dugmeNalepi: Tipka?
    private var tekstSpreman = false
    private var poslednjiPrepis = ""

    private var tip: TipTastature = .slova
    private var velikaSlova = false
    private var slovaDugmad: [(dugme: Tipka, osnovni: String)] = []
    private var dugmeShift: Tipka?
    private let zadnjiTokenKey = "diktator.zadnjiToken"
    private let cekaDiktatKey = "diktator.cekaDiktat"
    private let diktatPocetakKey = "diktator.diktatPocetak"
    private let cekaSesijuKey = "diktator.cekaSesiju"
    private let cekaSesijuVremeKey = "diktator.cekaSesijuVreme"
    private var autoNalepiUToku = false
    private var serverUpitUToku = false
    private var serverGreske = 0
    private var zadnjiServerUpit = Date.distantPast
    private var timerAutoNalepi: Timer?
    private var timerIPC: Timer?
    private var timerSesijaTimeout: Timer?
    private var sesijaAktivna = false
    private var sesijaDo: Double = 0
    private var sesijaBezIsteka = false
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
        view.backgroundColor = BojeTastature.pozadina
        postaviVisinu()
        postaviGlavni()
        napraviTastaturu()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        azurirajIzgledTastature()
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

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        azurirajIzgledTastature()
    }

    /// Sistemska tastatura prati izgled polja u koje se kuca, ne samo sistem.
    /// Isto radimo i mi, da se ne pojavi svetla tastatura u tamnoj aplikaciji.
    private func azurirajIzgledTastature() {
        switch textDocumentProxy.keyboardAppearance {
        case .dark:
            overrideUserInterfaceStyle = .dark
        case .light:
            overrideUserInterfaceStyle = .light
        default:
            overrideUserInterfaceStyle = .unspecified
        }
    }

    private func postaviVisinu() {
        let visina: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 300 : 291
        let ogranicenje = view.heightAnchor.constraint(equalToConstant: visina)
        ogranicenje.priority = .defaultHigh
        ogranicenje.isActive = true
    }

    private func postaviGlavni() {
        let diktiraj = napraviDugme(Prevod.t("Diktiraj"), id: "diktiraj", akcija: #selector(diktiraj))
        diktiraj.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        diktiraj.setTitleColor(.white, for: .normal)
        diktiraj.setTitleColor(.white, for: .highlighted)
        diktiraj.setTitleColor(.white, for: .disabled)
        diktiraj.layer.cornerRadius = 9
        diktiraj.layer.shadowOpacity = 0
        diktiraj.widthAnchor.constraint(equalToConstant: 92).isActive = true
        diktiraj.heightAnchor.constraint(equalToConstant: 32).isActive = true
        dugmeDiktiraj = diktiraj

        let nalepi = napraviNalepi()

        status.font = .systemFont(ofSize: 11, weight: .regular)
        status.textColor = .secondaryLabel
        status.textAlignment = .right
        status.numberOfLines = 1
        status.adjustsFontSizeToFitWidth = true
        status.minimumScaleFactor = 0.75
        status.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        status.setContentHuggingPriority(.defaultLow, for: .horizontal)

        spinnerObrade.hidesWhenStopped = true
        spinnerObrade.color = .secondaryLabel
        spinnerObrade.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        spinnerObrade.setContentHuggingPriority(.required, for: .horizontal)

        trakaStanja.axis = .horizontal
        trakaStanja.spacing = 8
        trakaStanja.alignment = .center
        trakaStanja.translatesAutoresizingMaskIntoConstraints = false
        trakaStanja.addArrangedSubview(diktiraj)
        trakaStanja.addArrangedSubview(nalepi)
        trakaStanja.addArrangedSubview(spinnerObrade)
        trakaStanja.addArrangedSubview(status)
        trakaStanja.heightAnchor.constraint(equalToConstant: 34).isActive = true

        tastatura.axis = .vertical
        tastatura.spacing = 6
        tastatura.distribution = .fillEqually
        tastatura.translatesAutoresizingMaskIntoConstraints = false

        let glavni = UIStackView(arrangedSubviews: [trakaStanja, tastatura])
        glavni.axis = .vertical
        glavni.spacing = 6
        glavni.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(glavni)

        NSLayoutConstraint.activate([
            glavni.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 3),
            glavni.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -3),
            glavni.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            glavni.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -6),
        ])
    }

    /// Zeleno dugme u traci iznad tastature. Tekst se inače ubacuje sam, ali
    /// Nalepi ostaje tu za ručno lepljenje (i kao obično lepljenje clipboarda).
    private func napraviNalepi() -> Tipka {
        let dugme = napraviDugme(Prevod.t("Nalepi"), id: "nalepi", akcija: #selector(nalepi))
        dugme.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        dugme.setTitleColor(.white, for: .normal)
        dugme.setTitleColor(.white, for: .highlighted)
        dugme.setTitleColor(.white, for: .disabled)
        dugme.layer.cornerRadius = 9
        dugme.layer.shadowOpacity = 0
        dugme.widthAnchor.constraint(equalToConstant: 80).isActive = true
        dugme.heightAnchor.constraint(equalToConstant: 32).isActive = true
        dugmeNalepi = dugme
        return dugme
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
        azurirajPrikaz()
    }

    /// Srpska latinica je raspoređena kao na sistemskoj tastaturi:
    /// q w e r t z u i o p / a s d f g h j k l č ć / ⇧ z x c v b n m š đ ⌫.
    private func napraviSlova() {
        let prvi = red()
        for slovo in ["q", "w", "e", "r", "t", "z", "u", "i", "o", "p"] {
            prvi.addArrangedSubview(napraviSlovo(slovo))
        }
        izjednaci(prvi)
        tastatura.addArrangedSubview(prvi)

        let drugi = red()
        for slovo in ["a", "s", "d", "f", "g", "h", "j", "k", "l", "č", "ć"] {
            drugi.addArrangedSubview(napraviSlovo(slovo))
        }
        izjednaci(drugi)
        tastatura.addArrangedSubview(drugi)

        let treci = red()
        let shift = napraviIkonu("shift", id: "shift")
        dugmeShift = shift
        treci.addArrangedSubview(shift)

        var slova: [Tipka] = []
        for slovo in ["z", "x", "c", "v", "b", "n", "m", "š", "đ"] {
            let dugme = napraviSlovo(slovo)
            slova.append(dugme)
            treci.addArrangedSubview(dugme)
        }

        let brisi = napraviIkonu("delete.left", id: "delete")
        treci.addArrangedSubview(brisi)
        if let prvo = slova.first {
            for dugme in slova.dropFirst() {
                dugme.widthAnchor.constraint(equalTo: prvo.widthAnchor).isActive = true
            }
            shift.widthAnchor.constraint(equalTo: prvo.widthAnchor, multiplier: 1.45).isActive = true
            brisi.widthAnchor.constraint(equalTo: shift.widthAnchor).isActive = true
        }
        tastatura.addArrangedSubview(treci)

        tastatura.addArrangedSubview(redDonja())
        azurirajSlova()
    }

    private func napraviBrojeve() {
        tastatura.addArrangedSubview(redTekst(["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]))
        tastatura.addArrangedSubview(redTekst(["-", "/", ":", ";", "(", ")", "€", "&", "@", "\""]))
        tastatura.addArrangedSubview(
            redZnakova("#+=", id: "simboli", znakovi: [".", ",", "?", "!", "'"])
        )
        tastatura.addArrangedSubview(redDonja(pocetna: "ABC", idPocetne: "abc"))
    }

    private func napraviSimbole() {
        tastatura.addArrangedSubview(redTekst(["[", "]", "{", "}", "#", "%", "^", "*", "+", "="]))
        tastatura.addArrangedSubview(redTekst(["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"]))
        tastatura.addArrangedSubview(
            redZnakova("123", id: "123", znakovi: [".", ",", "?", "!", "'"])
        )
        tastatura.addArrangedSubview(redDonja(pocetna: "ABC", idPocetne: "abc"))
    }

    /// Donji red kao na iOS tastaturi: 123/ABC, globus, razmak i return.
    /// Diktiraj i Nalepi su u traci iznad tastature.
    private func redDonja(pocetna: String = "123", idPocetne: String = "123") -> UIStackView {
        let redTipki = red()

        let pocetnaTipka = napraviDugme(pocetna, id: idPocetne, stil: .specijalno)
        pocetnaTipka.widthAnchor.constraint(equalToConstant: 46).isActive = true
        redTipki.addArrangedSubview(pocetnaTipka)

        let globus = napraviIkonu("globe", id: "globe")
        globus.widthAnchor.constraint(equalToConstant: 42).isActive = true
        redTipki.addArrangedSubview(globus)

        redTipki.addArrangedSubview(napraviDugme(Prevod.t("razmak"), id: "space", stil: .specijalno))

        let povratak = napraviDugme("return", id: "return", stil: .specijalno)
        povratak.widthAnchor.constraint(equalToConstant: 88).isActive = true
        redTipki.addArrangedSubview(povratak)

        return redTipki
    }

    private func red() -> UIStackView {
        let red = UIStackView()
        red.axis = .horizontal
        red.spacing = 5
        red.alignment = .fill
        red.distribution = .fill
        return red
    }

    private func izjednaci(_ red: UIStackView) {
        guard let prva = red.arrangedSubviews.first else { return }
        for pogled in red.arrangedSubviews.dropFirst() {
            pogled.widthAnchor.constraint(equalTo: prva.widthAnchor).isActive = true
        }
    }

    private func redTekst(_ tekstovi: [String]) -> UIStackView {
        let redTipki = red()
        for tekst in tekstovi {
            redTipki.addArrangedSubview(napraviDugme(tekst, id: "tekst:\(tekst)", stil: .slovo))
        }
        izjednaci(redTipki)
        return redTipki
    }

    /// Red sa širokim prvim i zadnjim dugmetom (123 / #+= / ABC i brisanje),
    /// kao na sistemskoj tastaturi.
    private func redZnakova(_ naslov: String, id: String, znakovi: [String]) -> UIStackView {
        let redTipki = red()

        let prva = napraviDugme(naslov, id: id, stil: .specijalno)
        redTipki.addArrangedSubview(prva)

        var slova: [Tipka] = []
        for znak in znakovi {
            let dugme = napraviDugme(znak, id: "tekst:\(znak)", stil: .slovo)
            slova.append(dugme)
            redTipki.addArrangedSubview(dugme)
        }

        let brisi = napraviIkonu("delete.left", id: "delete")
        redTipki.addArrangedSubview(brisi)

        if let prvo = slova.first {
            for dugme in slova.dropFirst() {
                dugme.widthAnchor.constraint(equalTo: prvo.widthAnchor).isActive = true
            }
            prva.widthAnchor.constraint(equalTo: prvo.widthAnchor, multiplier: 1.5).isActive = true
            brisi.widthAnchor.constraint(equalTo: prva.widthAnchor).isActive = true
        }
        return redTipki
    }

    private func napraviSlovo(_ osnovni: String) -> Tipka {
        let dugme = napraviDugme(osnovni, id: "slovo:\(osnovni)", stil: .slovo)
        slovaDugmad.append((dugme, osnovni))
        return dugme
    }

    private func napraviDugme(
        _ naslov: String,
        id: String,
        stil: StilTipke = .slovo,
        akcija: Selector = #selector(tapKey(_:))
    ) -> Tipka {
        let dugme = Tipka()
        dugme.setTitle(naslov, for: .normal)
        dugme.accessibilityIdentifier = id
        dugme.addTarget(self, action: akcija, for: .touchUpInside)
        dugme.layer.cornerRadius = 5
        dugme.layer.shadowColor = UIColor.black.cgColor
        dugme.layer.shadowOffset = CGSize(width: 0, height: 1)
        dugme.layer.shadowOpacity = 0.22
        dugme.layer.shadowRadius = 0

        switch stil {
        case .slovo:
            dugme.titleLabel?.font = .systemFont(ofSize: 23, weight: .regular)
            dugme.setTitleColor(.label, for: .normal)
            dugme.postaviBoju(BojeTastature.slovo, pritisnuta: BojeTastature.slovoPritisnuto)
        case .specijalno:
            dugme.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
            dugme.setTitleColor(.label, for: .normal)
            dugme.postaviBoju(BojeTastature.specijalno, pritisnuta: BojeTastature.specijalnoPritisnuto)
        case .ikona:
            dugme.postaviBoju(BojeTastature.specijalno, pritisnuta: BojeTastature.specijalnoPritisnuto)
            dugme.tintColor = .label
        }
        return dugme
    }

    private func napraviIkonu(
        _ ime: String,
        id: String,
        akcija: Selector = #selector(tapKey(_:)),
        velicina: CGFloat = 20
    ) -> Tipka {
        let dugme = napraviDugme("", id: id, stil: .ikona, akcija: akcija)
        postaviIkonu(dugme, ime, velicina: velicina)
        switch id {
        case "shift":
            dugme.accessibilityLabel = Prevod.t("Velika slova")
        case "delete":
            dugme.accessibilityLabel = Prevod.t("Obriši")
        case "globe":
            dugme.accessibilityLabel = Prevod.t("Sledeća tastatura")
        case "diktiraj":
            dugme.accessibilityLabel = Prevod.t("Diktiraj")
        default:
            break
        }
        return dugme
    }

    private func postaviIkonu(_ dugme: UIButton, _ ime: String, velicina: CGFloat = 20) {
        let konfiguracija = UIImage.SymbolConfiguration(pointSize: velicina, weight: .regular)
        dugme.setImage(UIImage(systemName: ime, withConfiguration: konfiguracija), for: .normal)
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
        guard let shift = dugmeShift else { return }
        if velikaSlova {
            // Kao na iOS-u: uključen shift je beo, sa tamnom strelicom.
            shift.postaviBoju(BojeTastature.slovo, pritisnuta: BojeTastature.slovoPritisnuto)
            postaviIkonu(shift, "shift.fill")
            shift.tintColor = .black
        } else {
            shift.postaviBoju(BojeTastature.specijalno, pritisnuta: BojeTastature.specijalnoPritisnuto)
            postaviIkonu(shift, "shift")
            shift.tintColor = .label
        }
    }

    @objc private func diktiraj() {
        guard hasFullAccess else {
            prikaziStatus(Prevod.t("Uključi Full Access."))
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
            prikaziStatus(Prevod.t("Obrada…"))
            pokreniTimeoutSesije()
            azurirajPrikaz()
            return
        }

        if obradaSesije {
            prikaziStatus(Prevod.t("Sačekaj da se završi prepis."))
            return
        }

        // Sesija je istekla, aplikacija je ugašena ili status ne stiže.
        // U svim tim slučajevima otvaramo Diktator, koji uključi sesiju i
        // odmah počne da snima — tastatura posle povratka samo preuzme tekst.
        if !sesijaAktivna || !statusSvez {
            Dnevnik.pisi(
                "Diktiraj: nema žive sesije (sesija=\(sesijaAktivna), svez=\(statusSvez)) — otvaram app."
            )
            #if APPSTORE
            // App Store verzija ne otvara aplikaciju iz tastature; korisnik
            // to radi sam, pa mu ovde kažemo šta treba da uradi.
            snimaSesijom = false
            obradaSesije = false
            cekaStartSesije = false
            UserDefaults.standard.set(false, forKey: cekaDiktatKey)
            prikaziStatus(Prevod.t("Otvori Diktator i uključi sesiju."))
            azurirajPrikaz()
            #else
            prikaziStatus(Prevod.t("Otvaram Diktator…"))
            diktatPocetakVreme = Date().timeIntervalSince1970
            UserDefaults.standard.set(diktatPocetakVreme, forKey: diktatPocetakKey)
            UserDefaults.standard.set(true, forKey: cekaDiktatKey)
            otvoriAplikaciju("diktator-ios://dictate")
            #endif
            return
        }

        posaljiKomandu("start")
        snimaSesijom = true
        obradaSesije = false
        cekaStartSesije = true
        diktatPocetakVreme = Date().timeIntervalSince1970
        UserDefaults.standard.set(diktatPocetakVreme, forKey: diktatPocetakKey)
        UserDefaults.standard.set(true, forKey: cekaDiktatKey)
        prikaziStatus(Prevod.t("Snimam…"))
        // Ako aplikacija ne odgovori (ugašena je ili suspendovana), timeout
        // će je otvoriti umesto da tastatura ostane na „Snimam…“.
        pokreniTimeoutSesije()
        azurirajPrikaz()
    }

    /// Status koji je stariji od nekoliko sekundi znači da aplikacija više ne
    /// radi (heartbeat je 1 s), pa je bolje odmah je otvoriti nego čekati
    /// timeout.
    private var statusSvez: Bool {
        zadnjiStatusVreme > 0
            && Date().timeIntervalSince1970 - zadnjiStatusVreme <= 5
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
        #if APPSTORE
        // App Store verzija nikada ne otvara aplikaciju iz tastature (App
        // Store Review 4.4.1). Umesto toga jasno traži da korisnik sam
        // otvori Diktator i uključi sesiju.
        _ = adresa
        UserDefaults.standard.set(false, forKey: cekaDiktatKey)
        ocistiCekanjeSesije()
        snimaSesijom = false
        obradaSesije = false
        cekaStartSesije = false
        timerSesijaTimeout?.invalidate()
        timerSesijaTimeout = nil
        prikaziStatus(Prevod.t("Otvori Diktator i uključi sesiju."))
        azurirajPrikaz()
        #else
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
                prikaziStatus(Prevod.t("Otvori app ručno."))
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
                    self.prikaziStatus(Prevod.t("Otvaram…"))
                } else {
                    UserDefaults.standard.set(false, forKey: self.cekaDiktatKey)
                    self.ocistiCekanjeSesije()
                    self.prikaziStatus(Prevod.t("Otvori app ručno."))
                }
            }
        }
        #endif
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
                self.prikaziStatus(Prevod.t("Otvaram…"))
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
                self.prikaziStatus(Prevod.t("Nema odgovora — otvaram app."))
                self.otvoriAplikaciju("diktator-ios://dictate")
                return
            }

            // Stop je poslat, ali nema statusa „obrada“. Aplikacija verovatno
            // ne radi, pa je otvaramo da se prepis ipak završi.
            if self.obradaSesije && !UserDefaults.standard.bool(forKey: self.cekaDiktatKey) {
                self.obradaSesije = false
                NSLog("Diktator tastatura: stop nije odgovorio, otvaram app.")
                self.prikaziStatus(Prevod.t("Nema odgovora — otvaram app."))
                self.otvoriAplikaciju("diktator-ios://dictate")
            }
        }
    }

    /// iOS 18 je ukinuo stari `openURL:` put preko responder lanca, a iOS 26
    /// traži Full Access. Ovo je samo rezerva ako `extensionContext.open`
    /// iz nekog razloga vrati false dok je Full Access uključen. App Store
    /// verzija je ne koristi — tastatura tamo nikada ne otvara aplikaciju.
    @discardableResult
    private func otvoriPrekoResponderLanca(_ url: URL) -> Bool {
        #if APPSTORE
        _ = url
        return false
        #else
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
        #endif
    }

    @objc private func nalepi() {
        nalepiSaServera()
    }

    private func nalepiSaServera() {
        guard hasFullAccess else {
            prikaziStatus(Prevod.t("Uključi Full Access."))
            return
        }
        guard let url = URL(string: "http://127.0.0.1:8765/tekst") else {
            nalepiIzRezerve()
            return
        }

        // Isti ključ koji računa i aplikacija.
        let serverToken = TajnaServera.token

        prikaziStatus(Prevod.t("Nalepi…"))
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
        prikaziStatus(Prevod.t("Nalepljeno."))
        azurirajPrikaz()
    }

    private func nalepiIzRezerve() {
        guard hasFullAccess else {
            prikaziStatus(Prevod.t("Uključi Full Access."))
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
            prikaziStatus(Prevod.t("Clipboard je prazan."))
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
            let bezIsteka = vrednosti[DiktatorIPC.sesijaNeogranicena] == "1"
            primeniStanje(
                sesija: sesija,
                stanje: stanjeApp,
                vreme: vreme,
                sesijaDo: doKada,
                bezIsteka: bezIsteka
            )
        } else if zadnjaNotifikacija == nil
                    || Date().timeIntervalSince(zadnjaNotifikacija!) > 10 {
            obradiStaleStanje()
        }

        // Ograničena sesija ima `sesijaDo`; sesija bez isteka se ne gasi po
        // vremenu, već samo kada je korisnik završi ili aplikacija prestane
        // da šalje status.
        if sesijaAktivna, !sesijaBezIsteka, sesijaDo > 0, sada >= sesijaDo {
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

        // Aplikacija je nestala usred obrade (ugašena ili srušena). Ne
        // ostavljamo tastaturu zaglavljenu na „Obrada…“ — vraćamo Diktiraj,
        // a sledeći dodir će otvoriti Diktator.
        if obradaSesije, !cekaStartSesije, sada - zadnjiStatusVreme > 20 {
            Dnevnik.pisi("Obrada je zastarela — vraćam Diktiraj.")
            obradaSesije = false
            tekstSpreman = false
            UserDefaults.standard.set(false, forKey: cekaDiktatKey)
            timerAutoNalepi?.invalidate()
            timerAutoNalepi = nil
            prikaziStatus(Prevod.t("Prepis nije stigao — tapni Diktiraj."))
        }

        // Stariji statusi nemaju sesijaDo. Ako su zastareli, ne verujemo im.
        // Kod sesije bez isteka heartbeat je jedini znak da aplikacija radi,
        // pa zastareo status gasi sesiju u tastaturi (sledeći Diktiraj će je
        // ponovo otvoriti).
        if sesijaAktivna, sada - zadnjiStatusVreme > 8,
           sesijaBezIsteka || sesijaDo == 0 {
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
        sesijaDo noviSesijaDo: Double = 0,
        bezIsteka: Bool = false
    ) {
        guard vreme > zadnjeStanjeVreme else { return }
        zadnjeStanjeVreme = vreme
        zadnjiStatusVreme = vreme
        sesijaAktivna = sesija
        let prethodniSesijaDo = sesijaDo
        let prethodnoBezIsteka = sesijaBezIsteka
        sesijaDo = sesija ? noviSesijaDo : 0
        sesijaBezIsteka = sesija && bezIsteka
        if sesija, noviSesijaDo > 0, noviSesijaDo != prethodniSesijaDo {
            Dnevnik.pisi("Sesija važi do \(Int(noviSesijaDo)).")
        } else if sesija, bezIsteka, !prethodnoBezIsteka {
            Dnevnik.pisi("Sesija je bez isteka.")
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
                    prikaziStatus(Prevod.t("Spremno je, nalepi."))
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
            prikaziStatus(Prevod.t("Greška — otvori Diktator."))
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
        sesijaBezIsteka = false
        if snimaSesijom && !cekaStartSesije {
            snimaSesijom = false
        }
        if obradaSesije && !UserDefaults.standard.bool(forKey: cekaDiktatKey) {
            obradaSesije = false
        }
        if UserDefaults.standard.bool(forKey: cekaSesijuKey) && !cekanjeSesijeTraje {
            ocistiCekanjeSesije()
            UserDefaults.standard.set(false, forKey: cekaDiktatKey)
            prikaziStatus(Prevod.t("Sesija nije počela — tapni Diktiraj."))
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
            let bezIsteka = vrednosti[DiktatorIPC.sesijaNeogranicena] == "1"
            Dnevnik.pisi(
                "Darwin fiksni status: sesija=\(sesija) stanje=\(stanje)"
            )
            // Notifikacija je svež signal; vreme uzimamo sada, da pasteboard
            // ne može da vrati staro stanje.
            primeniStanje(
                sesija: sesija,
                stanje: stanje,
                vreme: sada,
                sesijaDo: vazeceDo,
                bezIsteka: bezIsteka
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
            prikaziStatus(Prevod.t("Spremno je, nalepi."))
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
        let token = stringIz(predmet?[DiktatorClipboard.token])
        let vreme = stringIz(predmet?[DiktatorClipboard.vreme]).flatMap(Double.init)
        let tekst = stringIz(predmet?[DiktatorClipboard.tekst])
        if let token, let vreme, let tekst,
           !tekst.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           pocetak == 0 || vreme >= pocetak - 1 {
            let starost = Date().timeIntervalSince1970 - vreme
            if starost >= 0, starost <= 180 {
                Dnevnik.pisi("AutoNalepi: clipboard duzina=\(tekst.count)")
                nalepiAutomatski(tekst, token: token, izvor: "clipboard")
                return
            }
        }

        // Imenovani pasteboard i opšti clipboard umeju da vrate keširanu
        // vrednost u keyboard extension-u. Zato je lokalni server glavni
        // izvor: on uvek vraća stvarni tekst, token i vreme.
        pokusajServer()
    }

    /// Pita lokalni server aplikacije za poslednji prepis. Odgovor nosi i
    /// token i vreme, pa znamo da je tekst nov i da nije već nalepljen.
    private func pokusajServer() {
        guard !serverUpitUToku else { return }
        let sada = Date()
        // Kada server ne odgovara (aplikacija ugašena), razmak raste do 3 s,
        // da ne bismo stalno tukli na zatvoren port.
        let razmak = min(0.4 * pow(2.0, Double(min(serverGreske, 4))), 3.0)
        guard sada.timeIntervalSince(zadnjiServerUpit) > razmak else { return }
        let kljuc = TajnaServera.token
        guard let url = URL(string: "http://127.0.0.1:8765/tekst") else {
            return
        }

        zadnjiServerUpit = sada
        serverUpitUToku = true
        var zahtev = URLRequest(url: url)
        zahtev.timeoutInterval = 1.5
        zahtev.httpMethod = "GET"
        zahtev.setValue(kljuc, forHTTPHeaderField: "X-Diktator-Token")

        URLSession.shared.dataTask(with: zahtev) { [weak self] podaci, odgovor, greska in
            DispatchQueue.main.async {
                guard let self else { return }
                self.serverUpitUToku = false
                if let greska {
                    self.serverGreske += 1
                    // Prvi promašaj i svaki deseti — ostalo bi samo punilo
                    // dnevnik dok aplikacija nije pokrenuta.
                    if self.serverGreske == 1 || self.serverGreske % 10 == 0 {
                        Dnevnik.pisi(
                            "AutoNalepi server: greska \(greska.localizedDescription) (uzastopno \(self.serverGreske))"
                        )
                    }
                    return
                }
                self.serverGreske = 0
                guard let http = odgovor as? HTTPURLResponse else { return }
                guard http.statusCode == 200 else {
                    Dnevnik.pisi("AutoNalepi server: kod=\(http.statusCode)")
                    return
                }
                guard
                      let podaci,
                      let tekst = String(data: podaci, encoding: .utf8),
                      !tekst.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      let token = http.value(
                        forHTTPHeaderField: "X-Diktator-Tekst-Token"
                      ),
                      !token.isEmpty,
                      let vremeString = http.value(
                        forHTTPHeaderField: "X-Diktator-Tekst-Vreme"
                      ),
                      let vreme = Double(vremeString) else {
                    return
                }

                let pocetak = self.pocetakDiktata
                guard pocetak == 0 || vreme >= pocetak - 1 else {
                    Dnevnik.pisi("AutoNalepi server: tekst je stariji od diktata")
                    return
                }
                let starost = Date().timeIntervalSince1970 - vreme
                guard starost >= 0, starost <= 180 else {
                    Dnevnik.pisi("AutoNalepi server: preskačem star tekst")
                    return
                }

                Dnevnik.pisi("AutoNalepi server: duzina=\(tekst.count)")
                self.nalepiAutomatski(tekst, token: token, izvor: "server")
            }
        }.resume()
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
        tekstSpreman = false
        poslednjiPrepis = ""
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
        prikaziStatus(Prevod.t("Nalepljeno automatski."))
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
                status.text = "Uključi Full Access"
                status.textColor = .systemOrange
            } else if obradaSesije {
                status.text = "Prepisujem…"
                status.textColor = .secondaryLabel
            } else if snimaSesijom {
                status.text = "Snimam…"
                status.textColor = .systemRed
            } else if tekstSpreman {
                status.text = "Spremno za lepljenje"
                status.textColor = .systemGreen
            } else if sesijaAktivna {
                status.text = "Sesija ✓"
                status.textColor = .systemGreen
            } else if hasFullAccess {
                status.text = "Sesija ✗"
                status.textColor = .tertiaryLabel
            } else {
                status.text = ""
            }
        }

        azurirajDugmad()
    }

    /// Traka iznad tastature: Diktiraj je plav, crven dok snima i siv kada
    /// ne može; Nalepi je zelen dok tekst može da se ubaci.
    private func azurirajDugmad() {
        if let nalepi = dugmeNalepi {
            nalepi.isEnabled = hasFullAccess && !obradaSesije && !snimaSesijom
            let osnovna: UIColor = nalepi.isEnabled ? .systemGreen : .systemGray3
            let pritisnuta: UIColor = nalepi.isEnabled
                ? UIColor(red: 0.20, green: 0.68, blue: 0.32, alpha: 1)
                : .systemGray3
            nalepi.postaviBoju(osnovna, pritisnuta: pritisnuta)
            nalepi.accessibilityLabel = tekstSpreman ? "Nalepi diktat" : "Nalepi"
        }

        guard let diktiraj = dugmeDiktiraj else { return }

        if !hasFullAccess {
            diktiraj.isEnabled = false
            diktiraj.setTitle(Prevod.t("Diktiraj"), for: .normal)
            diktiraj.postaviBoju(.systemGray, pritisnuta: .systemGray)
            diktiraj.accessibilityLabel = "Diktiraj — potreban je Full Access"
            return
        }

        if obradaSesije {
            diktiraj.isEnabled = false
            diktiraj.setTitle(Prevod.t("Obrada…"), for: .normal)
            diktiraj.postaviBoju(.systemGray, pritisnuta: .systemGray)
            diktiraj.accessibilityLabel = "Prepisujem"
            return
        }

        diktiraj.isEnabled = true
        if snimaSesijom {
            diktiraj.setTitle(Prevod.t("Stop"), for: .normal)
            diktiraj.postaviBoju(
                .systemRed,
                pritisnuta: UIColor(red: 0.78, green: 0.16, blue: 0.16, alpha: 1)
            )
            diktiraj.accessibilityLabel = "Zaustavi snimanje"
        } else {
            diktiraj.setTitle(Prevod.t("Diktiraj"), for: .normal)
            diktiraj.postaviBoju(
                .systemBlue,
                pritisnuta: UIColor(red: 0.11, green: 0.42, blue: 0.86, alpha: 1)
            )
            diktiraj.accessibilityLabel = "Diktiraj"
        }
    }
}
