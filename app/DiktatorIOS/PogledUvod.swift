import SwiftUI

/// Kratak uvod pri prvom pokretanju: model, tastatura, Full Access i sesija.
/// Cilj je da i recenzent i korisnik za minut vide ceo tok, jer bez modela i
/// tastature aplikacija izgleda kao da ništa ne radi.
struct PogledUvod: View {
    @EnvironmentObject var stanje: AppStanje
    @Environment(\.dismiss) private var dismiss

    /// Srećna strana se može izabrati samo u DEBUG buildu, da bi snimci za
    /// App Store mogli da prikažu svaki korak: -DiktatorUvodStrana 2.
    @State private var strana = PogledUvod.pocetnaStrana
    private let brojStrana = 4

    private static var pocetnaStrana: Int {
        #if DEBUG
        if let upis = UserDefaults.standard.string(forKey: "DiktatorUvodStrana"),
           let broj = Int(upis) {
            return min(max(broj, 0), 3)
        }
        #endif
        return 0
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Preskoči") {
                    zavrsi()
                }
                .font(.system(size: 15))
                .foregroundStyle(Dizajn.tekstSekundarni)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            TabView(selection: $strana) {
                prvaStrana.tag(0)
                stranaModela.tag(1)
                stranaTastature.tag(2)
                stranaSesije.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            HStack(spacing: 12) {
                if strana > 0 {
                    Button("Nazad") {
                        withAnimation { strana -= 1 }
                    }
                    .buttonStyle(StilDugmetaSvetli())
                }

                Spacer()

                Button(strana == brojStrana - 1 ? "Počni" : "Dalje") {
                    if strana == brojStrana - 1 {
                        zavrsi()
                    } else {
                        withAnimation { strana += 1 }
                    }
                }
                .buttonStyle(StilDugmeta())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Dizajn.pozadina.ignoresSafeArea())
    }

    // MARK: - Strane

    private var prvaStrana: some View {
        strana(
            simbol: "waveform",
            naslov: "Dobro došao u Diktator",
            tekst: "Diktiraj na srpskom ili engleskom, a tekst se sam ubaci u aplikaciju u kojoj pišeš. Snimak se obrađuje na uređaju i ne čuva se."
        ) {
            Label("Bez naloga i bez reklama.", systemImage: "checkmark.seal")
            Label("Sesija se obnavlja svakim diktatom.", systemImage: "clock")
        }
    }

