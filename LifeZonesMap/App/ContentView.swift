import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var prefsArray: [UserPreferences]

    @State private var activeTab: AppTab = PreviewSeeder.isActive ? PreviewSeeder.initialTab() : .map
    @State private var showOnboarding = false
    @State private var showSettings = false
    @State private var mapVM = MapViewModel()
    @State private var selectedZone: ZoneID?

    private var prefs: UserPreferences? { prefsArray.first }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Active tab content
            Group {
                switch activeTab {
                case .map:
                    ZStack(alignment: .top) {
                        MapView(
                            scores: mapVM.scores,
                            onZoneTap: { selectedZone = $0 },
                            onSettingsTap: { showSettings = true }
                        )
                        if let p = prefs, !p.hasSeenMapTip, !mapVM.scores.isEmpty {
                            MapTip(prefs: p)
                                .padding(.horizontal, 32)
                                .padding(.top, 380)   // hovers just below the radar card
                        }
                    }
                case .check:
                    CheckInView()
                case .pulse:
                    PulseView()
                case .journal:
                    JournalView()
                }
            }
            .padding(.bottom, 60) // leave room for tab bar

            LZTabBar(active: $activeTab)
        }
        .background(LZ.paper.ignoresSafeArea())
        .onAppear {
            checkOnboarding()
            mapVM.setup(modelContext: modelContext)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingFlow {
                showOnboarding = false
                mapVM.loadCurrentWeek()
            }
        }
        .sheet(item: $selectedZone) { zone in
            ZoneDetailSheet(zone: zone)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private func checkOnboarding() {
        showOnboarding = prefs?.onboardingComplete != true
    }
}
// Triggering a cloud test build
