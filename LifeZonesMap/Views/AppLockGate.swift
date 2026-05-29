import SwiftUI
import SwiftData

/// Gates `content` behind Face ID / Touch ID / passcode when the user has
/// opted into the app lock. Re-locks when the app goes to background.
struct AppLockGate<Content: View>: View {
    @Query private var prefsArray: [UserPreferences]
    @Environment(\.scenePhase) private var scenePhase

    @State private var unlocked = false
    @State private var attemptInFlight = false

    let content: () -> Content

    private var lockEnabled: Bool {
        prefsArray.first?.appLockEnabled ?? false
    }

    var body: some View {
        ZStack {
            content()
                .opacity(needsAuth ? 0 : 1)   // hide pixels while locked
                .allowsHitTesting(!needsAuth)

            if needsAuth {
                LockScreen(
                    biometryLabel: AppLockService.biometryLabel,
                    inFlight: attemptInFlight,
                    onUnlock: { Task { await attemptUnlock() } }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: needsAuth)
        .onAppear {
            if lockEnabled {
                Task { await attemptUnlock() }
            } else {
                unlocked = true
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Re-lock when the app leaves the foreground.
            if lockEnabled && newPhase != .active {
                unlocked = false
            }
            if lockEnabled && newPhase == .active && !unlocked {
                Task { await attemptUnlock() }
            }
        }
    }

    private var needsAuth: Bool { lockEnabled && !unlocked }

    @MainActor
    private func attemptUnlock() async {
        guard !attemptInFlight else { return }
        attemptInFlight = true
        let ok = await AppLockService.authenticate(
            reason: "Unlock Life Zones to see your check-ins."
        )
        attemptInFlight = false
        if ok {
            withAnimation { unlocked = true }
        }
    }
}

/// The visible lock surface — large icon + tap-to-unlock button. Shown only
/// while the gate is locked.
private struct LockScreen: View {
    let biometryLabel: String
    let inFlight: Bool
    var onUnlock: () -> Void

    var body: some View {
        ZStack {
            LZ.paper.ignoresSafeArea()
            TopoTexture(
                lines: 20,
                palette: TopoPalette.sageCoast,
                seed: 7,
                opacity: 0.35,
                lineWidth: 0.8
            )
            .opacity(0.4)
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                IconMark(size: 96, color: LZ.tealDeep, bg: LZ.cream, rounded: 22)

                VStack(spacing: 6) {
                    Text("Life Zones is locked.")
                        .font(.system(size: 22, weight: .medium))
                        .tracking(-0.45)
                        .foregroundStyle(LZ.ink)
                    Text("Use \(biometryLabel) to continue.")
                        .font(LZType.serifItalic(14))
                        .foregroundStyle(LZ.inkSoft)
                }

                Spacer()

                Button(action: onUnlock) {
                    HStack(spacing: 8) {
                        if inFlight {
                            ProgressView().tint(LZ.cream)
                        } else {
                            Image(systemName: biometryLabel == "Face ID" ? "faceid"
                                            : (biometryLabel == "Touch ID" ? "touchid" : "lock"))
                        }
                        Text(inFlight ? "Verifying…" : "Unlock with \(biometryLabel)")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(LZ.tealDeep)
                    .foregroundStyle(LZ.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(inFlight)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}
