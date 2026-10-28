// Katalog servisa za opciono doterivanje teksta. Redosled je i redosled u
// izboru u Podešavanjima; DeepSeek ostaje podrazumevani zbog starih ključeva.
import Foundation

enum VrstaDoterivaca {
    case openAIKompatibilan
    case anthropic
    case gemini
    case ollama
}

struct ProvajderDoterivanja: Identifiable, Equatable {
    let id: String
    let naziv: String
    let opis: String
    let vrsta: VrstaDoterivaca
    let model: String
    let adresa: String
    let traziKljuc: Bool
    let prikazujeKljuc: Bool
    let prikazujeAdresu: Bool
    let uputstvo: String
    let linkNaslov: String?
    let link: URL?
}

enum ProvajderiDoterivanja {
    static let customId = "custom"

    static let podrazumevani = ProvajderDoterivanja(
        id: "deepseek",
        naziv: "DeepSeek",
        opis: "Jeftin i brz servis za srpski i engleski. Traži API ključ.",
        vrsta: .openAIKompatibilan,
        model: "deepseek-chat",
        adresa: "https://api.deepseek.com/chat/completions",
        traziKljuc: true,
        prikazujeKljuc: true,
        prikazujeAdresu: false,
        uputstvo: "Ključ praviš na platform.deepseek.com → API keys. Model: deepseek-chat.",
        linkNaslov: "Otvori ključeve",
        link: URL(string: "https://platform.deepseek.com/api_keys")
    )

    static let openAI = ProvajderDoterivanja(
        id: "openai",
        naziv: "OpenAI / ChatGPT",
        opis: "ChatGPT API. ChatGPT Plus pretplata nije dovoljna — potreban je API ključ.",
        vrsta: .openAIKompatibilan,
        model: "gpt-4o-mini",
        adresa: "https://api.openai.com/v1/chat/completions",
        traziKljuc: true,
        prikazujeKljuc: true,
        prikazujeAdresu: false,
        uputstvo: "Ključ praviš na platform.openai.com → API keys. Model: gpt-4o-mini.",
        linkNaslov: "Otvori ključeve",
        link: URL(string: "https://platform.openai.com/api-keys")
    )

    static let anthropic = ProvajderDoterivanja(
        id: "anthropic",
        naziv: "Anthropic Claude",
        opis: "Claude API. Claude Code je druga alatka — ovde ide Anthropic API ključ.",
        vrsta: .anthropic,
        model: "claude-haiku-5-5",
        adresa: "https://api.anthropic.com/v1/messages",
        traziKljuc: true,
        prikazujeKljuc: true,
        prikazujeAdresu: false,
        uputstvo: "Ključ praviš na console.anthropic.com → API keys. Model: claude-haiku-5-5.",
        linkNaslov: "Otvori ključeve",
        link: URL(string: "https://console.anthropic.com/settings/keys")
    )

    static let gemini = ProvajderDoterivanja(
        id: "gemini",
        naziv: "Google Gemini",
        opis: "Gemini API. Google AI Studio ključ; Gemini Advanced pretplata nije dovoljna.",
        vrsta: .gemini,
        model: "gemini-3.5-flash-lite",
        adresa: "https://generativelanguage.googleapis.com/v1beta/models",
        traziKljuc: true,
        prikazujeKljuc: true,
        prikazujeAdresu: false,
        uputstvo: "Ključ praviš na aistudio.google.com → Get API key. Model: gemini-3.5-flash-lite (može i noviji).",
        linkNaslov: "Otvori ključeve",
        link: URL(string: "https://aistudio.google.com/app/apikey")
    )

    static let ollama = ProvajderDoterivanja(
        id: "ollama",
        naziv: "Ollama (lokalno)",
        opis: "Model radi na računaru u istoj mreži. Nema ključa i tekst ne napušta tu mrežu.",
        vrsta: .ollama,
        model: "llama3.2",
        adresa: "http://localhost:11434/api/chat",
        traziKljuc: false,
        prikazujeKljuc: false,
        prikazujeAdresu: false,
        uputstvo: "Instaliraj Ollama na računar, pa pokreni `ollama pull llama3.2`. Adresa: localhost:11434.",
        linkNaslov: "Preuzmi Ollama",
        link: URL(string: "https://ollama.com/download")
    )

    static let custom = ProvajderDoterivanja(
        id: customId,
        naziv: "Drugi OpenAI-kompatibilni",
        opis: "OpenRouter, Groq, LM Studio, vLLM ili bilo koji servis sa OpenAI formatom.",
        vrsta: .openAIKompatibilan,
        model: "local-model",
        adresa: "http://localhost:1234/v1/chat/completions",
        traziKljuc: false,
        prikazujeKljuc: true,
        prikazujeAdresu: true,
        uputstvo: "Adresa mora da koristi https:// (http:// samo za localhost) i da se završava sa /chat/completions. Model piši tačno kako ga servis traži.",
        linkNaslov: nil,
        link: nil
    )

    static let svi = [podrazumevani, openAI, anthropic, gemini, ollama, custom]

    static func nadji(_ id: String) -> ProvajderDoterivanja? {
        svi.first { $0.id == id }
    }
}
