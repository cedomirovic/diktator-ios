import SwiftUI

struct PogledPomoc: View {
    private let podrska = URL(string: "mailto:cedomirovicnemanja@gmail.com?subject=Diktator%20iOS")
    private let github = URL(string: "https://github.com/cedomirovic/diktator-ios")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    NaslovEkrana(
                        naslov: "Pomoć",
                        podnaslov: "Sve što treba da znaš o tastaturi, sesiji i privatnosti."
                    )

                    koraciKartica
                    diktatKartica
                    tekstKartica(
                        naslov: "Statistika",
                        pasusi: [
                            "Na glavnom ekranu vidiš današnje reči, niz dana i ušteđeno vreme. Tapni karticu za grafikon poslednjih 7 dana, prosečnu brzinu i pregled jezika.",
                            "Statistika se računa lokalno iz broja reči i trajanja diktata. Ne čuva tekst; možeš je obrisati bez brisanja istorije."
                        ]
                    )
                    tekstKartica(
                        naslov: "Privatnost",
                        pasusi: [
                            "Snimak se obrađuje lokalno. Aplikacija ne šalje zvuk na server. Model se preuzima sa Hugging Face-a.",
                            "Ako uključiš doterivanje, samo gotov tekst ide izabranom servisu (Gemini, OpenAI, Claude, DeepSeek ili drugi). Nikada se ne šalje zvuk.",
                            "Ako izabereš Groq u Podešavanjima → Brzina, snimak se šalje Groq-u radi bržeg prepisa. U režimima Brzo i Najtačnije sve ostaje na uređaju."
                        ]
                    )
                    tekstKartica(
                        naslov: "Ograničenja",
                        pasusi: [
                            "Tastatura ne može direktno da snima — Apple to zabranjuje. Zato snima glavna aplikacija u pozadinskoj sesiji, a tastatura samo šalje start/stop.",
                            "Sesija drži mikrofon u pripravnosti najviše 15 minuta i troši bateriju. Zato se automatski gasi.",
                            "Kada je sesija uključena, mikrofon u tastaturi ne otvara aplikaciju. Ako sesija nije uključena, mikrofon otvara Diktator; tapni Uključi sesiju i vrati se. Posle Stop sačekaj da se tekst ubaci; ako ne uspe, u traci iznad tastature pojaviće se Nalepi.",
                            "Besplatni Apple ID profil traje 7 dana; posle toga build treba obnoviti."
                        ]
                    )
                    podrskaKartica
                }
                .frame(maxWidth: 640)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity)
            }
            .background(Dizajn.pozadina)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Delovi

    private var koraciKartica: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Kako da uključiš tastaturu")
                .font(.system(size: 17, weight: .semibold))

            korak(1, "Podešavanja → General → Keyboard → Keyboards → Add New Keyboard.")
            korak(2, "Izaberi Diktator.")
            korak(3, "Tapni Diktator i uključi Allow Full Access.")

            Text("Full Access je potreban da tastatura pročita clipboard, ubaci tekst i otvori aplikaciju dodirom na mikrofon (iOS 26+). Ako u traci iznad tastature piše Uključi Full Access, dodir na mikrofon neće raditi.")
                .font(.system(size: 13))
                .foregroundStyle(Dizajn.tekstSekundarni)
                .fixedSize(horizontal: false, vertical: true)
        }
        .kartica()
    }

    private var diktatKartica: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Diktat")
                .font(.system(size: 17, weight: .semibold))

            korak(1, "Pređi u bilo koju aplikaciju i otvori Diktator tastaturu.")
            korak(2, "Tapni mikrofon u donjem redu tastature. Ako sesija nije uključena, Diktator se sam otvori, uključi je i počne da snima.")
            korak(3, "Tapni crveni Stop — tekst se sam ubaci u polje u kome pišeš. Ako ne uspe, tapni Nalepi u traci iznad tastature.")

            Text("Sesija traje 15 minuta i svaki diktat je produžava. Kada istekne, prvi dodir na mikrofon je ponovo uključi.")
                .font(.system(size: 13))
                .foregroundStyle(Dizajn.tekstSekundarni)
                .fixedSize(horizontal: false, vertical: true)

            Text("Za najbolji srpski: Jezik = Srpski i Brzina = Najtačnije — Large v3.")
                .font(.system(size: 12))
                .foregroundStyle(Dizajn.tekstTercijarni)
                .fixedSize(horizontal: false, vertical: true)
        }
        .kartica()
    }

    private func tekstKartica(naslov: String, pasusi: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(naslov)
                .font(.system(size: 17, weight: .semibold))

            ForEach(pasusi, id: \.self) { pasus in
                Text(pasus)
                    .font(.system(size: 14))
                    .foregroundStyle(Dizajn.tekstSekundarni)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .kartica()
    }

    private var podrskaKartica: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                IkonaUKrugu(simbol: "questionmark.bubble.fill", velicina: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text("I dalje imate pitanja?")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Pošalji model uređaja, verziju iOS-a i kratak opis problema.")
                        .font(.system(size: 13))
                        .foregroundStyle(Dizajn.tekstSekundarni)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            if let podrska {
                Link(destination: podrska) {
                    Label("Kontaktiraj podršku", systemImage: "envelope.fill")
                }
                .buttonStyle(StilDugmeta())
            }

            Link(destination: github) {
                Label("GitHub projekat", systemImage: "link")
                    .font(.system(size: 13, weight: .medium))
            }
            .tint(Dizajn.akcenat)
        }
        .kartica()
    }

    private func korak(_ broj: Int, _ tekst: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(broj)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Dizajn.akcenat)
                .frame(width: 24, height: 24)
                .background(Dizajn.akcenat.opacity(0.12), in: Circle())

            Text(tekst)
                .font(.system(size: 14))
                .foregroundStyle(Dizajn.tekst)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
    }
}
