import SwiftUI

struct ContentView: View {
    @EnvironmentObject var stanje: AppStanje
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $stanje.izabraniTab) {
            PogledDiktat()
                .tabItem { Label("Diktat", systemImage: "mic.fill") }
                .tag(0)

            PogledIstorija()
                .tabItem { Label("Istorija", systemImage: "clock") }
                .tag(1)

            PogledRecnik()
                .tabItem { Label("Rečnik", systemImage: "text.book.closed") }
                .tag(2)

            NavigationStack {
                PogledPodesavanja()
            }
            .tabItem { Label("Podešavanja", systemImage: "gearshape") }
            .tag(3)

            PogledPomoc()
                .tabItem { Label("Pomoć", systemImage: "questionmark.circle") }
                .tag(4)
        }
        .onChange(of: scenePhase) { _, nova in
            switch nova {
            case .background:
                if stanje.sesijaAktivna || stanje.stanje.jeZauzet {
                    stanje.osveziIPC()
                } else {
                    stanje.oslobodiModel()
                }
            case .active:
                stanje.osveziIPC()
            default:
                break
            }
        }
    }
}
