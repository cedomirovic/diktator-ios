import Combine
import Foundation
import UserNotifications

/// Zbir diktata za jednu nedelju (ponedeljak–nedelja). Ne pamti tekst, samo
/// brojeve, pa se koristi i za karticu u statistici i za obaveštenje.
struct NedeljniPregled: Equatable {
    let pocetak: Date
    let kraj: Date
    let reci: Int
    let snimci: Int
    let trajanje: Double
    let aktivniDani: Int

    var prazan: Bool { reci == 0 }

    /// Vreme koje bi trebalo za kucanje istog teksta, umanjeno za vreme govora.
    var ustedaSekundi: Double {
        let kucanje = Double(reci) / Statistika.brzinaKucanja * 60
        return max(0, kucanje - trajanje)
    }

    var ustedaTekst: String { Statistika.vreme(ustedaSekundi) }

    var prosecnoReciUMinuti: Double {
        guard trajanje > 0 else { return 0 }
        return Double(reci) / (trajanje / 60)
    }

    /// Podnaslov obaveštenja, npr. „10. 11. 2026. – 16. 11. 2026.“
    var rasponTekst: String {
        let formatter = DateIntervalFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: pocetak, to: kraj)
    }
}

extension Statistika {
    /// Ponedeljak nedelje koja sadrži dati datum. `Calendar.weekday` broji od
    /// nedelje (1), pa se ponedeljak dobija pomerajem od šest dana unazad.
    static func pocetakNedelje(_ datum: Date, kalendar: Calendar = .current) -> Date {
        let dan = kalendar.startOfDay(for: datum)
        let danUNedelji = kalendar.component(.weekday, from: dan)
        let pomak = (danUNedelji + 5) % 7
        return kalendar.date(byAdding: .day, value: -pomak, to: dan) ?? dan
    }

    /// Zbir za opseg dana, uključujući oba kraja.
    func pregled(
        od pocetak: Date,
        do kraj: Date,
        kalendar: Calendar = .current
    ) -> NedeljniPregled {
        var reci = 0
        var snimci = 0
        var trajanje = 0.0
        var aktivni = 0
        var dan = kalendar.startOfDay(for: pocetak)
        let krajDana = kalendar.startOfDay(for: kraj)

        while dan <= krajDana {
            if let dnevni = dana[Statistika.kljuc(dan)] {
                reci += dnevni.reci
                snimci += dnevni.snimci
                trajanje += dnevni.trajanje
                if dnevni.reci > 0 {
                    aktivni += 1
                }
            }
            guard let sledeci = kalendar.date(byAdding: .day, value: 1, to: dan) else {
                break
            }
            dan = sledeci
        }

        return NedeljniPregled(
            pocetak: kalendar.startOfDay(for: pocetak),
            kraj: krajDana,
            reci: reci,
            snimci: snimci,
            trajanje: trajanje,
            aktivniDani: aktivni
        )
    }

    /// Poslednja završena nedelja (ponedeljak–nedelja).
    func prethodnaNedelja(
        danas: Date = Date(),
        kalendar: Calendar = .current
    ) -> NedeljniPregled {
        let ovajPonedeljak = Statistika.pocetakNedelje(danas, kalendar: kalendar)
        let prosliPonedeljak = kalendar.date(byAdding: .day, value: -7, to: ovajPonedeljak)
            ?? ovajPonedeljak
        let kraj = kalendar.date(byAdding: .day, value: 6, to: prosliPonedeljak)
            ?? prosliPonedeljak
        return pregled(od: prosliPonedeljak, do: kraj, kalendar: kalendar)
    }

    /// Nedelja o kojoj govori sledeće obaveštenje: sedam dana pre sledećeg
    /// okidača. Ako za tu nedelju još nema podataka (npr. odmah posle
    /// slanja), koristi se poslednja završena nedelja.
    func nedeljaZaObavestenje(
        dan: Int,
        minuta: Int,
        sada: Date = Date(),
        kalendar: Calendar = .current
    ) -> NedeljniPregled {
        guard let okidac = Statistika.sledeciOkidac(
            dan: dan,
            minuta: minuta,
            sada: sada,
            kalendar: kalendar
        ) else {
            return prethodnaNedelja(danas: sada, kalendar: kalendar)
        }
        let kraj = kalendar.date(byAdding: .day, value: -1, to: kalendar.startOfDay(for: okidac))
            ?? okidac
        let pocetak = kalendar.date(byAdding: .day, value: -6, to: kraj) ?? kraj
        let nedelja = pregled(od: pocetak, do: kraj, kalendar: kalendar)
        return nedelja.prazan ? prethodnaNedelja(danas: sada, kalendar: kalendar) : nedelja
    }

    /// Sledeći datum koji odgovara danu u nedelji i vremenu, ili `nil` ako
    /// kalendar ne može da ga izračuna.
    static func sledeciOkidac(
        dan: Int,
        minuta: Int,
        sada: Date = Date(),
        kalendar: Calendar = .current
    ) -> Date? {
        var komponente = DateComponents()
        komponente.weekday = dan
        komponente.hour = minuta / 60
        komponente.minute = minuta % 60
        return kalendar.nextDate(
            after: sada,
            matching: komponente,
            matchingPolicy: .nextTime
        )
    }
}

/// Zakazuje lokalno obaveštenje sa nedeljnim pregledom. Sadržaj se osveži pri
/// svakom pokretanju i posle svakog diktata, pa brojevi prate stanje.
@MainActor
enum NedeljniPodsetnik {
    static let identifikator = "diktator.nedeljni.pregled"
    static let kategorija = "diktator.pregled"

