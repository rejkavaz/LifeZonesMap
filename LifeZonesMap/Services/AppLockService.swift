import Foundation
import LocalAuthentication
import OSLog

private let lockLog = Logger(subsystem: "com.rejkavaz.LifeZonesMap", category: "AppLock")

/// Thin wrapper around LocalAuthentication. Face ID falls back to Touch ID
/// falls back to device passcode (`.deviceOwnerAuthentication` policy).
@MainActor
enum AppLockService {
    /// Is some form of biometric / passcode evaluable on this device?
    static var isAvailable: Bool {
        var error: NSError?
        let canEval = LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        if !canEval {
            lockLog.notice("Authentication unavailable: \(error?.localizedDescription ?? "nil", privacy: .public)")
        }
        return canEval
    }

    /// Tells the user-facing UI whether to say "Face ID", "Touch ID", or
    /// just "Unlock".
    static var biometryLabel: String {
        let ctx = LAContext()
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        switch ctx.biometryType {
        case .faceID:  return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default:       return "Unlock"
        }
    }

    /// Throws on cancellation or failure. Returns true on success.
    static func authenticate(reason: String) async -> Bool {
        let ctx = LAContext()
        ctx.localizedFallbackTitle = "Use passcode"
        do {
            return try await ctx.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
        } catch {
            lockLog.notice("Auth failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}
