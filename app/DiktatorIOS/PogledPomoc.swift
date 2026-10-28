import SwiftUI

struct PogledPomoc: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Kako da uključiš tastaturu")
                        .font(.title2.bold())
                    Text("1. Podešavanja → General → Keyboard → Keyboards → Add New Keyboard.")
                    Text("2. Izaberi Diktator.")
                    Text("3. Tapni Diktator i uključi Allow Full Access.")
                    Text("Full Access je potreban da tastatura pročita clipboard, ubaci tekst i otvori aplikaciju dugmetom Diktiraj (iOS 26+). U gornjoj traci tastature treba da piše Full Access ✓.")

                    Divider()

                    Text("Diktat")
                        .font(.title2.bold())
                    Text("1. Pređi u bilo koju aplikaciju i otvori Diktator tastaturu.")
                    Text("2. Tapni Diktiraj. Ako sesija nije uključena, Diktator se sam otvori, uključi je i počne da snima.")
                    Text("3. Tapni Stop — tekst se sam ubaci u polje u kome pišeš. Ako ne uspe, tapni Nalepi.")
                    Text("Sesija traje 15 minuta i svaki diktat je produžava. Kada istekne, prvi Diktiraj je ponovo uključi.")
                    Text("Za najbolji srpski: Jezik = Srpski, Model = Large v3, Režim = Najbolji kvalitet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Divider()

                    Text("Statistika")
                        .font(.title2.bold())
                    Text("Na glavnom ekranu vidiš današnje reči, niz dana i ušteđeno vreme. Tapni karticu za grafikon poslednjih 7 dana, prosečnu brzinu i pregled jezika.")
                    Text("Statistika se računa lokalno iz broja reči i trajanja diktata. Ne čuva tekst; možeš je obrisati bez brisanja istorije.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Divider()

                    Text("Privatnost")
                        .font(.title2.bold())
                    Text("Snimak se obrađuje lokalno. Aplikacija ne šalje zvuk na server. Model se preuzima sa Hugging Face-a.")
                    Text("Ako uključiš doterivanje, samo gotov tekst ide izabranom servisu (Gemini, OpenAI, Claude, DeepSeek ili drugi). Nikada se ne šalje zvuk.")
                    Text("Ako izabereš Groq u Podešavanjima → Brzina, snimak se šalje Groq-u radi bržeg prepisa. U režimima Brzo i Najtačnije sve ostaje na uređaju.")

                    Divider()

                    Text("Ograničenja")
                        .font(.title2.bold())
                    Text("Tastatura ne može direktno da snima — Apple to zabranjuje. Zato snima glavna aplikacija u pozadinskoj sesiji, a tastatura samo šalje start/stop.")
                    Text("Sesija drži mikrofon u pripravnosti najviše 15 minuta i troši bateriju. Zato se automatski gasi.")
                    Text("Kada je sesija uključena, Diktiraj ne otvara aplikaciju. Ako sesija nije uključena, Diktiraj otvara Diktator; tapni Uključi sesiju i vrati se. Posle Stop sačekaj da piše Spremno je, nalepi, pa tapni Nalepi.")
                    Text("Besplatni Apple ID profil traje 7 dana; posle toga build treba obnoviti.")

                    Divider()

                    Link("GitHub projekat", destination: URL(string: "https://github.com/cedomirovic/diktator-ios")!)
                        .font(.footnote)
                }
                .padding()
            }
            .navigationTitle("Pomoć")
        }
    }
}
