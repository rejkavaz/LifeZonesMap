import Foundation
import UserNotifications
import Observation
import SwiftUI

/// Decoded actions the app responds to from notifications, widgets,
/// shortcut URLs, etc. A single source of truth for "where should I send
/// the user right now?"
enum DeepLinkAction: Equatable {
    case openCheckIn
    case openZoneDetail(ZoneID)
    case openJournal
}

/// A small @Observable bus that any view can observe via @Environment or
/// @State injection. ContentView watches this and switches tabs accordingly.
@Observable
@MainActor
final class DeepLinkRouter: NSObject, UNUserNotificationCenterDelegate {
    /// The latest pending action. ContentView consumes this by reading then
    /// setting back to nil.
    var pending: DeepLinkAction?

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func handle(userInfo: [AnyHashable: Any]) {
        guard let link = userInfo["deepLink"] as? String else { return }
        switch link {
        case "checkin":  pending = .openCheckIn
        case "journal":  pending = .openJournal
        default:         break
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Foreground notification — still let it banner so the user knows it's
    /// time, but also tee up the deep link in case they tap.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    /// User tapped the notification (from background, lock screen, or banner).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handle(userInfo: response.notification.request.content.userInfo)
        completionHandler()
    }
}
