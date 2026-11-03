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
            return "Tapni mikrofon i pričaj. Tekst se posle diktiranja sam ubaci u aplikaciju u kojoj kucaš."
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

/// Odnos brzine i tačnosti. Turbo model ima 4 dekoderska sloja umesto 32,
/// pa je nekoliko puta brži, ali za srpski ume da pogreši imena i završetke.
enum RezimBrzine: String, CaseIterable, Identifiable {
    case brzo
    case tacno
    case oblak

    var id: String { rawValue }

    var naziv: String {
        switch self {
        case .brzo: return "Brzo — Turbo, na uređaju"
        case .tacno: return "Najtačnije — Large v3"
        case .oblak: return "Najbrže — Groq (oblak)"
        }
    }

    var opis: String {
        switch self {
        case .brzo:
            return "Turbo model, kraći audio kontekst i najbrža obrada. Nekoliko puta brže, uz moguće greške u imenima i završecima."
        case .tacno:
            return "Isto kao desktop Diktator: Large v3, pun audio kontekst i pretraga snopom. Najtačniji srpski, ali sporiji."
        case .oblak:
            return "Groq prepiše kratak snimak za oko sekund, ali zvuk tada napušta uređaj i šalje se servisu Groq (SAD). Uključuje se samo uz potvrdu, a lokalni prepis je uvek dostupan."
        }
    }

