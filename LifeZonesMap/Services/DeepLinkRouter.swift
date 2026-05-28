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

    /// Decode a deepLink dictionary value (from notifications, widgets,
    /// or URL schemes) and update `pending` if recognized.
    func handle(deepLinkValue: String?) {
        handle(deepLink: deepLinkValue)
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
        // Extract the Sendable string here in the nonisolated context;
        // [AnyHashable: Any] itself isn't safe to send across actors.
        let link = response.notification.request.content.userInfo["deepLink"] as? String
        Task { @MainActor in
            self.handle(deepLink: link)
        }
        completionHandler()
    }

    private func handle(deepLink: String?) {
        guard let deepLink else { return }
        switch deepLink {
        case "checkin":  pending = .openCheckIn
        case "journal":  pending = .openJournal
        default:         break
        }
    }
}
