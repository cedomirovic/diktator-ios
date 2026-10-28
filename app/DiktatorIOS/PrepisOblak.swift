// Opcioni prepis u oblaku preko Groq-a. Lokalni whisper ostaje podrazumevan;
// oblak se koristi samo kada ga korisnik uključi, jer tada snimak napušta
// uređaj. Kada oblak ne odgovori, aplikacija se vraća na lokalni prepis.
import Foundation

enum GreskaOblaka: LocalizedError {
    case nemaKljuca
    case neispravanOdgovor
    case status(Int, String?)
    case prazan

    var errorDescription: String? {
        switch self {
        case .nemaKljuca:
            return "Groq API ključ nije unet."
        case .neispravanOdgovor:
            return "Groq je vratio neočekivan odgovor."
        case .status(let kod, let detalj):
            let osnova: String
            switch kod {
            case 400:
                osnova = "Groq ne prihvata zahtev (HTTP 400)."
            case 401, 403:
                osnova = "Groq je odbio ključ (HTTP \(kod))."
            case 404:
                osnova = "Groq ne poznaje model ili putanju (HTTP 404)."
            case 413:
                osnova = "Snimak je predugačak za Groq (HTTP 413)."
            case 429:
                osnova = "Groq traži pauzu — previše zahteva (HTTP 429)."
            default:
                osnova = "Groq je vratio HTTP \(kod)."
            }
            guard let detalj, !detalj.isEmpty else { return osnova }
            return "\(osnova) \(detalj)"
        case .prazan:
            return "Groq nije prepoznao govor."
        }
    }
}

struct PrepisOblak {
    static let adresa = URL(string: "https://api.groq.com/openai/v1/audio/transcriptions")!
    static let adresaModela = URL(string: "https://api.groq.com/openai/v1/models")!
    static let podrazumevaniModel = "whisper-large-v3-turbo"

    static func prepisi(
        uzorci: [Float],
        jezik: String,
        kljuc: String,
        model: String
    ) async throws -> String {
        let ociscenKljuc = kljuc.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ociscenKljuc.isEmpty else { throw GreskaOblaka.nemaKljuca }
        let izabraniModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        let modelZaSlanje = izabraniModel.isEmpty ? podrazumevaniModel : izabraniModel

        let granica = "Diktator-\(UUID().uuidString)"
        var telo = Data()
        func dodaj(_ tekst: String) {
            telo.append(Data(tekst.utf8))
        }
        func polje(_ ime: String, _ vrednost: String) {
            dodaj("--\(granica)\r\n")
            dodaj("Content-Disposition: form-data; name=\"\(ime)\"\r\n\r\n")
            dodaj("\(vrednost)\r\n")
        }

        polje("model", modelZaSlanje)
        polje("response_format", "json")
        polje("temperature", "0")
        if jezik != "auto" {
            polje("language", jezik)
        }
        dodaj("--\(granica)\r\n")
        dodaj("Content-Disposition: form-data; name=\"file\"; filename=\"snimak.wav\"\r\n")
        dodaj("Content-Type: audio/wav\r\n\r\n")
        telo.append(wav(uzorci))
        dodaj("\r\n--\(granica)--\r\n")

        var zahtev = URLRequest(url: adresa)
        zahtev.httpMethod = "POST"
        zahtev.timeoutInterval = 25
        zahtev.setValue("Bearer \(ociscenKljuc)", forHTTPHeaderField: "Authorization")
        zahtev.setValue(
            "multipart/form-data; boundary=\(granica)",
            forHTTPHeaderField: "Content-Type"
        )
        zahtev.httpBody = telo

        let (podaci, odgovor) = try await URLSession.shared.data(for: zahtev)
        guard let http = odgovor as? HTTPURLResponse else {
            throw GreskaOblaka.neispravanOdgovor
        }
        guard http.statusCode == 200 else {
            throw GreskaOblaka.status(http.statusCode, detaljGreske(podaci))
        }

        struct Odgovor: Decodable {
            let text: String
        }
        guard let dekodirano = try? JSONDecoder().decode(Odgovor.self, from: podaci) else {
            throw GreskaOblaka.neispravanOdgovor
        }
        let tekst = dekodirano.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tekst.isEmpty else { throw GreskaOblaka.prazan }
        return tekst
    }

    /// Provera ključa bez slanja zvuka — dovoljan je spisak modela.
    static func proveriKljuc(_ kljuc: String) async throws {
        let ociscen = kljuc.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ociscen.isEmpty else { throw GreskaOblaka.nemaKljuca }

        var zahtev = URLRequest(url: adresaModela)
        zahtev.httpMethod = "GET"
        zahtev.timeoutInterval = 20
        zahtev.setValue("Bearer \(ociscen)", forHTTPHeaderField: "Authorization")

        let (podaci, odgovor) = try await URLSession.shared.data(for: zahtev)
        guard let http = odgovor as? HTTPURLResponse else {
            throw GreskaOblaka.neispravanOdgovor
        }
        guard http.statusCode == 200 else {
            throw GreskaOblaka.status(http.statusCode, detaljGreske(podaci))
        }
    }

    /// Groq u telu odgovora vraća razlog (npr. „Invalid API Key“). Prikazujemo
    /// ga ukratko, da se iz poruke vidi šta tačno ne valja.
    private static func detaljGreske(_ podaci: Data) -> String? {
        struct Odgovor: Decodable {
            struct Detalj: Decodable {
                let message: String?
                let code: String?
            }
            let error: Detalj?
            let message: String?
        }
        guard let dekodirano = try? JSONDecoder().decode(Odgovor.self, from: podaci) else {
            return nil
        }
        let poruka = dekodirano.error?.message ?? dekodirano.message
        guard let poruka, !poruka.isEmpty else { return nil }
        let ocisceno = poruka
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return ocisceno.count > 120 ? String(ocisceno.prefix(120)) + "…" : ocisceno
    }

    /// WAV koji Groq očekuje: mono, 16 kHz, 16 bita.
    private static func wav(_ uzorci: [Float]) -> Data {
        let kanala: UInt16 = 1
        let frekvencija: UInt32 = 16_000
        let bitova: UInt16 = 16
        let bajtovaPoUzorku = UInt32(bitova / 8)
        let velicina = UInt32(uzorci.count) * bajtovaPoUzorku

        var podaci = Data(capacity: 44 + Int(velicina))
        func dodaj(_ tekst: String) {
            podaci.append(Data(tekst.utf8))
        }
        func dodaj32(_ vrednost: UInt32) {
            withUnsafeBytes(of: vrednost.littleEndian) { podaci.append(contentsOf: $0) }
        }
        func dodaj16(_ vrednost: UInt16) {
            withUnsafeBytes(of: vrednost.littleEndian) { podaci.append(contentsOf: $0) }
        }

        dodaj("RIFF")
        dodaj32(36 + velicina)
        dodaj("WAVE")
        dodaj("fmt ")
        dodaj32(16)
        dodaj16(1)
        dodaj16(kanala)
        dodaj32(frekvencija)
        dodaj32(frekvencija * UInt32(kanala) * bajtovaPoUzorku)
        dodaj16(UInt16(kanala * UInt16(bajtovaPoUzorku)))
        dodaj16(bitova)
        dodaj("data")
        dodaj32(velicina)

        for u in uzorci {
            let ogranicen = max(-1.0, min(1.0, u))
            let vrednost = Int16(ogranicen * 32_767.0)
            dodaj16(UInt16(bitPattern: vrednost))
        }
        return podaci
    }
}
