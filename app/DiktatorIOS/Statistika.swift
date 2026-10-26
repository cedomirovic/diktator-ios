import Foundation

/// Dnevni zbir za grafikon i niz dana. Ne čuvamo tekst, samo brojeve.
struct DnevnaStatistika: Codable, Equatable {
    var reci: Int = 0
    var znakovi: Int = 0
    var snimci: Int = 0
    var trajanje: Double = 0
}

struct DnevniPodatak: Identifiable {
    let id: String
    let datum: Date
    let oznaka: String
    let reci: Int
}

struct JezikStatistika: Identifiable {
    let id: String
    let naziv: String
    let broj: Int
}

/// Ukupna statistika diktata. Čuva se odvojeno od istorije, pa ostaje i kada
/// se istorija skrati na 200 zapisa ili obriše.
struct Statistika: Codable, Equatable {
    var ukupnoReci: Int = 0
    var ukupnoZnakova: Int = 0
    var ukupnoSnimaka: Int = 0
    var ukupnoTrajanje: Double = 0
    var dana: [String: DnevnaStatistika] = [:]
    var jezici: [String: Int] = [:]
    var prviDatum: Date?
    var zadnjiDatum: Date?

    /// Prosečna brzina kucanja na telefonu, za procenu uštede vremena.
    static let brzinaKucanja = 40.0

    init() {}

    private enum CodingKeys: String, CodingKey {
        case ukupnoReci
        case ukupnoZnakova
        case ukupnoSnimaka
        case ukupnoTrajanje
        case dana
        case jezici
        case prviDatum
        case zadnjiDatum
    }

    init(from decoder: Decoder) throws {
        let k = try decoder.container(keyedBy: CodingKeys.self)
        ukupnoReci = try k.decodeIfPresent(Int.self, forKey: .ukupnoReci) ?? 0
        ukupnoZnakova = try k.decodeIfPresent(Int.self, forKey: .ukupnoZnakova) ?? 0
        ukupnoSnimaka = try k.decodeIfPresent(Int.self, forKey: .ukupnoSnimaka) ?? 0
        ukupnoTrajanje = try k.decodeIfPresent(Double.self, forKey: .ukupnoTrajanje) ?? 0
        dana = try k.decodeIfPresent([String: DnevnaStatistika].self, forKey: .dana) ?? [:]
        jezici = try k.decodeIfPresent([String: Int].self, forKey: .jezici) ?? [:]
        prviDatum = try k.decodeIfPresent(Date.self, forKey: .prviDatum)
        zadnjiDatum = try k.decodeIfPresent(Date.self, forKey: .zadnjiDatum)
    }

    mutating func dodaj(
        tekst: String,
        trajanje: Double,
        jezik: String,
        datum: Date = Date()
    ) {
        let reci = Tekst.brojReci(tekst)
        guard reci > 0 else { return }

        let sekunde = max(0, trajanje)
        ukupnoReci += reci
        ukupnoZnakova += tekst.count
        ukupnoSnimaka += 1
        ukupnoTrajanje += sekunde
        jezici[jezik, default: 0] += 1

        let kljuc = Statistika.kljuc(datum)
        var dan = dana[kljuc] ?? DnevnaStatistika()
        dan.reci += reci
        dan.znakovi += tekst.count
        dan.snimci += 1
        dan.trajanje += sekunde
        dana[kljuc] = dan

        if prviDatum == nil || datum < prviDatum! {
            prviDatum = datum
        }
        if zadnjiDatum == nil || datum > zadnjiDatum! {
            zadnjiDatum = datum
        }
    }

    var prosecnoReciUMinuti: Double {
        guard ukupnoTrajanje > 0 else { return 0 }
        return Double(ukupnoReci) / (ukupnoTrajanje / 60)
    }

    var prosecanDiktatSekundi: Double {
        guard ukupnoSnimaka > 0 else { return 0 }
        return ukupnoTrajanje / Double(ukupnoSnimaka)
    }

    /// Koliko je vremena ušteđeno u odnosu na kucanje istog teksta.
    var ustedaSekundi: Double {
        let kucanje = Double(ukupnoReci) / Statistika.brzinaKucanja * 60
        return max(0, kucanje - ukupnoTrajanje)
    }

    var ustedaTekst: String {
        Statistika.vreme(ustedaSekundi)
    }

    var vremeGovoraTekst: String {
        Statistika.vreme(ukupnoTrajanje)
    }

    var danasReci: Int {
        dana[Statistika.kljuc(Date())]?.reci ?? 0
    }

    var nedeljaReci: Int {
        Statistika.zbir(dana: dana, danaUnazad: 7)
    }

    var mesecReci: Int {
        Statistika.zbir(dana: dana, danaUnazad: 30)
    }

