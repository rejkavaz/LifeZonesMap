import SwiftUI
import SwiftData

struct OnboardingFlow: View {
    @Environment(\.modelContext) private var modelContext
    @State private var page = 0
    @State private var checkInDay = 0
    @State private var checkInHour = 19
    @State private var notificationsGranted = false
    @State private var scores: [ZoneID: Int] = Dictionary(uniqueKeysWithValues: ZoneID.allCases.map { ($0, 5) })

    var onComplete: () -> Void

    var body: some View {
        TabView(selection: $page) {
            welcomePage.tag(0)
            zonesPage.tag(1)
            schedulePage.tag(2)
            firstCheckInPage.tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .ignoresSafeArea()
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: DS.Spacing.s32) {
            Spacer()
            MapView(scores: MapViewModel.demoScores())
                .frame(height: 260)
                .padding(.horizontal)

            VStack(spacing: DS.Spacing.s12) {
                Text("Your life, mapped.")
                    .font(.largeTitle).fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text("A quiet weekly check-in.\nNo streaks. No judgment.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, DS.Spacing.s32)

            Spacer()

            pageButton("Get started") { withAnimation { page = 1 } }
        }
        .padding(.bottom, DS.Spacing.s48)
    }

    // MARK: - Page 2: The 7 Zones

    private var zonesPage: some View {
        VStack(spacing: DS.Spacing.s24) {
            Spacer()
            Text("Seven areas.\nOne picture.")
                .font(.title).fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Spacing.s12) {
                    ForEach(ZoneRegistry.all) { def in
                        VStack(alignment: .leading, spacing: DS.Spacing.s8) {
                            Image(systemName: def.iconName)
                                .font(.title2)
                                .foregroundStyle(def.color)
                            Text(def.name)
                                .font(.headline)
                            Text(def.tagline)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .frame(width: 120)
                        .padding(DS.Spacing.s16)
                        .background(.background, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
                    }
                }
                .padding(.horizontal)
            }

            Spacer()
            pageButton("Next") { withAnimation { page = 2 } }
        }
        .padding(.bottom, DS.Spacing.s48)
    }

    // MARK: - Page 3: Schedule

    private var schedulePage: some View {
        VStack(spacing: DS.Spacing.s24) {
            Spacer()

            VStack(spacing: DS.Spacing.s8) {
                Text("When should we\nremind you?")
                    .font(.title).fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text("A Sunday evening ritual.\nOr whenever works for you.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            Picker("Day", selection: $checkInDay) {
                ForEach(0..<7) { i in
                    Text(dayName(i)).tag(i)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 100)

            Picker("Time", selection: $checkInHour) {
                ForEach(6..<23) { h in
                    Text(timeLabel(h)).tag(h)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 100)

            Toggle("Enable reminders", isOn: Binding(
                get: { notificationsGranted },
                set: { enabled in
                    if enabled {
                        Task {
                            notificationsGranted = await NotificationScheduler.shared.requestPermission()
                        }
                    } else {
                        NotificationScheduler.shared.cancelReminder()
                        notificationsGranted = false
                    }
                }
            ))
            .padding(.horizontal, DS.Spacing.s32)

            Spacer()
            pageButton("Next") { withAnimation { page = 3 } }
        }
        .padding(.bottom, DS.Spacing.s48)
    }

    // MARK: - Page 4: First check-in

    private var firstCheckInPage: some View {
        VStack(spacing: DS.Spacing.s16) {
            Text("Where are you\nright now?")
                .font(.title).fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.top, DS.Spacing.s48)

            ScrollView {
                VStack(spacing: DS.Spacing.s8) {
                    ForEach(ZoneRegistry.all) { def in
                        compactZoneRow(def: def)
                    }
                }
                .padding(.horizontal)
            }

            pageButton("Begin", color: Color(hex: "#1D9E75")) {
                saveAndFinish()
            }
            .padding(.bottom, DS.Spacing.s48)
        }
    }

    private func compactZoneRow(def: ZoneDefinition) -> some View {
        HStack(spacing: DS.Spacing.s12) {
            Image(systemName: def.iconName)
                .foregroundStyle(def.color)
                .frame(width: 24)
            Text(def.name)
                .font(.subheadline)
            Spacer()
            Text("\(scores[def.id] ?? 5)")
                .font(.headline)
                .foregroundStyle(def.color)
                .frame(width: 28)
            Slider(value: Binding(
                get: { Double(scores[def.id] ?? 5) },
                set: { scores[def.id] = Int($0.rounded()) }
            ), in: 1...10, step: 1)
            .tint(def.color)
            .frame(width: 120)
        }
        .padding(DS.Spacing.s12)
        .background(.background, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    // MARK: - Helpers

    private func pageButton(_ title: String, color: Color = Color(hex: "#1D9E75"), action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(color)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg))
        }
        .padding(.horizontal, DS.Spacing.s32)
    }

    private func dayName(_ i: Int) -> String {
        ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"][i]
    }

    private func timeLabel(_ h: Int) -> String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"
        var comps = DateComponents(); comps.hour = h; comps.minute = 0
        return Calendar.current.date(from: comps).map { f.string(from: $0) } ?? "\(h):00"
    }

    private func saveAndFinish() {
        let service = CheckInService(modelContext: modelContext)
        let tags: [ZoneID: String] = [:]
        let notes: [ZoneID: String] = [:]
        _ = try? service.save(scores: scores, tags: tags, notes: notes)

        // Save preferences
        let prefs = UserPreferences()
        prefs.checkInDayOfWeek = checkInDay
        prefs.checkInHour = checkInHour
        prefs.notificationsEnabled = notificationsGranted
        prefs.onboardingComplete = true
        modelContext.insert(prefs)
        try? modelContext.save()

        if notificationsGranted {
            Task {
                await NotificationScheduler.shared.scheduleWeeklyReminder(
                    dayOfWeek: checkInDay, hour: checkInHour
                )
            }
        }

        onComplete()
    }
}
