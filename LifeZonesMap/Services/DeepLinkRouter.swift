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
    // These have to be nonisolated because the protocol requirement isn't
    // main-actor-isolated. Both then hop back to MainActor to mutate state.

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        Task { @MainActor in
            self.handle(userInfo: userInfo)
        }
        completionHandler()
    }
}
