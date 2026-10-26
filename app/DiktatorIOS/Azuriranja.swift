import Foundation
import UserNotifications

struct Azuriranje: Identifiable, Equatable, Codable {
    let verzija: String
    let url: URL
    let napomene: String

    var id: String { verzija }
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

    static func proveri(prisilno: Bool = false) async -> Azuriranje? {
        let sada = Date().timeIntervalSince1970
        let zadnja = UserDefaults.standard.double(forKey: kljucZadnjaProvera)
        if !prisilno, zadnja > 0, sada - zadnja < intervalProvere {
            return kesirano()
        }

        UserDefaults.standard.set(sada, forKey: kljucZadnjaProvera)

        var zahtev = URLRequest(url: apiURL)
        zahtev.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        zahtev.setValue("Diktator-iOS/\(trenutnaVerzija)", forHTTPHeaderField: "User-Agent")
        zahtev.timeoutInterval = 15

        do {
            let (podaci, odgovor) = try await URLSession.shared.data(for: zahtev)
            guard let http = odgovor as? HTTPURLResponse, http.statusCode == 200 else {
                return kesirano()
            }
            guard let json = try JSONSerialization.jsonObject(with: podaci) as? [String: Any],
                  let tag = json["tag_name"] as? String else {
                return kesirano()
            }

            let verzija = normalizuj(tag)
            guard jeNovija(verzija, od: trenutnaVerzija) else {
                UserDefaults.standard.removeObject(forKey: kljucKesirano)
                return nil
            }

            let url = (json["html_url"] as? String).flatMap(URL.init(string:))
                ?? releasesURL
            let napomene = (json["body"] as? String) ?? ""
            let azuriranje = Azuriranje(verzija: verzija, url: url, napomene: napomene)
            if let podaci = try? JSONEncoder().encode(azuriranje) {
                UserDefaults.standard.set(podaci, forKey: kljucKesirano)
            }
            return azuriranje
        } catch {
            return kesirano()
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
        var postavke = await centar.notificationSettings()
        if postavke.authorizationStatus == .notDetermined {
            _ = try? await centar.requestAuthorization(options: [.alert, .sound])
            postavke = await centar.notificationSettings()
        }
        guard jeDozvoljeno(postavke.authorizationStatus) else { return }
        guard UserDefaults.standard.string(forKey: kljucObavesteno) != azuriranje.verzija else {
            return
        }

        let sadrzaj = UNMutableNotificationContent()
        sadrzaj.title = "Dostupno je ažuriranje Diktatora"
        sadrzaj.body = "Verzija \(azuriranje.verzija) je objavljena. Otvori GitHub i preuzmi novu verziju."
        sadrzaj.sound = .default
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

    private static func jeDozvoljeno(_ status: UNAuthorizationStatus) -> Bool {
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
