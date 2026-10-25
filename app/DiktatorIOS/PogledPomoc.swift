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
                    Text("Full Access je potreban da tastatura pročita clipboard i ubaci tekst.")

                    Divider()

                    Text("Diktat")
                        .font(.title2.bold())
                    Text("1. U bilo kojoj aplikaciji prebaci na Diktator tastaturu.")
                    Text("2. Tapni Diktiraj — otvara se aplikacija (ako iOS pita, tapni Open).")
                    Text("3. Snimi govor i sačekaj prepis.")
                    Text("4. Vrati se preko „Back to …“ i tapni Nalepi.")

                    Divider()

                    Text("Privatnost")
                        .font(.title2.bold())
                    Text("Snimak se obrađuje lokalno. Aplikacija ne šalje zvuk na server. Model se preuzima sa Hugging Face-a.")

                    Divider()

                    Text("Ograničenja")
                        .font(.title2.bold())
                    Text("Tastatura ne može da snima — Apple to zabranjuje. Zato se snima u aplikaciji.")
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
