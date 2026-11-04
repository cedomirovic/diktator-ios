import SwiftUI
import UIKit

/// Vizuelni jezik preuzet sa desktop Diktatora: svetla pozadina, bele kartice
/// sa tankom ivicom, plavi akcenat i SF Pro tipografija. Boje su prilagođene
/// i tamnom režimu, da aplikacija ostane čitljiva noću.
enum Dizajn {
    // MARK: - Boje

    /// Plava iz dizajna (#2F7CF6).
    static let akcenat = dinamicka(svetla: 0x2F7CF6, tamna: 0x4C93FF)
    /// Svetla plava za krug iza ikone (#E9F1FD).
    static let akcenatMeki = dinamicka(svetla: 0xE9F1FD, tamna: 0x1B3355)
    static let pozadina = dinamicka(svetla: 0xF2F3F5, tamna: 0x0E0F11)
    static let kartica = dinamicka(svetla: 0xFFFFFF, tamna: 0x1C1D21)
    static let ivica = dinamicka(svetla: 0xE4E6EA, tamna: 0x2E3036)
    static let tekst = dinamicka(svetla: 0x14161A, tamna: 0xF4F5F7)
    static let tekstSekundarni = dinamicka(svetla: 0x6B7076, tamna: 0x9BA1A8)
    static let tekstTercijarni = dinamicka(svetla: 0x9AA0A6, tamna: 0x71767D)
    static let zelena = dinamicka(svetla: 0x1FA971, tamna: 0x35C98A)
    static let crvena = dinamicka(svetla: 0xE0484D, tamna: 0xF2686C)
    static let narandzasta = dinamicka(svetla: 0xE8971E, tamna: 0xF2AE45)

    // MARK: - Oblici

    static let radijusKartice: CGFloat = 18
    static let radijusReda: CGFloat = 12

    private static func dinamicka(svetla: UInt32, tamna: UInt32) -> Color {
        Color(uiColor: UIColor { zbir in
            UIColor(hex: zbir.userInterfaceStyle == .dark ? tamna : svetla)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - Kartice

extension View {
    /// Bela kartica sa tankom ivicom i blagom senkom, kao u desktop dizajnu.
    func kartica(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Dizajn.kartica)
            .clipShape(RoundedRectangle(cornerRadius: Dizajn.radijusKartice, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Dizajn.radijusKartice, style: .continuous)
                    .stroke(Dizajn.ivica, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 2)
    }
}

// MARK: - Tipografija

/// Veliki naslov ekrana sa sivim podnaslovom, kao „Istorija / Vaše prethodne
/// diktacije na jednom mestu.“ u dizajnu.
struct NaslovEkrana: View {
    let naslov: LocalizedStringKey
    var podnaslov: LocalizedStringKey?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(naslov)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Dizajn.tekst)

            if let podnaslov {
                Text(podnaslov)
                    .font(.system(size: 15))
                    .foregroundStyle(Dizajn.tekstSekundarni)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Naslov grupe unutar ekrana (npr. „Ponašanje aplikacije“).
struct NaslovSekcije: View {
    let naslov: LocalizedStringKey
    var podnaslov: LocalizedStringKey?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(naslov)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Dizajn.tekst)
            if let podnaslov {
                Text(podnaslov)
                    .font(.system(size: 13))
                    .foregroundStyle(Dizajn.tekstSekundarni)
            }
        }
    }
}

// MARK: - Ikone i oznake

/// Ikona u svetlom krugu, kao u karticama statistike.
struct IkonaUKrugu: View {
    let simbol: String
    var boja: Color = Dizajn.akcenat
    var velicina: CGFloat = 40

    var body: some View {
        Image(systemName: simbol)
            .font(.system(size: velicina * 0.44, weight: .semibold))
            .foregroundStyle(boja)
            .frame(width: velicina, height: velicina)
            .background(boja.opacity(0.12), in: Circle())
    }
}

/// Mala siva oznaka, npr. trajanje diktata „01:32“.
struct Oznaka: View {
    let tekst: String

    var body: some View {
        Text(tekst)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Dizajn.tekstSekundarni)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Dizajn.pozadina, in: Capsule())
    }
}

/// Red sa natpisom levo i vrednošću desno (detalji statistike).
struct RedPodatka: View {
    let naslov: LocalizedStringKey
    let vrednost: String

    var body: some View {
        HStack {
            Text(naslov)
                .font(.system(size: 15))
                .foregroundStyle(Dizajn.tekstSekundarni)
            Spacer()
            Text(vrednost)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Dizajn.tekst)
        }
    }
}

// MARK: - Dugmad

/// Plavo (ili crveno) dugme pune širine, zaobljeno kao u dizajnu.
struct StilDugmeta: ButtonStyle {
    var boja: Color = Dizajn.akcenat
    var pun = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .foregroundStyle(pun ? Color.white : boja)
            .background(pun ? boja : boja.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: Dizajn.radijusReda, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}

/// Sekundarno dugme: svetla pozadina i obojeni tekst.
struct StilDugmetaSvetli: ButtonStyle {
    var boja: Color = Dizajn.akcenat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(boja)
            .background(boja.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}
