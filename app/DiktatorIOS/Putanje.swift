import Foundation

/// Zajedničke putanje u aplikaciji. Sve ide kroz URL, bez spajanja stringova.
enum Putanje {
    static var podrska: URL {
        let baza = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = baza.appendingPathComponent("Diktator", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var modeli: URL {
        let dir = podrska.appendingPathComponent("models", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var istorija: URL {
        podrska.appendingPathComponent("istorija.json")
    }

    static var statistika: URL {
        podrska.appendingPathComponent("statistika.json")
    }

    static var recnik: URL {
        podrska.appendingPathComponent("recnik.txt")
    }

    static func velicina(_ url: URL) -> Int64 {
        guard let atributi = try? FileManager.default.attributesOfItem(atPath: url.path),
              let broj = atributi[.size] as? NSNumber else { return 0 }
        return broj.int64Value
    }

    static func zastitiFajl(_ url: URL) {
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: url.path
        )
    }
}
