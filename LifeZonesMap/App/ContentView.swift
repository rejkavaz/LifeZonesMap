import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var prefsArray: [UserPreferences]

    @State private var selectedTab = 0
    @State private var showOnboarding = false
    @State private var mapVM = MapViewModel()
    @State private var selectedZone: ZoneID?

    private var prefs: UserPreferences? { prefsArray.first }

    var body: some View {
        TabView(selection: $selectedTab) {
            mapTab.tabItem {
                Label("Map", systemImage: "map.fill")
            }.tag(0)

            CheckInView().tabItem {
                Label("Check In", systemImage: "plus.circle.fill")
            }.tag(1)

            PulseView().tabItem {
                Label("Pulse", systemImage: "waveform.path.ecg")
            }.tag(2)

            SettingsView().tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }.tag(3)
        }
        .tint(Color(hex: "#1D9E75"))
        .onAppear { checkOnboarding() }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingFlow {
                showOnboarding = false
                mapVM.loadCurrentWeek()
            }
        }
        .sheet(item: $selectedZone) { zone in
            ZoneDetailSheet(zone: zone)
        }
    }

    private var mapTab: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MapView(scores: mapVM.scores, onZoneTap: { selectedZone = $0 })
                    .frame(height: 340)
                    .padding()

                zoneList
            }
            .navigationTitle("Life Zones")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text(Date().isoWeekLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .onAppear { mapVM.setup(modelContext: modelContext) }
    }

    private var zoneList: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.s8) {
                ForEach(ZoneRegistry.all) { def in
                    Button {
                        selectedZone = def.id
                    } label: {
                        HStack(spacing: DS.Spacing.s12) {
                            Circle()
                                .fill(def.color)
                                .frame(width: 10, height: 10)
                            Text(def.name)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Spacer()
                            GeometryReader { geo in
                                HStack(spacing: 0) {
                                    Spacer()
                                    Rectangle()
                                        .fill(def.color.opacity(0.3))
                                        .frame(width: geo.size.width * CGFloat(mapVM.scores[def.id] ?? 5) / 10, height: 6)
                                        .clipShape(Capsule())
                                }
                            }
                            .frame(width: 80, height: 6)

                            Text("\(mapVM.scores[def.id] ?? 5)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(def.color)
                                .frame(width: 20)
                        }
                        .padding(.horizontal, DS.Spacing.s16)
                        .padding(.vertical, DS.Spacing.s12)
                        .background(.background, in: RoundedRectangle(cornerRadius: DS.Radius.md))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, DS.Spacing.s32)
        }
    }

    private func checkOnboarding() {
        showOnboarding = prefs?.onboardingComplete != true
        if !showOnboarding { mapVM.setup(modelContext: modelContext) }
    }
}

extension ZoneID: Identifiable {}
