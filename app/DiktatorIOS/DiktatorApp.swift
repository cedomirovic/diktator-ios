import SwiftUI
import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let centar = UNUserNotificationCenter.current()
        centar.delegate = self

        // Dugme „Preuzmi“ direktno na obaveštenju o novoj verziji.
        let preuzmi = UNNotificationAction(
            identifier: "diktator.preuzmi",
            title: "Preuzmi",
            options: [.foreground]
        )
        let kategorija = UNNotificationCategory(
            identifier: "diktator.azuriranje",
            actions: [preuzmi],
            intentIdentifiers: [],
            options: []
        )
        // Nedeljni pregled samo otvara statistiku na dodir, bez dodatnih akcija.
        let pregled = UNNotificationCategory(
            identifier: "diktator.pregled",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        centar.setNotificationCategories([kategorija, pregled])
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let informacije = response.notification.request.content.userInfo
        if informacije["pregled"] as? String == "1" {
            await MainActor.run {
                NavigacijaZahteva.deljena.otvoriStatistiku = true
            }
            return
        }
        guard let tekst = informacije["url"] as? String,
              let url = URL(string: tekst) else {
            return
        }
        await MainActor.run {
            UIApplication.shared.open(url)
        }
    }
}

@main
struct DiktatorApp: App {
    @StateObject private var stanje = AppStanje()
    @StateObject private var navigacija = NavigacijaZahteva.deljena
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(stanje)
                .environmentObject(navigacija)
                .onOpenURL { url in
                    stanje.obradiURL(url)
                }
                .onChange(of: navigacija.otvoriStatistiku) { _, novo in
                    // Obaveštenje o nedeljnom pregledu vodi na statistiku,
                    // koja je deo taba Diktat.
                    if novo {
                        stanje.izabraniTab = 0
                    }
                }
                .onChange(of: scenePhase) { _, nova in
                    switch nova {
                    case .active:
                        Dnevnik.pisi("scenePhase: active")
                    case .inactive:
                        Dnevnik.pisi("scenePhase: inactive")
                    case .background:
                        Dnevnik.pisi("scenePhase: background")
                    @unknown default:
                        break
                    }
                    if nova == .active || nova == .background {
                        stanje.osveziIPC()
                    }
                    if nova == .active {
                        // Keš dozvole se osveži unapred, da „Testiraj
                        // obaveštenje“ ne čeka proveru sistema.
                        Task { await Azuriranja.osveziDozvolu() }
                        stanje.proveriAzuriranja()
                        // Brojevi u nedeljnom pregledu prate poslednje stanje.
                        stanje.osveziNedeljniPodsetnik()
                    }
                }
                .task {
                    stanje.proveriAzuriranja()
                }
        }
    }
}
