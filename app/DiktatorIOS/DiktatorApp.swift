import SwiftUI

@main
struct DiktatorApp: App {
    @StateObject private var stanje = AppStanje()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(stanje)
                .onOpenURL { url in
                    stanje.obradiURL(url)
                }
        }
    }
}
