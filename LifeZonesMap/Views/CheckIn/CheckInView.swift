import SwiftUI
import SwiftData

struct CheckInView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = CheckInViewModel()
    @State private var ratedZones: Set<ZoneID> = []
    @State private var showingSummary = false
    @State private var showingReflection = false

    @Query(sort: \WeeklyCheckIn.weekStartDate, order: .reverse) private var history: [WeeklyCheckIn]

    private var prefs: UserPreferences? {
        try? modelContext.fetch(FetchDescriptor<UserPreferences>()).first
    }

    /// Returns the user's most-frequently used custom tags for a zone,
    /// sorted by frequency. Skips any tag that's already in the seed set.
    private func personalTags(for zone: ZoneID) -> [String] {
        let defaults = Set(ZoneRegistry.definition(for: zone).exampleTags)
        var counts: [String: Int] = [:]
        for c in history {
            if let t = c.tag(for: zone), !t.isEmpty, !defaults.contains(t) {
                counts[t, default: 0] += 1
            }
        }
        return counts.sorted { $0.value > $1.value }.map(\.key)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if vm.alreadyCheckedIn, let existing = vm.existingCheckIn {
                    AlreadyCheckedInView(checkIn: existing)
                } else {
                    checkInScroll
                }
            }
            .background(LZ.paper.ignoresSafeArea())

            if !vm.alreadyCheckedIn {
                floatingCTA
            }
        }
        .onAppear { vm.setup(modelContext: modelContext) }
        .sheet(isPresented: $showingSummary, onDismiss: {
            // After they close the summary, surface a one-question reflection.
            if vm.submittedCheckIn != nil {
                showingReflection = true
            }
        }) {
            if let checkIn = vm.submittedCheckIn {
                CheckInSummaryView(checkIn: checkIn)
            }
        }
        .sheet(isPresented: $showingReflection) {
            if let checkIn = vm.submittedCheckIn {
                ReflectionPromptView(checkIn: checkIn) {
                    showingReflection = false
                }
            }
        }
    }

    // MARK: - Scroll content

    private var checkInScroll: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 24)
                    .padding(.top, DS.Spacing.s8)
                    .padding(.bottom, 6)

                VStack(spacing: 12) {
                    ForEach(ZoneRegistry.all) { def in
                        ZoneCard(
                            definition: def,
                            score:       scoreBinding(for: def.id),
                            selectedTag: tagBinding(for: def.id),
                            note:        noteBinding(for: def.id),
                            hapticsEnabled: prefs?.enableHaptics ?? true,
                            rated: ratedZones.contains(def.id),
                            personalTags: personalTags(for: def.id)
                        )
                        .padding(.horizontal, 18)
                    }
                }
                .padding(.top, 14)
                .padding(.bottom, 140)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(todayLabel()).uppercaseCaption()
            Text("A quiet half-hour with yourself.")
                .font(.system(size: 26, weight: .medium))
                .tracking(-0.57)
                .lineSpacing(2)
                .foregroundStyle(LZ.ink)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(hex: "#E5DAC0")).frame(height: 3)
                        Capsule()
                            .fill(LZ.tealDeep)
                            .frame(width: geo.size.width * CGFloat(ratedZones.count) / 7, height: 3)
                            .animation(DS.Anim.spring, value: ratedZones.count)
                    }
                }
                .frame(height: 3)
                Text("\(ratedZones.count) / 7")
                    .font(.system(size: 11, weight: .semibold).monospacedDigit())
                    .foregroundStyle(LZ.inkMute)
            }
            .padding(.top, 4)
        }
    }

    private func todayLabel() -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: Date())
    }

    // MARK: - Floating bottom CTA

    private var floatingCTA: some View {
        let remaining = 7 - ratedZones.count
        let ready = remaining == 0

        return HStack {
            Text(ready ? "Save this week" : "Save this week")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(ready ? LZ.cream : LZ.cream.opacity(0.95))
            Spacer()
            Text(ready ? "Ready" : "\(remaining) zone\(remaining == 1 ? "" : "s") to go")
                .font(.system(size: 11, weight: .medium))
                .tracking(0.66)
                .foregroundStyle(LZ.cream.opacity(0.85))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ready ? LZ.tealDeep : Color(hex: "#C9C0AB"))
                .shadow(color: ready ? LZ.tealDeep.opacity(0.20) : .clear, radius: 12, y: 4)
        )
        .padding(.horizontal, 18)
        .padding(.bottom, 24)
        .opacity(ready ? 1.0 : 0.92)
        .onTapGesture {
            guard ready, !vm.isSubmitting else { return }
            Task {
                await vm.submit(modelContext: modelContext)
                if vm.submittedCheckIn != nil { showingSummary = true }
            }
        }
    }

    // MARK: - Bindings

    private func scoreBinding(for id: ZoneID) -> Binding<Int> {
        Binding(
            get: { vm.scores[id] ?? 5 },
            set: {
                vm.setScore($0, for: id)
                ratedZones.insert(id)
            }
        )
    }

    private func tagBinding(for id: ZoneID) -> Binding<String?> {
        Binding(
            get: { vm.tags[id] },
            set: { vm.tags[id] = $0 }
        )
    }

    private func noteBinding(for id: ZoneID) -> Binding<String> {
        Binding(
            get: { vm.notes[id] ?? "" },
            set: { vm.notes[id] = $0 }
        )
    }
}

// MARK: - Already checked in

struct AlreadyCheckedInView: View {
    let checkIn: WeeklyCheckIn

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 10) {
                    IconMark(size: 56, color: LZ.tealDeep, bg: LZ.cream, rounded: 12)
                    Text("THIS WEEK").uppercaseCaption()
                    Text("Saved.")
                        .font(.system(size: 32, weight: .medium))
                        .tracking(-0.7)
                        .foregroundStyle(LZ.ink)
                    Text(checkIn.weekStartDate.isoWeekLabel)
                        .font(LZType.serifItalic(14))
                        .foregroundStyle(LZ.inkSoft)
                }
                .padding(.top, 36)

                VStack(spacing: 0) {
                    ForEach(Array(ZoneRegistry.all.enumerated()), id: \.element.id) { idx, def in
                        ZoneRow(
                            definition: def,
                            score: checkIn.score(for: def.id),
                            isLast: idx == ZoneRegistry.all.count - 1
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
            .padding(.bottom, 100)
        }
    }
}
