import SwiftUI
import SwiftData

/// Scrollable list of every past check-in. Tap a row to view + edit.
struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeeklyCheckIn.weekStartDate, order: .reverse) private var checkIns: [WeeklyCheckIn]
    @State private var selected: WeeklyCheckIn?
    @State private var confirmingDelete: WeeklyCheckIn?

    var body: some View {
        Group {
            if checkIns.isEmpty {
                emptyState
            } else {
                List {
                    Section {
                        ForEach(checkIns) { checkIn in
                            Button { selected = checkIn } label: {
                                row(for: checkIn)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(LZ.paper)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    confirmingDelete = checkIn
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        Text("\(checkIns.count) week\(checkIns.count == 1 ? "" : "s")")
                            .uppercaseCaption()
                    }
                }
                .scrollContentBackground(.hidden)
                .background(LZ.paper)
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selected) { checkIn in
            HistoryDetailView(checkIn: checkIn)
        }
        .alert("Delete this week?", isPresented: Binding(
            get: { confirmingDelete != nil },
            set: { if !$0 { confirmingDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let c = confirmingDelete {
                    modelContext.delete(c)
                    try? modelContext.save()
                }
                confirmingDelete = nil
            }
            Button("Cancel", role: .cancel) { confirmingDelete = nil }
        } message: {
            Text("The check-in for this week will be permanently removed.")
        }
    }

    private func row(for checkIn: WeeklyCheckIn) -> some View {
        HStack(spacing: 14) {
            // Mini radar — 36pt
            RadarMap(
                scores: Dictionary(uniqueKeysWithValues: ZoneID.allCases.map { ($0, checkIn.score(for: $0)) }),
                animateReveal: false,   // don't pop one-by-one as the list scrolls
                size: 36,
                showNodes: false,
                showLabels: false,
                showGrid: false,
                fill: LZ.teal,
                fillOpacity: 0.18,
                stroke: LZ.tealDeep,
                dotRadius: 1
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(checkIn.weekStartDate.isoWeekLabel)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(LZ.ink)
                Text("Avg \(String(format: "%.1f", checkIn.overallAverage))")
                    .font(.system(size: 12).monospacedDigit())
                    .foregroundStyle(LZ.inkMute)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(LZ.inkMute)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            ZoneGlyph(glyph: .moon, size: 36, stroke: 1.5)
                .foregroundStyle(LZ.inkMute.opacity(0.5))
            Text("No check-ins yet.").font(.system(size: 16, weight: .medium))
            Text("Your first weekly check-in will show up here.")
                .font(LZType.serifItalic(13))
                .foregroundStyle(LZ.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LZ.paper)
    }
}

/// Read + edit a single past check-in.
struct HistoryDetailView: View {
    @Bindable var checkIn: WeeklyCheckIn
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var working: [ZoneID: Int] = [:]
    @State private var hasChanges = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(checkIn.weekStartDate.isoWeekLabel)
                            .uppercaseCaption()
                        Text("Edit this week")
                            .font(.system(size: 24, weight: .medium))
                            .tracking(-0.5)
                            .foregroundStyle(LZ.ink)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                    // Each zone with a slider
                    VStack(spacing: 0) {
                        ForEach(Array(ZoneRegistry.all.enumerated()), id: \.element.id) { idx, def in
                            zoneRow(def: def)
                            if idx != ZoneRegistry.all.count - 1 {
                                Rectangle().fill(LZ.ruleSoft).frame(height: 0.5)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal, 18)

                    Spacer(minLength: 32)
                }
            }
            .background(LZ.paper.ignoresSafeArea())
            .navigationTitle(checkIn.weekStartDate.isoWeekLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(LZ.inkSoft)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        commit(); dismiss()
                    }
                    .foregroundStyle(LZ.tealDeep)
                    .fontWeight(.semibold)
                    .disabled(!hasChanges)
                }
            }
        }
        .onAppear {
            working = Dictionary(uniqueKeysWithValues: ZoneID.allCases.map { ($0, checkIn.score(for: $0)) })
        }
    }

    private func zoneRow(def: ZoneDefinition) -> some View {
        HStack(spacing: 12) {
            ZoneGlyph(glyph: def.glyph, size: 18, stroke: 1.6)
                .foregroundStyle(def.color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(def.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(LZ.ink)
                    Spacer()
                    Text("\(working[def.id] ?? 5)")
                        .font(.system(size: 18, weight: .light).monospacedDigit())
                        .foregroundStyle(def.color)
                }
                CompactSlider(
                    color: def.color,
                    score: Binding(
                        get: { working[def.id] ?? 5 },
                        set: { working[def.id] = $0; hasChanges = true }
                    ),
                    rated: true
                )
                .frame(height: 14)
            }
        }
        .padding(.vertical, 12)
    }

    private func commit() {
        var newScores: [String: Int] = [:]
        for (zone, score) in working { newScores[zone.rawValue] = score }
        checkIn.scores = newScores
        try? modelContext.save()
        WidgetDataProvider.update(from: checkIn)
    }
}
