import Foundation
import UserNotifications

struct Azuriranje: Identifiable, Equatable, Codable {
    let verzija: String
    let url: URL
    let napomene: String

    var id: String { verzija }
}

enum RezultatProvere {
    case dostupno(Azuriranje)
    case nema
    case greska
}

/// Provera novih verzija preko GitHub release-a. Aplikacija nije na App
/// Store-u, pa nema sistemsku proveru ažuriranja; ovo je zamena za nju.
enum Azuriranja {
    static let repo = "cedomirovic/diktator-ios"
    static let releasesURL = URL(string: "https://github.com/\(repo)/releases")!

    private static let apiURL = URL(
        string: "https://api.github.com/repos/\(repo)/releases/latest"
    )!
    private static let kljucZadnjaProvera = "diktator.azuriranja.zadnjaProvera"
    private static let kljucKesirano = "diktator.azuriranja.kesirano"
    private static let kljucObavesteno = "diktator.azuriranja.obavesteno"
    private static let intervalProvere: TimeInterval = 6 * 3600

    static var trenutnaVerzija: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "0"
    }

    static func proveri(prisilno: Bool = false) async -> RezultatProvere {
        let sada = Date().timeIntervalSince1970
        let zadnja = UserDefaults.standard.double(forKey: kljucZadnjaProvera)
        if !prisilno, zadnja > 0, sada - zadnja < intervalProvere {
            return kesirano().map { .dostupno($0) } ?? .nema
        }

        var zahtev = URLRequest(url: apiURL)
        zahtev.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        zahtev.setValue("Diktator-iOS/\(trenutnaVerzija)", forHTTPHeaderField: "User-Agent")
        zahtev.timeoutInterval = 15

        do {
            let (podaci, odgovor) = try await URLSession.shared.data(for: zahtev)
            guard let http = odgovor as? HTTPURLResponse else {
                return kesirano().map { .dostupno($0) } ?? .greska
            }
            // 404 znači da repozitorijum još nema objavljen release — to nije
            // greška u mreži, nego jednostavno nema nove verzije.
            if http.statusCode == 404 {
                UserDefaults.standard.set(sada, forKey: kljucZadnjaProvera)
                UserDefaults.standard.removeObject(forKey: kljucKesirano)
                return .nema
            }
            guard http.statusCode == 200 else {
                return kesirano().map { .dostupno($0) } ?? .greska
            }
            guard let json = try JSONSerialization.jsonObject(with: podaci) as? [String: Any],
                  let tag = json["tag_name"] as? String else {
                return kesirano().map { .dostupno($0) } ?? .greska
            }

            // Uspešnu proveru pamtimo tek sada; neuspeh ne sme da blokira
            // sledeću proveru šest sati.
            UserDefaults.standard.set(sada, forKey: kljucZadnjaProvera)

            let verzija = normalizuj(tag)
            guard jeNovija(verzija, od: trenutnaVerzija) else {
                UserDefaults.standard.removeObject(forKey: kljucKesirano)
                return .nema
            }

            let url = (json["html_url"] as? String).flatMap(URL.init(string:))
                ?? releasesURL
            let napomene = (json["body"] as? String) ?? ""
            let azuriranje = Azuriranje(verzija: verzija, url: url, napomene: napomene)
            if let podaci = try? JSONEncoder().encode(azuriranje) {
                UserDefaults.standard.set(podaci, forKey: kljucKesirano)
            }
            return .dostupno(azuriranje)
        } catch {
            return kesirano().map { .dostupno($0) } ?? .greska
        }
    }

    static func kesirano() -> Azuriranje? {
        guard let podaci = UserDefaults.standard.data(forKey: kljucKesirano),
              let azuriranje = try? JSONDecoder().decode(Azuriranje.self, from: podaci) else {
            return nil
        }
        return jeNovija(azuriranje.verzija, od: trenutnaVerzija) ? azuriranje : nil
    }

    static func posaljiNotifikaciju(_ azuriranje: Azuriranje) async {
        let centar = UNUserNotificationCenter.current()
        // Ne pitamo za dozvolu u sred provere — dijalog se pojavljuje kada
        // korisnik to sam zatraži (uključi prekidač ili tapne test).
        let postavke = await centar.notificationSettings()
        guard jeDozvoljeno(postavke.authorizationStatus) else { return }
        guard UserDefaults.standard.string(forKey: kljucObavesteno) != azuriranje.verzija else {
            return
        }

        let sadrzaj = UNMutableNotificationContent()
        sadrzaj.title = "Dostupno je ažuriranje Diktatora"
        sadrzaj.body = "Verzija \(azuriranje.verzija) je objavljena. Otvori GitHub i preuzmi novu verziju."
        sadrzaj.sound = .default
        sadrzaj.categoryIdentifier = "diktator.azuriranje"
        sadrzaj.userInfo = ["url": azuriranje.url.absoluteString]

        let zahtev = UNNotificationRequest(
            identifier: "diktator.azuriranje.\(azuriranje.verzija)",
            content: sadrzaj,
            trigger: nil
        )
        try? await centar.add(zahtev)
        UserDefaults.standard.set(azuriranje.verzija, forKey: kljucObavesteno)
    }

    /// Testno obaveštenje da korisnik odmah vidi da li su notifikacije
    /// uključene, bez čekanja na stvarnu novu verziju.
    @discardableResult
    static func posaljiTestnuNotifikaciju() async -> Bool {
        let centar = UNUserNotificationCenter.current()
        var postavke = await centar.notificationSettings()
        if postavke.authorizationStatus == .notDetermined {
            _ = try? await centar.requestAuthorization(options: [.alert, .sound])
            postavke = await centar.notificationSettings()
        }
        guard jeDozvoljeno(postavke.authorizationStatus) else { return false }

        let sadrzaj = UNMutableNotificationContent()
        sadrzaj.title = "Diktator"
        sadrzaj.body = "Obaveštenja o novim verzijama rade."
        sadrzaj.sound = .default
        let zahtev = UNNotificationRequest(
            identifier: "diktator.test.\(UUID().uuidString)",
            content: sadrzaj,
            trigger: nil
        )
        do {
            try await centar.add(zahtev)
            return true
        } catch {
            return false
        }
    }

    /// Vraća trenutni status, a prvi put pita korisnika za dozvolu. Tako
    /// dugme „Testiraj obaveštenje“ odmah pokaže sistemski dijalog umesto da
    /// tiho ne uradi ništa.
    static func statusDozvole() async -> UNAuthorizationStatus {
        let centar = UNUserNotificationCenter.current()
        var postavke = await centar.notificationSettings()
        if postavke.authorizationStatus == .notDetermined {
            _ = try? await centar.requestAuthorization(options: [.alert, .sound])
            postavke = await centar.notificationSettings()
        }
        return postavke.authorizationStatus
    }

    static func jeDozvoljeno(_ status: UNAuthorizationStatus) -> Bool {
        status == .authorized || status == .provisional || status == .ephemeral
    }

    static func normalizuj(_ tag: String) -> String {
        var verzija = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        if verzija.lowercased().hasPrefix("v") {
            verzija.removeFirst()
        }
        return verzija
    }

    static func jeNovija(_ nova: String, od stara: String) -> Bool {
        let a = nova.split(separator: ".").map { Int($0) ?? 0 }
        let b = stara.split(separator: ".").map { Int($0) ?? 0 }
        let broj = max(a.count, b.count)
        for indeks in 0..<broj {
            let x = indeks < a.count ? a[indeks] : 0
            let y = indeks < b.count ? b[indeks] : 0
            if x != y { return x > y }
        }
        return false
    }
}