    static func iz(_ id: String) -> RezimBrzine {
        RezimBrzine(rawValue: id) ?? .brzo
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

/// Koliko dugo pozadinska sesija drži mikrofon u pripravnosti. Kada sesija
/// nema istek, tastatura diktira u svakoj aplikaciji i Diktator se ne otvara
/// dok korisnik sam ne završi sesiju.
enum TrajanjeSesije: String, CaseIterable, Identifiable {
    case bezIsteka = "bez"
    case sat = "sat"
    case petnaestMinuta = "15"

    var id: String { rawValue }

    var naziv: String {
        switch self {
        case .bezIsteka: return "Bez isteka"
        case .sat: return "1 sat"
        case .petnaestMinuta: return "15 minuta"
        }
    }

    /// `nil` znači da sesija nema istek i gasi se samo na zahtev korisnika.
    var sekundi: Int? {
        switch self {
        case .bezIsteka: return nil
        case .sat: return 3600
        case .petnaestMinuta: return 900
        }
    }

    var opis: String {
        switch self {
        case .bezIsteka:
            return "Tastatura diktira u bilo kojoj aplikaciji i Diktator se ne otvara. Mikrofon ostaje u pripravnosti dok god je sesija uključena, pa baterija troši malo više. Preporučeno."
        case .sat:
            return "Sesija traje jedan sat i svaki diktat je produžava za novih sat vremena."
        case .petnaestMinuta:
            #if APPSTORE
            return "Sesija traje 15 minuta i svaki diktat je produžava. Posle isteka otvori Diktator i uključi je ponovo."
            #else
            return "Sesija traje 15 minuta i svaki diktat je produžava. Posle isteka tastatura ponovo otvara Diktator."
            #endif
        }
    }

    /// Opcije koje se nude u Podešavanjima. App Store verzija nema sesiju bez
    /// isteka — tamo mikrofon u pripravnosti sme da traje najviše 15 minuta.
    static var dostupna: [TrajanjeSesije] {
        #if APPSTORE
        return [.petnaestMinuta]
        #else
        return allCases
        #endif
    }

    static var podrazumevano: TrajanjeSesije {
        #if APPSTORE
        return .petnaestMinuta
        #else
        return .bezIsteka
        #endif
    }

    static func iz(_ id: String) -> TrajanjeSesije {
        let izabrano = TrajanjeSesije(rawValue: id) ?? podrazumevano
        #if APPSTORE
        // I ako je iz starije verzije ostalo „bez isteka“, App Store build ga
        // svodi na 15 minuta.
        return izabrano == .bezIsteka ? .petnaestMinuta : izabrano
        #else
        return izabrano
        #endif
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
    var rezimPrepisa = RezimPrepisa.kvalitet.rawValue
    var oslobadjanjeModela = OslobadjanjeModela.pet.rawValue
    var cuvajIstoriju = true
    /// Koliko dugo pozadinska sesija radi. U App Store verziji to je uvek
    /// 15 minuta, a u ličnoj verziji podrazumevano bez isteka.
    var trajanjeSesije = TrajanjeSesije.podrazumevano.rawValue
    /// Kada je Diktator otvoren iz tastature samo zato što sesija nije bila
    /// uključena, posle prepisa se sam zatvori da bi iOS vratio korisnika u
    /// aplikaciju iz koje je došao.
    var vratiSePosleDiktata = true
    var proveravajAzuriranja = true
    var doterivanje = false
    var provajderDoterivanja = ProvajderiDoterivanja.podrazumevani.id
    var modeliDoterivanja: [String: String] = [:]
    var adresaCustomDoterivanja = ProvajderiDoterivanja.custom.adresa
    var prepisOblak = false
    var modelOblaka = PrepisOblak.podrazumevaniModel
    var rezimBrzine = RezimBrzine.tacno.rawValue

    init() {}

    private enum CodingKeys: String, CodingKey {
        case jezik
        case model
        case rezimPrepisa
        case oslobadjanjeModela
        case cuvajIstoriju
        case trajanjeSesije
        case vratiSePosleDiktata
        case proveravajAzuriranja
        case doterivanje
        case provajderDoterivanja
        case modeliDoterivanja
        case adresaCustomDoterivanja
        case prepisOblak
        case modelOblaka
        case rezimBrzine
    }

    init(from decoder: Decoder) throws {
        let kontejner = try decoder.container(keyedBy: CodingKeys.self)
        jezik = try kontejner.decodeIfPresent(String.self, forKey: .jezik)
            ?? Podesavanja.podrazumevaniJezik
        model = try kontejner.decodeIfPresent(String.self, forKey: .model)
            ?? Modeli.nadjiPostojeci()?.id
            ?? Modeli.podrazumevani.id
        rezimPrepisa = try kontejner.decodeIfPresent(String.self, forKey: .rezimPrepisa)
            ?? RezimPrepisa.kvalitet.rawValue
        if RezimPrepisa(rawValue: rezimPrepisa) == nil {
            rezimPrepisa = RezimPrepisa.kvalitet.rawValue
        }
        oslobadjanjeModela = try kontejner.decodeIfPresent(String.self, forKey: .oslobadjanjeModela)
            ?? OslobadjanjeModela.pet.rawValue
        if OslobadjanjeModela(rawValue: oslobadjanjeModela) == nil {
            oslobadjanjeModela = OslobadjanjeModela.pet.rawValue
        }
        cuvajIstoriju = try kontejner.decodeIfPresent(Bool.self, forKey: .cuvajIstoriju) ?? true
        trajanjeSesije = TrajanjeSesije.iz(
            try kontejner.decodeIfPresent(String.self, forKey: .trajanjeSesije)
                ?? TrajanjeSesije.podrazumevano.rawValue
        ).rawValue
        vratiSePosleDiktata = try kontejner.decodeIfPresent(Bool.self, forKey: .vratiSePosleDiktata) ?? true
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
        prepisOblak = try kontejner.decodeIfPresent(Bool.self, forKey: .prepisOblak) ?? false
        modelOblaka = try kontejner.decodeIfPresent(String.self, forKey: .modelOblaka)
            ?? PrepisOblak.podrazumevaniModel
        rezimBrzine = try kontejner.decodeIfPresent(String.self, forKey: .rezimBrzine)
            ?? RezimBrzine.tacno.rawValue
        if RezimBrzine(rawValue: rezimBrzine) == nil {
            rezimBrzine = RezimBrzine.tacno.rawValue
        }
    }
}