    private var stranaModela: some View {
        strana(
            simbol: "arrow.down.circle",
            naslov: "1. Preuzmi model",
            tekst: "Model je fajl sa kojim Diktator pretvara govor u tekst. Preuzima se jednom i ostaje na uređaju."
        ) {
            if stanje.modelJePreuzet {
                Label("Model je preuzet.", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Dizajn.zelena)
            } else if stanje.modelSePreuzima {
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: stanje.napredakPreuzimanja ?? 0)
                    Text("Preuzimam…")
                        .font(.system(size: 13))
                        .foregroundStyle(Dizajn.tekstSekundarni)
                }
            } else {
                if let base = Modeli.nadji("ggml-base.bin") {
                    Button(Prevod.t("Preuzmi Base (~%@)", base.velicinaTekst)) {
                        stanje.preuzmiModel(base)
                    }
                    .buttonStyle(StilDugmeta())
                }
                if let large = Modeli.nadji("ggml-large-v3-q5_0.bin") {
                    Button(Prevod.t("Preuzmi Large v3 (~%@)", large.velicinaTekst)) {
                        stanje.preuzmiModel(large)
                    }
                    .buttonStyle(StilDugmetaSvetli())
                }
                Text("Base je dovoljan za prvi test; Large v3 daje najbolji srpski.")
                    .font(.system(size: 13))
                    .foregroundStyle(Dizajn.tekstTercijarni)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let napomena = stanje.napomenaMemorije {
                Text(napomena)
                    .font(.system(size: 13))
                    .foregroundStyle(Dizajn.narandzasta)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var stranaTastature: some View {
        strana(
            simbol: "keyboard",
            naslov: "2. Dodaj tastaturu",
            tekst: "Tastatura ubacuje prepis u polje u kome pišeš, u bilo kojoj aplikaciji."
        ) {
            korak(1, "Otvori iOS Podešavanja → Opšte → Tastatura → Tastature.")
            korak(2, "Tapni Dodaj novu tastaturu, pa Diktator.")
            korak(3, "Tapni Diktator i uključi Allow Full Access.")
            Text("Full Access tastatura koristi da pročita clipboard kada tapneš Nalepi i da preuzme gotov tekst iz Diktatora.")
                .font(.system(size: 13))
                .foregroundStyle(Dizajn.tekstTercijarni)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var stranaSesije: some View {
        strana(
            simbol: "mic.fill",
            naslov: "3. Uključi sesiju",
            tekst: "Sesija drži mikrofon u pripravnosti da bi tastatura mogla da diktira u bilo kojoj aplikaciji. Uključuje se ovde, dodirom."
        ) {
            if stanje.sesijaAktivna {
                Label("Sesija je uključena.", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Dizajn.zelena)
            } else {
                Button("Uključi sesiju") {
                    stanje.ukljuciSesiju()
                }
                .buttonStyle(StilDugmeta())
                .disabled(!stanje.modelJePreuzet)
                .opacity(stanje.modelJePreuzet ? 1 : 0.5)

                if !stanje.modelJePreuzet {
                    Text("Prvo preuzmi model na prethodnom koraku.")
                        .font(.system(size: 13))
                        .foregroundStyle(Dizajn.tekstTercijarni)
                }
            }

            #if APPSTORE
            Text("Kada sesija istekne, otvori Diktator i uključi je ponovo — tastatura sama ne otvara aplikaciju.")
                .font(.system(size: 13))
                .foregroundStyle(Dizajn.tekstTercijarni)
                .fixedSize(horizontal: false, vertical: true)
            #else
            Text("Ako sesija nije uključena, Diktiraj u tastaturi otvara Diktator i uključi je.")
                .font(.system(size: 13))
                .foregroundStyle(Dizajn.tekstTercijarni)
                .fixedSize(horizontal: false, vertical: true)
            #endif
        }
    }

    // MARK: - Delovi

    private func strana<Sadrzaj: View>(
        simbol: String,
        naslov: LocalizedStringKey,
        tekst: LocalizedStringKey,
        @ViewBuilder sadrzaj: @escaping () -> Sadrzaj
    ) -> some View {
        GeometryReader { geometrija in
            ScrollView {
                VStack(spacing: 16) {
                    IkonaUKrugu(simbol: simbol, boja: Dizajn.akcenat, velicina: 64)

                    Text(naslov)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Dizajn.tekst)
                        .multilineTextAlignment(.center)

                    Text(tekst)
                        .font(.system(size: 15))
                        .foregroundStyle(Dizajn.tekstSekundarni)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 12) {
                        sadrzaj()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Dizajn.kartica)
                    .clipShape(
                        RoundedRectangle(cornerRadius: Dizajn.radijusKartice, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Dizajn.radijusKartice, style: .continuous)
                            .stroke(Dizajn.ivica, lineWidth: 1)
                    )
                }
                .frame(maxWidth: 560)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometrija.size.height, alignment: .top)
            }
        }
    }

    private func korak(_ broj: Int, _ tekst: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(broj)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Dizajn.akcenat)
                .frame(width: 22, height: 22)
                .background(Dizajn.akcenatMeki)
                .clipShape(Circle())
            Text(tekst)
                .font(.system(size: 14))
                .foregroundStyle(Dizajn.tekst)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func zavrsi() {
        stanje.oznaciUvodVidjen()
        dismiss()
    }
}
