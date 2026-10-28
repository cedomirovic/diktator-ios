// Opciono doterivanje teksta preko izabranog servisa. Isključeno je po
// defaultu i šalje se samo gotov tekst (bez snimka) — i to samo ako korisnik
// uključi doterivanje.
import Foundation

enum GreskaDoterivanja: LocalizedError {
    case nemaKljuca(String)
    case neispravnaAdresa
    case nebezbednaAdresa
    case odgovor(String)
    case prazan(String)

    var errorDescription: String? {
        switch self {
        case .nemaKljuca(let naziv):
            return "\(naziv) API ključ nije unet."
        case .neispravnaAdresa:
            return "Adresa servisa za doterivanje nije ispravna."
        case .nebezbednaAdresa:
            return "Adresa servisa mora da koristi https://. http:// je dozvoljen samo za localhost (Ollama)."
        case .odgovor(let poruka):
            return poruka
        case .prazan(let naziv):
            return "\(naziv) je vratio prazan tekst."
        }
    }
}

struct Doterivac {
    static func doteraj(
        _ tekst: String,
        provajder: ProvajderDoterivanja,
        kljuc: String,
        model: String,
        adresa: String,
        jezik: String = "sr"
    ) async throws -> String {
        let ociscenKljuc = kljuc.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !provajder.traziKljuc || !ociscenKljuc.isEmpty else {
            throw GreskaDoterivanja.nemaKljuca(provajder.naziv)
        }

        let izabraniModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !izabraniModel.isEmpty else {
            throw GreskaDoterivanja.odgovor("\(provajder.naziv): model nije unet.")
        }
        let url: URL
        if case .gemini = provajder.vrsta {
            // Gemini traži model u putanji, pa se adresa sastavlja od osnove i
            // izabranog modela. Naziv modela sme da sadrži samo bezbedne znake.
            var modelZaUrl = izabraniModel
            if modelZaUrl.hasPrefix("models/") {
                modelZaUrl.removeFirst("models/".count)
            }
            let dozvoljeni = CharacterSet(
                charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-"
            )
            guard modelZaUrl.unicodeScalars.allSatisfy({ dozvoljeni.contains($0) }) else {
                throw GreskaDoterivanja.odgovor("\(provajder.naziv): naziv modela nije ispravan.")
            }
            let osnovna = adresa.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let osnovniURL = try proveriAdresu(osnovna)
            let modelURL = osnovniURL.appendingPathComponent(modelZaUrl)
            url = try proveriAdresu(modelURL.absoluteString + ":generateContent")
        } else {
            url = try proveriAdresu(adresa)
        }

        let uputstvo = uputstvo(jezik: jezik)
        var zahtev = URLRequest(url: url)
        zahtev.httpMethod = "POST"
        zahtev.timeoutInterval = 60
        zahtev.setValue("application/json", forHTTPHeaderField: "Content-Type")

        switch provajder.vrsta {
        case .openAIKompatibilan:
            if !ociscenKljuc.isEmpty {
                zahtev.setValue("Bearer \(ociscenKljuc)", forHTTPHeaderField: "Authorization")
            }
            let telo: [String: Any] = [
                "model": izabraniModel,
                "temperature": 0,
                "messages": [
                    ["role": "system", "content": uputstvo],
                    ["role": "user", "content": tekst],
                ],
            ]
            zahtev.httpBody = try JSONSerialization.data(withJSONObject: telo)

        case .anthropic:
            zahtev.setValue(ociscenKljuc, forHTTPHeaderField: "x-api-key")
            zahtev.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            let telo: [String: Any] = [
                "model": izabraniModel,
                "max_tokens": 2048,
                "temperature": 0,
                "system": uputstvo,
                "messages": [
                    ["role": "user", "content": tekst],
                ],
            ]
            zahtev.httpBody = try JSONSerialization.data(withJSONObject: telo)

        case .gemini:
            zahtev.setValue(ociscenKljuc, forHTTPHeaderField: "x-goog-api-key")
            let telo: [String: Any] = [
                "systemInstruction": [
                    "parts": [["text": uputstvo]],
                ],
                "contents": [
                    ["role": "user", "parts": [["text": tekst]]],
                ],
                "generationConfig": ["temperature": 0],
            ]
            zahtev.httpBody = try JSONSerialization.data(withJSONObject: telo)

        case .ollama:
            let telo: [String: Any] = [
                "model": izabraniModel,
                "stream": false,
                "messages": [
                    ["role": "system", "content": uputstvo],
                    ["role": "user", "content": tekst],
                ],
                "options": ["temperature": 0],
            ]
            zahtev.httpBody = try JSONSerialization.data(withJSONObject: telo)
        }

        let (podaci, odgovor) = try await URLSession.shared.data(for: zahtev)
        guard let http = odgovor as? HTTPURLResponse else {
            throw GreskaDoterivanja.odgovor("\(provajder.naziv) nije vratio HTTP odgovor.")
        }
        guard http.statusCode == 200 else {
            throw GreskaDoterivanja.odgovor(porukaZaStatus(http.statusCode, naziv: provajder.naziv))
        }

        let ocisceno: String?
        do {
            ocisceno = try ocitaj(podaci, vrsta: provajder.vrsta)
        } catch {
            throw GreskaDoterivanja.odgovor("\(provajder.naziv) je vratio neočekivan odgovor.")
        }

        guard let tekst = ocisceno?.trimmingCharacters(in: .whitespacesAndNewlines),
              !tekst.isEmpty else {
            throw GreskaDoterivanja.prazan(provajder.naziv)
        }
        return tekst
    }

