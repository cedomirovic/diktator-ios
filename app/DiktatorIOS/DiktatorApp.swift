import SwiftUI
import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
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
        guard let tekst = response.notification.request.content.userInfo["url"] as? String,
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
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(stanje)
                .onOpenURL { url in
                    stanje.obradiURL(url)
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
                        stanje.proveriAzuriranja()
                    }
                }
                .task {
                    stanje.proveriAzuriranja()
                }
        }
    }
}
