import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var prefsArray: [UserPreferences]
    @Query private var checkIns: [WeeklyCheckIn]
    @Query private var insights: [ZoneInsight]
    @Query private var reflections: [WeeklyReflection]

    @State private var showDeleteAlert = false
    @State private var showExportSheet = false
    @State private var exportItem: ExportSheetItem?

    private var prefs: UserPreferences {
        prefsArray.first ?? {
            let p = UserPreferences(); modelContext.insert(p); return p
        }()
    }

    var body: some View {
        NavigationStack {
            List {
                helpSection
                checkInSection
                zonesSection
                appearanceSection
                privacySection
                healthSection
                historySection
                insightsSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(LZ.paper.ignoresSafeArea())
            .tint(LZ.tealDeep)
            .navigationTitle("Settings")
            .alert("Delete all data?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) { deleteAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all check-ins, insights, and preferences. This cannot be undone.")
            }
            .sheet(item: $exportItem) { item in
                ShareSheet(items: [item.data])
            }
        }
    }

    // MARK: - Sections

    private var helpSection: some View {
        Section {
            NavigationLink {
                TutorialView()
            } label: {
                Label("Tour & help", systemImage: "book")
            }
        } footer: {
            Text("Every feature, explained — what the app does and why.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var checkInSection: some View {
        Section("Check-in schedule") {
            Picker("Reminder day", selection: Binding(
                get: { prefs.checkInDayOfWeek },
                set: {
                    prefs.checkInDayOfWeek = $0
                    reschedule()
                    // Tell the widget so the lock-screen "Tap to check in"
                    // state lights up on the right day.
                    WidgetDataProvider.updateCheckInWeekday($0 + 1)
                }
            )) {
                ForEach(0..<7) { i in
                    Text(dayName(i)).tag(i)
                }
            }

            HStack {
                Text("Reminder time")
                Spacer()
                Picker("", selection: Binding(
                    get: { prefs.checkInHour },
                    set: { prefs.checkInHour = $0; reschedule() }
                )) {
                    ForEach(6..<23) { h in
                        Text(timeLabel(h)).tag(h)
                    }
                }
                .labelsHidden()
            }

            Toggle("Enable notifications", isOn: Binding(
                get: { prefs.notificationsEnabled },
                set: { enabled in
                    prefs.notificationsEnabled = enabled
                    if enabled { reschedule() } else { NotificationScheduler.shared.cancelReminder() }
                }
            ))

            Toggle("Haptic feedback", isOn: Binding(
                get: { prefs.enableHaptics },
                set: { prefs.enableHaptics = $0 }
            ))
        }
    }

    private var zonesSection: some View {
        Section("Zones") {
            NavigationLink("Customize zone names") {
                CustomZoneNamesView(prefs: prefs)
            }
            NavigationLink {
                GoalsView()
            } label: {
                Label("Goals", systemImage: "target")
            }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            NavigationLink {
                AppIconPickerView()
            } label: {
                Label("App icon", systemImage: "app.badge")
            }
        }
    }

    private var privacySection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { prefs.appLockEnabled },
                set: { newValue in
                    if newValue {
                        // Make sure they can actually authenticate before
                        // turning it on — otherwise they'd lock themselves out.
                        Task {
                            let ok = await AppLockService.authenticate(
                                reason: "Confirm to enable app lock for Life Zones."
                            )
                            if ok { prefs.appLockEnabled = true }
                        }
                    } else {
                        prefs.appLockEnabled = false
                    }
                }
            )) {
                Label("Lock with \(AppLockService.biometryLabel)", systemImage: "lock")
            }
            .disabled(!AppLockService.isAvailable)
        } header: {
            Text("Privacy")
        } footer: {
            if AppLockService.isAvailable {
                Text("Require \(AppLockService.biometryLabel) when the app opens or returns from the background.")
            } else {
                Text("Set up Face ID / Touch ID or a passcode on this device to enable app lock.")
            }
        }
    }

    private var healthSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { prefs.healthKitVitalityEnabled },
                set: { newValue in
                    if newValue {
                        Task {
                            let granted = await HealthKitService.shared.requestPermission()
                            prefs.healthKitVitalityEnabled = granted
                        }
                    } else {
                        prefs.healthKitVitalityEnabled = false
                    }
                }
            )) {
                Label("Suggest Vitality from Health", systemImage: "heart.text.square")
            }
            .disabled(!HealthKitService.isAvailable)
        } header: {
            Text("Apple Health")
        } footer: {
            if HealthKitService.isAvailable {
                Text("Read sleep, steps, and mindful minutes from the last 7 days to suggest a Vitality score during your check-in. Read-only — nothing is written back to Health.")
            } else {
                Text("Apple Health isn't available on this device.")
            }
        }
    }

    private var historySection: some View {
        Section("Your data") {
            NavigationLink {
                HistoryView()
            } label: {
                Label("All past weeks", systemImage: "clock.arrow.circlepath")
            }
        }
    }

    private var insightsSection: some View {
        Section("Insights") {
            Toggle("Local pattern insights", isOn: Binding(
                get: { prefs.enableInsights },
                set: { prefs.enableInsights = $0 }
            ))

            Toggle("AI insights (Anthropic API)", isOn: Binding(
                get: { prefs.insightAPIEnabled },
                set: { prefs.insightAPIEnabled = $0 }
            ))

            if prefs.insightAPIEnabled {
                SecureField("Anthropic API key", text: Binding(
                    get: { prefs.anthropicAPIKey },
                    set: { prefs.anthropicAPIKey = $0 }
                ))
                .font(.system(.body, design: .monospaced))

                Text("Your check-in data is sent to Anthropic's API to generate richer insights. No other data leaves your device.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var dataSection: some View {
        Section("Data") {
            NavigationLink {
                BackupSettingsView()
            } label: {
                Label("Backup & restore", systemImage: "externaldrive.badge.timemachine")
            }
            Button("Export as JSON") {
                let data = ExportService().exportJSON(checkIns: Array(checkIns))
                exportItem = ExportSheetItem(data: data, filename: "lifezonesmap.json")
            }
            Button("Export as CSV") {
                let data = ExportService().exportCSV(checkIns: Array(checkIns))
                exportItem = ExportSheetItem(data: data, filename: "lifezonesmap.csv")
            }
            Button("Export PDF report") {
                let data = ExportService().exportPDFReport(
                    checkIns: Array(checkIns),
                    insights: Array(insights),
                    reflections: Array(reflections)
                )
                exportItem = ExportSheetItem(data: data, filename: "lifezonesmap_report.pdf")
            }
            Button("Delete all data", role: .destructive) {
                showDeleteAlert = true
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Privacy")
                Spacer()
                Text("On-device by default")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func reschedule() {
        guard prefs.notificationsEnabled else { return }
        Task {
            await NotificationScheduler.shared.scheduleWeeklyReminder(
                dayOfWeek: prefs.checkInDayOfWeek,
                hour: prefs.checkInHour
            )
        }
    }

    private func deleteAll() {
        let service = CheckInService(modelContext: modelContext)
        try? service.deleteAll()
        insights.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }

    // MARK: - Helpers

    private func dayName(_ i: Int) -> String {
        ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"][i]
    }

    private func timeLabel(_ h: Int) -> String {
        let f = DateFormatter(); f.dateFormat = "h a"
        var c = DateComponents(); c.hour = h; c.minute = 0
        return Calendar.current.date(from: c).map { f.string(from: $0) } ?? "\(h):00"
    }
}

// MARK: - Export helpers

struct ExportSheetItem: Identifiable {
    let id = UUID()
    let data: Data
    let filename: String
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