    /// Za bezbednost dozvoljavamo HTTPS svuda, a HTTP samo za loopback
    /// (Ollama i lokalni modeli). Tako API ključ i tekst nikad ne idu
    /// nešifrovani preko mreže.
    static func proveriAdresu(_ tekst: String) throws -> URL {
        let ocisceno = tekst.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: ocisceno),
              let sema = url.scheme?.lowercased(),
              let host = url.host?.lowercased(),
              !host.isEmpty,
              url.user == nil,
              url.password == nil else {
            throw GreskaDoterivanja.neispravnaAdresa
        }
        guard sema == "http" || sema == "https" else {
            throw GreskaDoterivanja.neispravnaAdresa
        }
        let ociscenHost = host
            .trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
        let lokalna = ociscenHost == "localhost" || ociscenHost == "127.0.0.1" || ociscenHost == "::1"
        guard sema == "https" || lokalna else {
            throw GreskaDoterivanja.nebezbednaAdresa
        }
        return url
    }

    private static func ocitaj(_ podaci: Data, vrsta: VrstaDoterivaca) throws -> String? {
        switch vrsta {
        case .openAIKompatibilan:
            struct Odgovor: Decodable {
                struct Izbor: Decodable {
                    struct Poruka: Decodable { let content: String }
                    let message: Poruka
                }
                let choices: [Izbor]
            }
            let dekodirano = try JSONDecoder().decode(Odgovor.self, from: podaci)
            return dekodirano.choices.first?.message.content

        case .anthropic:
            struct Odgovor: Decodable {
                struct Blok: Decodable {
                    let type: String
                    let text: String?
                }
                let content: [Blok]
            }
            let dekodirano = try JSONDecoder().decode(Odgovor.self, from: podaci)
            return dekodirano.content
                .filter { $0.type == "text" }
                .compactMap(\.text)
                .joined(separator: " ")

        case .gemini:
            struct Odgovor: Decodable {
                struct Kandidat: Decodable {
                    struct Sadrzaj: Decodable {
                        struct Deo: Decodable {
                            let text: String?
                            let thought: Bool?
                        }
                        let parts: [Deo]
                    }
                    let content: Sadrzaj
                }
                let candidates: [Kandidat]
            }
            let dekodirano = try JSONDecoder().decode(Odgovor.self, from: podaci)
            return dekodirano.candidates.first?.content.parts
                .filter { $0.thought != true }
                .compactMap(\.text)
                .joined(separator: " ")

        case .ollama:
            struct Odgovor: Decodable {
                struct Poruka: Decodable { let content: String }
                let message: Poruka
            }
            let dekodirano = try JSONDecoder().decode(Odgovor.self, from: podaci)
            return dekodirano.message.content
        }
    }

    private static func porukaZaStatus(_ kod: Int, naziv: String) -> String {
        switch kod {
        case 401, 403:
            return "\(naziv) je odbio ključ (HTTP \(kod))."
        case 404:
            return "\(naziv) ne nalazi adresu ili model (HTTP 404)."
        case 429:
            return "\(naziv) traži pauzu — previše zahteva (HTTP 429)."
        default:
            return "\(naziv) je vratio HTTP \(kod)."
        }
    }

    private static func uputstvo(jezik: String) -> String {
        if jezik == "en" {
            return """
            You are an English proofreader. Fix only punctuation, capitalization, \
            and obvious speech-recognition errors. Do not change the meaning, add \
            sentences, or translate. Return only the corrected text, without \
            explanations or quotation marks. Preserve these names and terms: \
            Nemanja Čedomirović, Tamara Pandža, Diktator, Beograd.
            """
        }
        return """
        Ti si lektor za srpski jezik. Ispravi samo interpunkciju, velika slova i \
        očigledne greške u prepoznavanju govora. Ne menjaj smisao, ne dodaj nove \
        rečenice i ne prevodi. Vrati isključivo ispravljen tekst, bez objašnjenja \
        i bez navodnika. Imena i pojmovi koje treba poštovati: Nemanja Čedomirović, \
        Tamara Pandža, Diktator, Beograd.
        """
    }
}
