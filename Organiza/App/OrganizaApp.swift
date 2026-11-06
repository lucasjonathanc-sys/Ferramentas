import SwiftData
import SwiftUI
import UIKit
import UserNotifications

@main
struct OrganizaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        Fonte.registrar()
        Fonte.configurarAparencia()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.locale, Fmt.locale)
        }
        .modelContainer(for: [Atividade.self, Cliente.self])
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Mostra o lembrete mesmo com o app aberto
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}