    /// Redosled u izboru: ponedeljak prvi, kao što nedelja i počinje.
    static let dostupniDani: [Int] = [2, 3, 4, 5, 6, 7, 1]

    static func nazivDana(_ dan: Int) -> String {
        switch dan {
        case 1: return Prevod.t("Nedelja")
        case 2: return Prevod.t("Ponedeljak")
        case 3: return Prevod.t("Utorak")
        case 4: return Prevod.t("Sreda")
        case 5: return Prevod.t("Četvrtak")
        case 6: return Prevod.t("Petak")
        default: return Prevod.t("Subota")
        }
    }

    static func vremeTekst(_ minuta: Int) -> String {
        String(format: "%02d:%02d", minuta / 60, minuta % 60)
    }

    static func sadrzaj(_ pregled: NedeljniPregled) -> UNMutableNotificationContent {
        let sadrzaj = UNMutableNotificationContent()
        sadrzaj.title = Prevod.t("Tvoja nedelja u Diktatoru")
        if pregled.prazan {
            sadrzaj.body = Prevod.t(
                "Prošle nedelje nije bilo diktata. Otvori Diktator i nastavi niz."
            )
        } else {
            sadrzaj.subtitle = pregled.rasponTekst
            sadrzaj.body = Prevod.t(
                "%@ reči i %@ ušteđenog vremena prošle nedelje.",
                pregled.reci.formatted(),
                pregled.ustedaTekst
            )
        }
        sadrzaj.sound = .default
        sadrzaj.categoryIdentifier = kategorija
        sadrzaj.userInfo = ["pregled": "1"]
        return sadrzaj
    }

    /// Postavlja ponavljajuće nedeljno obaveštenje. Ako dozvola nije data,
    /// uklanja postojeći zahtev da ne bi stizalo obaveštenje koje korisnik
    /// nije hteo.
    static func zakazi(statistika: Statistika, dan: Int, minuta: Int) async {
        let centar = UNUserNotificationCenter.current()
        let postavke = await centar.notificationSettings()
        let pregled = statistika.nedeljaZaObavestenje(dan: dan, minuta: minuta)
        #if DEBUG
        let okidacDatum = Statistika.sledeciOkidac(dan: dan, minuta: minuta)
        Dnevnik.pisi(
            "Nedeljni pregled: dan=\(dan) vreme=\(vremeTekst(minuta)) "
                + "okidac=\(okidacDatum.map { "\($0)" } ?? "—") "
                + "nedelja=\(pregled.rasponTekst) reci=\(pregled.reci) "
                + "dozvola=\(postavke.authorizationStatus.rawValue)"
        )
        #endif
        guard Azuriranja.jeDozvoljeno(postavke.authorizationStatus) else {
            centar.removePendingNotificationRequests(withIdentifiers: [identifikator])
            return
        }

        var komponente = DateComponents()
        komponente.weekday = dan
        komponente.hour = minuta / 60
        komponente.minute = minuta % 60
        let okidac = UNCalendarNotificationTrigger(
            dateMatching: komponente,
            repeats: true
        )
        let zahtev = UNNotificationRequest(
            identifier: identifikator,
            content: sadrzaj(pregled),
            trigger: okidac
        )
        try? await centar.add(zahtev)
    }

    static func otkazi() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifikator])
    }

    /// Odmah šalje primer pregleda. Ako još nema nijedne završene nedelje,
    /// prikazuje se primer sa izmišljenim brojevima, da se vidi izgled.
    static func posaljiTestni(
        statistika: Statistika
    ) async -> Azuriranja.RezultatTestaObavestenja {
        let centar = UNUserNotificationCenter.current()
        var postavke = await centar.notificationSettings()
        if postavke.authorizationStatus == .notDetermined {
            _ = try? await centar.requestAuthorization(options: [.alert, .sound])
            postavke = await centar.notificationSettings()
        }
        guard Azuriranja.jeDozvoljeno(postavke.authorizationStatus) else {
            return .odbijeno
        }

        let pregled = statistika.prethodnaNedelja()
        let sadrzajObavestenja: UNMutableNotificationContent
        if pregled.prazan {
            let primer = UNMutableNotificationContent()
            primer.title = Prevod.t("Tvoja nedelja u Diktatoru")
            primer.body = Prevod.t(
                "Primer: 1.240 reči i 38 min ušteđenog vremena. Tvoji brojevi stižu posle prve nedelje diktata."
            )
            primer.sound = .default
            primer.categoryIdentifier = kategorija
            primer.userInfo = ["pregled": "1"]
            sadrzajObavestenja = primer
        } else {
            sadrzajObavestenja = sadrzaj(pregled)
        }

        let zahtev = UNNotificationRequest(
            identifier: "diktator.nedeljni.test.\(UUID().uuidString)",
            content: sadrzajObavestenja,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        )
        do {
            try await centar.add(zahtev)
            return .poslato
        } catch {
            return .greska
        }
    }
}

/// Kada korisnik otvori obaveštenje o nedeljnom pregledu, aplikacija treba da
/// prikaže statistiku. `AppDelegate` ne vidi `AppStanje`, pa zahtev ide kroz
/// ovaj mali deljeni objekat.
@MainActor
final class NavigacijaZahteva: ObservableObject {
    static let deljena = NavigacijaZahteva()

    @Published var otvoriStatistiku = false
}
