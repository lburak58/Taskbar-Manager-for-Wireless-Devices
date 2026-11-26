import Foundation
import UserNotifications
import TMWDCore

/// Yalnizca .app bundle'i icindeyken calisir; izin ilk dusuk pil aninda istenir.
enum Notifier {
    static var isAvailable: Bool { Bundle.main.bundleIdentifier != nil && Bundle.main.bundlePath.hasSuffix(".app") }

    static func notifyLow(_ devices: [BatteryDevice]) {
        guard isAvailable, !devices.isEmpty else { return }
        let center = UNUserNotificationCenter.current()
        let body = Formatting.notificationBody(devices)
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    if granted { post(center, body) }
                }
            case .authorized, .provisional:
                post(center, body)
            default:
                break // izin yok: sessizce gec
            }
        }
    }

    private static func post(_ center: UNUserNotificationCenter, _ body: String) {
        let content = UNMutableNotificationContent()
        content.title = Strings.appName
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request) { _ in }
    }
}
