import Foundation

enum StanjeAplikacije: Equatable {
    case mirno
    case snima
    case priprema
    case prepisuje
    case doteruje
    case greska(String)

    var naslov: String {
        switch self {
        case .mirno: return "Spreman"
        case .snima: return "Snimam…"
        case .priprema: return "Pripremam model…"
        case .prepisuje: return "Prepisujem…"
        case .doteruje: return "Doterujem…"
        case .greska: return "Greška"
        }
    }

    var detalj: String {
        switch self {
        case .mirno:
            return "Tapni mikrofon i govori. Tekst se posle prepisa kopira u clipboard."
        case .snima:
            return "Govori sada. Tapni ponovo da završiš."
        case .priprema:
            return "Model se učitava u memoriju, sačekaj trenutak."
        case .prepisuje:
            return "Pretvaram govor u tekst."
        case .doteruje:
            return "Popravljam interpunkciju i imena preko izabranog servisa."
        case .greska(let poruka):
            return poruka
        }
    }

    var jeSnimanje: Bool {
        if case .snima = self { return true }
        return false
    }

    var jeZauzet: Bool {
        switch self {
        case .priprema, .prepisuje, .doteruje: return true
        default: return false
        }
    }
}

struct Zapis: Identifiable, Codable, Equatable {
    var id = UUID()
    var tekst: String
    var datum = Date()
    var trajanje: Double = 0
    var jezik: String = "auto"
}

/// Brzina i tačnost prepisa. Štedljivi režim troši manje RAM-a.
enum RezimPrepisa: String, CaseIterable, Identifiable {
    case kvalitet
    case stedljivo

    var id: String { rawValue }

    var naziv: String {
        switch self {
        case .kvalitet: return "Najbolji kvalitet"
        case .stedljivo: return "Manje memorije"
        }
    }

    var opis: String {
        switch self {
        case .kvalitet:
            return "Beam search sa 5 kandidata — tačniji, troši više RAM-a."
        case .stedljivo:
            return "Greedy dekodiranje — brže i manje RAM-a, uz moguće sitne razlike."
        }
    }

    static func iz(_ id: String) -> RezimPrepisa {
        RezimPrepisa(rawValue: id) ?? .stedljivo
    }
}

/// Koliko dugo model ostaje u memoriji posle prepisa.
enum OslobadjanjeModela: String, CaseIterable, Identifiable {
    case odmah
    case jedan
    case pet
    case petnaest
    case trideset
    case nikad

    var id: String { rawValue }

    var naziv: String {
        switch self {
        case .odmah: return "Odmah posle prepisa"
        case .jedan: return "Posle 1 minuta"
        case .pet: return "Posle 5 minuta"
        case .petnaest: return "Posle 15 minuta"
        case .trideset: return "Posle 30 minuta"
        case .nikad: return "Nikad"
        }
    }

    var sekunde: TimeInterval? {
        switch self {
        case .odmah: return 0
        case .jedan: return 60
        case .pet: return 300
        case .petnaest: return 900
        case .trideset: return 1800
        case .nikad: return nil
        }
    }

    static func iz(_ id: String) -> OslobadjanjeModela {
        OslobadjanjeModela(rawValue: id) ?? .pet
    }
}

struct Podesavanja: Codable, Equatable {
    /// Na srpskom sistemu odmah biramo srpski, jer je automatska detekcija
    /// na kratkim snimcima manje pouzdana. Na drugim jezicima ostaje "auto".
    static var podrazumevaniJezik: String {
        let prvi = Locale.preferredLanguages.first?.lowercased() ?? ""
        return prvi.hasPrefix("sr") ? "sr" : "auto"
    }

    var jezik = Podesavanja.podrazumevaniJezik
    var model = Modeli.podrazumevani.id
    var rezimPrepisa = RezimPrepisa.stedljivo.rawValue
    var oslobadjanjeModela = OslobadjanjeModela.pet.rawValue
    var cuvajIstoriju = true
    var proveravajAzuriranja = true
    var doterivanje = false
    var provajderDoterivanja = ProvajderiDoterivanja.podrazumevani.id
    var modeliDoterivanja: [String: String] = [:]
    var adresaCustomDoterivanja = ProvajderiDoterivanja.custom.adresa

    init() {}

    private enum CodingKeys: String, CodingKey {
        case jezik
        case model
        case rezimPrepisa
        case oslobadjanjeModela
        case cuvajIstoriju
        case proveravajAzuriranja
        case doterivanje
        case provajderDoterivanja
        case modeliDoterivanja
        case adresaCustomDoterivanja
    }

    init(from decoder: Decoder) throws {
        let kontejner = try decoder.container(keyedBy: CodingKeys.self)
        jezik = try kontejner.decodeIfPresent(String.self, forKey: .jezik)
            ?? Podesavanja.podrazumevaniJezik
        model = try kontejner.decodeIfPresent(String.self, forKey: .model)
            ?? Modeli.nadjiPostojeci()?.id
            ?? Modeli.podrazumevani.id
        rezimPrepisa = try kontejner.decodeIfPresent(String.self, forKey: .rezimPrepisa)
            ?? RezimPrepisa.stedljivo.rawValue
        if RezimPrepisa(rawValue: rezimPrepisa) == nil {
            rezimPrepisa = RezimPrepisa.stedljivo.rawValue
        }
        oslobadjanjeModela = try kontejner.decodeIfPresent(String.self, forKey: .oslobadjanjeModela)
            ?? OslobadjanjeModela.pet.rawValue
        if OslobadjanjeModela(rawValue: oslobadjanjeModela) == nil {
            oslobadjanjeModela = OslobadjanjeModela.pet.rawValue
        }
        cuvajIstoriju = try kontejner.decodeIfPresent(Bool.self, forKey: .cuvajIstoriju) ?? true
        proveravajAzuriranja = try kontejner.decodeIfPresent(Bool.self, forKey: .proveravajAzuriranja) ?? true
        doterivanje = try kontejner.decodeIfPresent(Bool.self, forKey: .doterivanje) ?? false
        provajderDoterivanja = try kontejner.decodeIfPresent(String.self, forKey: .provajderDoterivanja)
            ?? ProvajderiDoterivanja.podrazumevani.id
        if ProvajderiDoterivanja.nadji(provajderDoterivanja) == nil {
            provajderDoterivanja = ProvajderiDoterivanja.podrazumevani.id
        }
        modeliDoterivanja = try kontejner.decodeIfPresent([String: String].self, forKey: .modeliDoterivanja)
            ?? [:]
        adresaCustomDoterivanja = try kontejner.decodeIfPresent(String.self, forKey: .adresaCustomDoterivanja)
            ?? ProvajderiDoterivanja.custom.adresa
    }
}
