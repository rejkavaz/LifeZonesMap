import SwiftUI
import SwiftData

struct CheckInView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = CheckInViewModel()
    @State private var showingSummary = false

    private var prefs: UserPreferences? {
        try? modelContext.fetch(FetchDescriptor<UserPreferences>()).first
    }

    var body: some View {
        NavigationStack {
            Group {
                if vm.alreadyCheckedIn, let existing = vm.existingCheckIn {
                    AlreadyCheckedInView(checkIn: existing)
                } else {
                    checkInForm
                }
            }
            .navigationTitle("Check In")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear { vm.setup(modelContext: modelContext) }
        .sheet(isPresented: $showingSummary) {
            if let checkIn = vm.submittedCheckIn {
                CheckInSummaryView(checkIn: checkIn)
            }
        }
    }

    private var checkInForm: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.s12) {
                weekHeader
                    .padding(.horizontal)

                ForEach(ZoneRegistry.all) { def in
                    ZoneCard(
                        definition: def,
                        score:       scoreBinding(for: def.id),
                        selectedTag: tagBinding(for: def.id),
                        note:        noteBinding(for: def.id),
                        hapticsEnabled: prefs?.enableHaptics ?? true
                    )
                    .padding(.horizontal)
                }

                submitButton
                    .padding()
            }
            .padding(.bottom, DS.Spacing.s32)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var weekHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date().isoWeekLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Rate each zone 1–10")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.top, DS.Spacing.s8)
    }

    private var submitButton: some View {
        Button {
            Task { await vm.submit(modelContext: modelContext) }
            showingSummary = vm.submittedCheckIn != nil
        } label: {
            Group {
                if vm.isSubmitting {
                    ProgressView().tint(.white)
                } else {
                    Text("Save this week")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(vm.allZonesRated ? Color(hex: "#1D9E75") : Color(.systemGray4))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg))
        }
        .disabled(!vm.allZonesRated || vm.isSubmitting)
        .animation(DS.Anim.spring, value: vm.allZonesRated)
    }

    // MARK: - Bindings

    private func scoreBinding(for id: ZoneID) -> Binding<Int> {
        Binding(
            get: { vm.scores[id] ?? 5 },
            set: { vm.setScore($0, for: id) }
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

struct AlreadyCheckedInView: View {
    let checkIn: WeeklyCheckIn

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.s16) {
                VStack(spacing: DS.Spacing.s8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color(hex: "#1D9E75"))
                    Text("This week's check-in is saved.")
                        .font(.headline)
                    Text(checkIn.weekStartDate.isoWeekLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)

                ForEach(ZoneRegistry.all) { def in
                    HStack {
                        Image(systemName: def.iconName)
                            .foregroundStyle(def.color)
                        Text(def.name)
                            .font(.subheadline)
                        Spacer()
                        Text("\(checkIn.score(for: def.id))")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(def.color)
                    }
                    .padding()
                    .background(.background, in: RoundedRectangle(cornerRadius: DS.Radius.md))
                    .padding(.horizontal)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}
