import SwiftUI
import Foundation

struct PogledDiktat: View {
    @EnvironmentObject var stanje: AppStanje
    @Environment(\.scenePhase) private var fazaEkrana
    @State private var prikaziPodesavanja = false
    @State private var predlogRecnika: PredlogRecnika?
    /// Uvod se prikazuje pri prvom pokretanju, jer bez modela i tastature
    /// aplikacija deluje kao da ne radi.
    @State private var prikaziUvod = false

    private var jeGreska: Bool {
        if case .greska = stanje.stanje { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    zaglavlje

                    if stanje.prikaziPovratak {
                        TrakaPovratka(
                            naslov: Prevod.t("Vrati se u svoju aplikaciju"),
                            opis: stanje.povratakOpis
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    hero

                    sesijaKartica

                    statistikaKartica

                    azuriranjeKartica

                    if !stanje.modelJePreuzet {
                        modelKartica
                    } else if stanje.podesavanja.model == "ggml-large-v3-turbo-q5_0.bin" {
                        savetKartica
                    }

                    if stanje.podesavanja.jezik == "auto" {
                        napomena
                    }

                    poslednjiTekstKartica

                    if let poruka = stanje.poruka {
                        Text(poruka)
                            .font(.system(size: 13))
                            .foregroundStyle(Dizajn.tekstSekundarni)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }

                    kakoRadiKartica
                }
                .frame(maxWidth: 640)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity)
            }
            .background(Dizajn.pozadina)
            .toolbar(.hidden, for: .navigationBar)
            .animation(.easeInOut(duration: 0.25), value: stanje.prikaziPovratak)
            // Kada Diktator ode u pozadinu, korisnik se već vratio u svoju
            // aplikaciju, pa traka više nije aktuelna.
            .onChange(of: fazaEkrana) { _, nova in
                if nova == .background {
                    stanje.ocistiPovratak()
                }
            }
            .navigationDestination(isPresented: $prikaziPodesavanja) {
                PogledPodesavanja()
            }
            .sheet(item: $predlogRecnika) { predlog in
                PogledDodajRecnik(tekst: predlog.tekst)
                    .environmentObject(stanje)
            }
            .sheet(isPresented: $prikaziUvod) {
                PogledUvod()
                    .environmentObject(stanje)
            }
            .onAppear {
                // Snimci za App Store (i skripta uzmi-snimke.sh) pale ovu
                // zastavicu da uvod ne bi ušao u kadar. Radi i u AppStore
                // buildu, koji nema DEBUG uslov.
                if UserDefaults.standard.bool(forKey: "DiktatorBezUvoda") {
                    stanje.oznaciUvodVidjen()
                }
                if !stanje.podesavanja.uvodVidjen {
                    prikaziUvod = true
                } else {
                    #if DEBUG
                    // Za snimke: -DiktatorUvod 1 prikaže uvod i posle prvog
                    // pokretanja, bez brisanja podešavanja.
                    if UserDefaults.standard.bool(forKey: "DiktatorUvod") {
                        prikaziUvod = true
                    }
                    #endif
                }
            }
        }
    }

    private var zaglavlje: some View {
        HStack(alignment: .top, spacing: 12) {
            NaslovEkrana(
                naslov: "Diktator",
                podnaslov: stanje.koristiServiseUOblaku
                    ? "Glas pretvara u tekst. Lokalno, uz opcione servise koje sam uključiš."
                    : "Glas pretvara u tekst — sve ostaje na uređaju."
            )

            Button {
                prikaziPodesavanja = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Dizajn.tekstSekundarni)
                    .frame(width: 40, height: 40)
                    .background(Dizajn.kartica, in: Circle())
                    .overlay(Circle().stroke(Dizajn.ivica, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Podešavanja")
        }
    }

    // MARK: - Mikrofon

    private var hero: some View {
        VStack(spacing: 12) {
            Text(stanje.stanje.naslov)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(jeGreska ? Dizajn.crvena : Dizajn.tekst)

            Text(stanje.stanje.detalj)
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .foregroundStyle(jeGreska ? Dizajn.crvena : Dizajn.tekstSekundarni)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                if stanje.stanje.jeSnimanje {
                    stanje.zaustaviSnimanje()
                } else {
                    stanje.pocniSnimanje()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(stanje.stanje.jeSnimanje ? Dizajn.crvena : Dizajn.akcenat)
                        .frame(width: 112, height: 112)
                        .shadow(
                            color: (stanje.stanje.jeSnimanje ? Dizajn.crvena : Dizajn.akcenat)
                                .opacity(0.28),
                            radius: 18,
                            y: 8
                        )
                    Image(systemName: stanje.stanje.jeSnimanje ? "stop.fill" : "mic.fill")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .disabled(stanje.stanje.jeZauzet)
            .padding(.top, 4)

            if stanje.stanje.jeSnimanje {
                ProgressView(value: Double(stanje.nivo))
                    .tint(Dizajn.crvena)
                    .padding(.horizontal, 28)
            } else if stanje.stanje.jeZauzet {
                ProgressView()
                    .tint(Dizajn.akcenat)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .kartica(padding: 20)
    }

    // MARK: - Sesija

    private var sesijaKartica: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                IkonaUKrugu(simbol: "waveform", boja: Dizajn.akcenat)
                Text("Sesija diktata")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                oznakaStanja(stanje.sesijaAktivna)
            }

            if stanje.sesijaAktivna {
                if stanje.sesijaBezIsteka {
                    Text("Tastatura sada može da snima u pozadini, bez otvaranja Diktatora. Sesija nema istek i traje dok je ne završiš.")
                        .font(.system(size: 14))
                        .foregroundStyle(Dizajn.tekstSekundarni)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Tastatura sada može da snima u pozadini, bez otvaranja Diktatora. Preostalo: \(stanje.sesijaPreostalo / 60):\(String(format: "%02d", stanje.sesijaPreostalo % 60))")
                        .font(.system(size: 14))
                        .foregroundStyle(Dizajn.tekstSekundarni)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Crveno i punom širinom — jasno se vidi da sesiju treba
                // ugasiti kada se ne diktira.
                Button {
                    stanje.zavrsiSesiju()
                } label: {
                    Label("Završi sesiju", systemImage: "stop.circle.fill")
                }
                .buttonStyle(StilDugmeta(boja: Dizajn.crvena))
                .accessibilityHint("Gasi sesiju diktata i oslobađa mikrofon.")
            } else {
                #if APPSTORE
                Text("Uključi sesiju da mikrofon u tastaturi snima dok je otvorena bilo koja aplikacija. Ako sesija nije uključena, Diktiraj u tastaturi će te zamoliti da otvoriš Diktator i uključiš je.")
                    .font(.system(size: 14))
                    .foregroundStyle(Dizajn.tekstSekundarni)
                    .fixedSize(horizontal: false, vertical: true)
                #else
                Text("Uključi sesiju da mikrofon u tastaturi snima dok je otvorena bilo koja aplikacija. Ako sesija nije uključena ili je aplikacija ugašena, tastatura sama otvara Diktator i uključi je.")
                    .font(.system(size: 14))
                    .foregroundStyle(Dizajn.tekstSekundarni)
                    .fixedSize(horizontal: false, vertical: true)
                #endif

                Button("Uključi sesiju") {
                    stanje.ukljuciSesiju()
                }
                .buttonStyle(StilDugmeta())
                .disabled(!stanje.modelJePreuzet || stanje.stanje.jeZauzet)
                .opacity(stanje.modelJePreuzet && !stanje.stanje.jeZauzet ? 1 : 0.5)
            }

            Text(opisTrajanjaSesije)
                .font(.system(size: 12))
                .foregroundStyle(Dizajn.tekstTercijarni)
                .fixedSize(horizontal: false, vertical: true)
        }
        .kartica()
    }

    /// Kratak opis ispod kartice sesije, prilagođen izabranom trajanju.
    private var opisTrajanjaSesije: String {
        switch TrajanjeSesije.iz(stanje.podesavanja.trajanjeSesije) {
        case .bezIsteka:
            return Prevod.t("Sesija bez isteka drži mikrofon u pripravnosti dok je ne završiš. Kada je završiš, tastatura ponovo otvara Diktator.")
        case .sat:
            return Prevod.t("Sesija traje najviše jedan sat i drži mikrofon u pripravnosti. Svaki diktat je produžava za novih sat vremena.")
        case .petnaestMinuta:
            #if APPSTORE
            return Prevod.t("Sesija traje najviše 15 minuta i drži mikrofon u pripravnosti. Svaki diktat je produžava za novih 15 minuta, a posle isteka je uključiš ponovo u Diktatoru.")
            #else
            return Prevod.t("Sesija traje najviše 15 minuta i drži mikrofon u pripravnosti. Svaki diktat je produžava za novih 15 minuta.")
            #endif
        }
    }

    private func oznakaStanja(_ aktivna: Bool) -> some View {
        Text(Prevod.t(aktivna ? "Aktivna" : "Isključena"))
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(aktivna ? Dizajn.zelena : Dizajn.tekstTercijarni)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                (aktivna ? Dizajn.zelena : Dizajn.tekstTercijarni).opacity(0.12),
                in: Capsule()
            )
    }

    // MARK: - Statistika

    private var statistikaKartica: some View {
        NavigationLink {
            PogledStatistika()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    IkonaUKrugu(simbol: "chart.bar.fill", boja: Dizajn.akcenat)
                    Text("Statistika")
                        .font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Dizajn.tekstTercijarni)
                }

                if stanje.statistika.ukupnoSnimaka == 0 {
                    Text("Prvi diktat pokreće statistiku.")
                        .font(.system(size: 14))
                        .foregroundStyle(Dizajn.tekstSekundarni)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(stanje.statistika.danasReci.formatted())
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Dizajn.tekst)
                        Text("reči danas")
                            .font(.system(size: 14))
                            .foregroundStyle(Dizajn.tekstSekundarni)
                        Spacer()
                        if stanje.statistika.nizDana > 0 {
                            Label("\(stanje.statistika.nizDana)", systemImage: "flame.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Dizajn.narandzasta)
                        }
                    }

                    HStack(spacing: 14) {
                        Text("Ukupno \(stanje.statistika.ukupnoReci.formatted())")
                        Text("Ušteđeno \(stanje.statistika.ustedaTekst)")
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(Dizajn.tekstTercijarni)
                }
            }
            .kartica()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Ažuriranje

    @ViewBuilder
    private var azuriranjeKartica: some View {
        if let azuriranje = stanje.dostupnoAzuriranje {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    IkonaUKrugu(simbol: "arrow.down.circle.fill", boja: Dizajn.akcenat)
                    Text("Dostupno ažuriranje")
                        .font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Oznaka(tekst: "v\(azuriranje.verzija)")
                }

                Text("Nova verzija je objavljena. Preuzmi je sa GitHub-a.")
                    .font(.system(size: 14))
                    .foregroundStyle(Dizajn.tekstSekundarni)

                Link(destination: azuriranje.url) {
                    Label("Preuzmi", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(StilDugmeta())
            }
            .kartica()
        }
    }

    // MARK: - Model

    private var modelKartica: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                IkonaUKrugu(simbol: "arrow.down.circle", boja: Dizajn.narandzasta)
                Text("Model još nije preuzet")
                    .font(.system(size: 17, weight: .semibold))
            }
            Text("Otvori Podešavanja i preuzmi Large v3 (~1,0 GB) — preporučeno za srpski.")
                .font(.system(size: 14))
                .foregroundStyle(Dizajn.tekstSekundarni)
                .fixedSize(horizontal: false, vertical: true)
            if let napomena = stanje.napomenaMemorije {
                Text(napomena)
                    .font(.system(size: 12))
                    .foregroundStyle(Dizajn.narandzasta)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button("Otvori Podešavanja") {
                prikaziPodesavanja = true
            }
            .buttonStyle(StilDugmeta())
        }
        .kartica()
    }

    private var savetKartica: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                IkonaUKrugu(simbol: "lightbulb.fill", boja: Dizajn.narandzasta)
                Text("Savet za srpski")
                    .font(.system(size: 17, weight: .semibold))
            }
            Text("Turbo je izabran zbog brzine. Ako želiš tačniji srpski, prebaci na Large v3 (~1,0 GB).")
                .font(.system(size: 14))
                .foregroundStyle(Dizajn.tekstSekundarni)
                .fixedSize(horizontal: false, vertical: true)

            if let large = Modeli.nadji("ggml-large-v3-q5_0.bin") {
                if large.preuzet {
                    Button("Izaberi Large v3") {
                        stanje.izaberiModel(large)
                    }
                    .buttonStyle(StilDugmeta())
                } else {
                    Button("Preuzmi Large v3 (~1,0 GB)") {
                        stanje.preuzmiModel(large)
                    }
                    .buttonStyle(StilDugmeta())
                    .disabled(stanje.modelSePreuzima)
                    .opacity(stanje.modelSePreuzima ? 0.5 : 1)

                    if stanje.modelSePreuzima {
                        ProgressView(value: stanje.napredakPreuzimanja ?? 0) {
                            Text("Preuzimanje Large v3…")
                                .font(.system(size: 12))
                        }
                    }
                }
            }

            Button("Otvori Podešavanja") {
                prikaziPodesavanja = true
            }
            .buttonStyle(StilDugmetaSvetli())
        }
        .kartica()
    }

    private var napomena: some View {
        Text("Za srpski je pouzdanije izabrati **Srpski** u Podešavanjima; automatska detekcija je slabija na kratkim snimcima.")
            .font(.system(size: 13))
            .foregroundStyle(Dizajn.tekstSekundarni)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Poslednji tekst

    @ViewBuilder
    private var poslednjiTekstKartica: some View {
        if !stanje.poslednjiTekst.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text("Poslednji tekst")
                        .font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Button("U rečnik") {
                        predlogRecnika = PredlogRecnika(tekst: stanje.poslednjiTekst)
                    }
                    .buttonStyle(StilDugmetaSvetli())
                    Button("Kopiraj") {
                        stanje.kopirajPoslednji()
                    }
                    .buttonStyle(StilDugmetaSvetli())
                }
                Text(stanje.poslednjiTekst)
                    .font(.system(size: 15))
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .kartica()
        }
    }

    // MARK: - Uputstvo

    private var kakoRadiKartica: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Kako radi")
                .font(.system(size: 17, weight: .semibold))

            korak("keyboard", "Otvori Diktator tastaturu", "U bilo kojoj aplikaciji prebaci na Diktator tastaturu.")
            #if APPSTORE
            korak("mic.fill", "Tapni Diktiraj i govori", "Dugme je u traci iznad tastature; sesija mora biti uključena u Diktatoru, a svaki diktat je produžava.")
            korak("text.cursor", "Tekst se sam ubaci", "Tapni crveni Stop — tekst ide u polje u kome pišeš. Ako ne uspe, tapni Nalepi iznad tastature.")

            Text("Ako sesija nije uključena, Diktiraj te zamoli da otvoriš Diktator i uključiš je.")
                .font(.system(size: 12))
                .foregroundStyle(Dizajn.tekstTercijarni)
            #else
            korak("mic.fill", "Tapni Diktiraj i govori", "Dugme je u traci iznad tastature; sesija se uključuje sama, a svaki diktat je produžava.")
            korak("text.cursor", "Tekst se sam ubaci", "Tapni crveni Stop — tekst ide u polje u kome pišeš. Ako ne uspe, tapni Nalepi iznad tastature.")

            Text("Ako je Diktator ugašen, Diktiraj ga otvara i odmah snima.")
                .font(.system(size: 12))
                .foregroundStyle(Dizajn.tekstTercijarni)
            #endif
        }
        .kartica()
    }

    private func korak(_ simbol: String, _ naslov: LocalizedStringKey, _ opis: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            IkonaUKrugu(simbol: simbol, boja: Dizajn.akcenat, velicina: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(naslov)
                    .font(.system(size: 15, weight: .semibold))
                Text(opis)
                    .font(.system(size: 13))
                    .foregroundStyle(Dizajn.tekstSekundarni)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Traka za povratak

/// Podseća korisnika da se vrati u aplikaciju u kojoj je diktirao.
///
/// iOS ne daje način da aplikacija sama prebaci u drugu aplikaciju, pa je
/// jedini povratak sistemski: prevlačenje prstom udesno po donjoj ivici
/// ekrana ili strelica ‹ u gornjem levom uglu. Zato traka ne izgleda kao
/// dugme — crta gest (tačka klizi udesno) i kaže gde se tapne.
private struct TrakaPovratka: View {
    let naslov: String
    let opis: String

    @Environment(\.accessibilityReduceMotion) private var smanjiPokret
    @State private var klizi = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(naslov)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Dizajn.tekst)
                Text(opis)
                    .font(.system(size: 13))
                    .foregroundStyle(Dizajn.tekstSekundarni)
                    .fixedSize(horizontal: false, vertical: true)
            }

            gest

            Text(Prevod.t("ili tapni ‹ u gornjem levom uglu ekrana"))
                .font(.system(size: 12))
                .foregroundStyle(Dizajn.tekstTercijarni)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Dizajn.akcenatMeki)
        .clipShape(RoundedRectangle(cornerRadius: Dizajn.radijusKartice, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Dizajn.radijusKartice, style: .continuous)
                .stroke(Dizajn.akcenat.opacity(0.25), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    /// Crtež donje ivice ekrana: tačka klizi udesno, kao prst pri povratku.
    private var gest: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geometrija in
                let sirina = geometrija.size.width
                let precnik: CGFloat = 16
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Dizajn.akcenat.opacity(0.18))
                        .frame(height: 7)
                        .frame(maxHeight: .infinity, alignment: .center)

                    Circle()
                        .fill(Dizajn.akcenat)
                        .frame(width: precnik, height: precnik)
                        .offset(x: klizi ? sirina - precnik : 0)

                    HStack {
                        Spacer()
                        Image(systemName: "chevron.right.2")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Dizajn.akcenat.opacity(0.65))
                    }
                }
            }
            .frame(height: 22)
            .accessibilityHidden(true)

            Text(Prevod.t("Prevuci prstom udesno po donjoj ivici ekrana"))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Dizajn.tekstSekundarni)
                .fixedSize(horizontal: false, vertical: true)
        }
        .animation(pokret, value: klizi)
        .onAppear { klizi = true }
    }

    /// Tačka tiho klizi udesno, kao prst — osim kada je uključeno smanjenje
    /// pokreta.
    private var pokret: Animation? {
        smanjiPokret ? nil : .easeInOut(duration: 1.1).repeatForever(autoreverses: false)
    }
}