    /// Niz uzastopnih dana sa bar jednim diktatom. Ako danas još nema
    /// diktata, niz se računa od juče, da ne nestane pre prvog diktata.
    var nizDana: Int {
        let kalendar = Calendar.current
        var dan = kalendar.startOfDay(for: Date())
        if dana[Statistika.kljuc(dan)] == nil {
            guard let juce = kalendar.date(byAdding: .day, value: -1, to: dan) else {
                return 0
            }
            dan = juce
        }

        var niz = 0
        while let dnevni = dana[Statistika.kljuc(dan)], dnevni.reci > 0 {
            niz += 1
            guard let prethodni = kalendar.date(byAdding: .day, value: -1, to: dan) else {
                break
            }
            dan = prethodni
        }
        return niz
    }

    var najduziNiz: Int {
        let kljucevi = dana.keys.sorted()
        guard !kljucevi.isEmpty else { return 0 }

        let kalendar = Calendar.current
        var najduzi = 1
        var trenutni = 1
        for indeks in 1..<kljucevi.count {
            guard let prethodni = Statistika.datum(iz: kljucevi[indeks - 1]),
                  let sadasnji = Statistika.datum(iz: kljucevi[indeks]),
                  let razlika = kalendar.dateComponents(
                    [.day],
                    from: prethodni,
                    to: sadasnji
                  ).day else {
                trenutni = 1
                continue
            }
            if razlika == 1 {
                trenutni += 1
                najduzi = max(najduzi, trenutni)
            } else {
                trenutni = 1
            }
        }
        return najduzi
    }

    var poslednjih7Dana: [DnevniPodatak] {
        let kalendar = Calendar.current
        let danas = kalendar.startOfDay(for: Date())
        let formatter = Statistika.formatterOznake

        return (0..<7).reversed().compactMap { pomak in
            guard let datum = kalendar.date(byAdding: .day, value: -pomak, to: danas) else {
                return nil
            }
            let kljuc = Statistika.kljuc(datum)
            return DnevniPodatak(
                id: kljuc,
                datum: datum,
                oznaka: formatter.string(from: datum),
                reci: dana[kljuc]?.reci ?? 0
            )
        }
    }

    var jeziciSortirano: [JezikStatistika] {
        let nazivi = [
            "sr": "Srpski",
            "en": "Engleski",
            "auto": "Automatski"
        ]
        return jezici
            .map { kljuc, broj in
                JezikStatistika(
                    id: kljuc,
                    naziv: nazivi[kljuc] ?? kljuc.uppercased(),
                    broj: broj
                )
            }
            .sorted { $0.broj > $1.broj }
    }

    static func iz(_ zapisi: [Zapis]) -> Statistika {
        var statistika = Statistika()
        for zapis in zapisi {
            statistika.dodaj(
                tekst: zapis.tekst,
                trajanje: zapis.trajanje,
                jezik: zapis.jezik,
                datum: zapis.datum
            )
        }
        return statistika
    }

    static func vreme(_ sekunde: Double) -> String {
        let ukupno = max(0, Int(sekunde.rounded()))
        if ukupno < 60 {
            return "\(ukupno) s"
        }
        if ukupno < 3600 {
            return "\(ukupno / 60) min"
        }
        let sati = ukupno / 3600
        let minuti = (ukupno % 3600) / 60
        return minuti == 0 ? "\(sati) h" : "\(sati) h \(minuti) min"
    }

    static func kljuc(_ datum: Date) -> String {
        formatterKljuca.string(from: datum)
    }

    static func datum(iz kljuc: String) -> Date? {
        formatterKljuca.date(from: kljuc)
    }

    private static func zbir(
        dana: [String: DnevnaStatistika],
        danaUnazad: Int
    ) -> Int {
        let kalendar = Calendar.current
        let danas = kalendar.startOfDay(for: Date())
        return (0..<danaUnazad).reduce(0) { rezultat, pomak in
            guard let datum = kalendar.date(byAdding: .day, value: -pomak, to: danas) else {
                return rezultat
            }
            return rezultat + (dana[kljuc(datum)]?.reci ?? 0)
        }
    }

    private static let formatterKljuca: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let formatterOznake: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "sr_Latn")
        f.timeZone = .current
        f.dateFormat = "EEE"
        return f
    }()
}

enum StatistikaSkladiste {
    static func ucitaj() -> Statistika {
        guard let podaci = try? Data(contentsOf: Putanje.statistika),
              let statistika = try? JSONDecoder().decode(Statistika.self, from: podaci) else {
            return Statistika()
        }
        return statistika
    }

    static func sacuvaj(_ statistika: Statistika) {
        guard let podaci = try? JSONEncoder().encode(statistika) else { return }
        try? podaci.write(to: Putanje.statistika, options: .atomic)
        Putanje.zastitiFajl(Putanje.statistika)
    }
}
