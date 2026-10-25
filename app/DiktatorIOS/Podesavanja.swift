import Foundation

final class SkladistePodesavanja {
    private static let kljuc = "diktator.ios.podesavanja.v1"

    static func ucitaj() -> Podesavanja {
        guard let podaci = UserDefaults.standard.data(forKey: kljuc),
              let p = try? JSONDecoder().decode(Podesavanja.self, from: podaci) else {
            return Podesavanja()
        }
        return p
    }

    static func sacuvaj(_ p: Podesavanja) {
        guard let podaci = try? JSONEncoder().encode(p) else { return }
        UserDefaults.standard.set(podaci, forKey: kljuc)
    }
}

final class IstorijaSkladiste {
    static func ucitaj() -> [Zapis] {
        guard let podaci = try? Data(contentsOf: Putanje.istorija),
              let zapisi = try? JSONDecoder().decode([Zapis].self, from: podaci) else {
            return []
        }
        Putanje.zastitiFajl(Putanje.istorija)
        return zapisi
    }

    static func sacuvaj(_ zapisi: [Zapis]) {
        let ograniceno = Array(zapisi.prefix(200))
        guard let podaci = try? JSONEncoder().encode(ograniceno) else { return }
        try? podaci.write(to: Putanje.istorija, options: .atomic)
        Putanje.zastitiFajl(Putanje.istorija)
    }
}

enum Recnik {
    static func ucitaj() -> String {
        if let tekst = try? String(contentsOf: Putanje.recnik, encoding: .utf8) {
            Putanje.zastitiFajl(Putanje.recnik)
            return tekst
        }
        return ""
    }

    static func sacuvaj(_ tekst: String) {
        try? tekst.write(to: Putanje.recnik, atomically: true, encoding: .utf8)
        Putanje.zastitiFajl(Putanje.recnik)
    }

    /// Rečnik ide whisper-u kao početni tekst (prompt), zato ga kratimo.
    static func kaoPrompt(_ tekst: String) -> String {
        let redovi = tekst
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let spojeno = redovi.joined(separator: ", ")
        if spojeno.count <= 600 { return spojeno }
        return String(spojeno.prefix(600))
    }
}
