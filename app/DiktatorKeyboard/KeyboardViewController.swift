import UIKit

final class KeyboardViewController: UIInputViewController {
    private enum TipTastature {
        case slova
        case brojevi
        case simboli
    }

    private let gornjaTraka = UIStackView()
    private let tastatura = UIStackView()
    private let status = UILabel()

    private var tip: TipTastature = .slova
    private var velikaSlova = false
    private var slovaDugmad: [(dugme: UIButton, osnovni: String)] = []
    private var dugmeShift: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        postaviVisinu()
        postaviGlavni()
        napraviTastaturu()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        azurirajStatus()
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

        let nalepi = napraviDugme(
            "Nalepi",
            id: "nalepi",
            akcija: #selector(nalepi)
        )
        nalepi.backgroundColor = .systemGreen
        nalepi.setTitleColor(.white, for: .normal)
        nalepi.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        nalepi.widthAnchor.constraint(equalToConstant: 80).isActive = true

        status.font = .systemFont(ofSize: 11)
        status.textColor = .secondaryLabel
        status.textAlignment = .right
        status.numberOfLines = 1
        status.adjustsFontSizeToFitWidth = true
        status.minimumScaleFactor = 0.75
        status.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        status.setContentHuggingPriority(.defaultLow, for: .horizontal)

        gornjaTraka.addArrangedSubview(diktiraj)
        gornjaTraka.addArrangedSubview(nalepi)
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
        guard let url = URL(string: "diktator-ios://dictate") else { return }

        // iOS 26 traži Full Access i za otvaranje matične aplikacije.
        // Bez njega `extensionContext.open` vrati false, pa odmah objasnimo
        // korisniku šta treba uključiti umesto nejasne poruke.
        guard hasFullAccess else {
            prikaziStatus("Uključi Full Access.")
            return
        }

        prikaziStatus("Otvaram…")
        NSLog("Diktator tastatura: otvaram %@, Full Access = %@", url.absoluteString, hasFullAccess ? "da" : "ne")

        guard let kontekst = extensionContext else {
            if !otvoriPrekoResponderLanca(url) {
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
                    self.prikaziStatus("Otvori app ručno.")
                }
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
        guard hasFullAccess else {
            prikaziStatus("Uključi Full Access.")
            return
        }
        guard let tekst = UIPasteboard.general.string?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !tekst.isEmpty else {
            prikaziStatus("Clipboard je prazan.")
            return
        }
        textDocumentProxy.insertText(tekst)
        prikaziStatus("Nalepljeno.")
    }

    private func prikaziStatus(_ tekst: String) {
        status.text = tekst
        status.textColor = .secondaryLabel
    }

    private func azurirajStatus() {
        if hasFullAccess {
            status.text = "Full Access ✓"
            status.textColor = .systemGreen
        } else {
            status.text = "Full Access ✗"
            status.textColor = .systemOrange
        }
    }
}
