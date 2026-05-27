import SwiftUI
import SwiftData

struct CheckInSummaryView: View {
    let checkIn: WeeklyCheckIn
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var deltas: [ZoneID: Int] = [:]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerCard
                    deltaList
                }
                .padding(.bottom, 32)
            }
            .background(LZ.paper.ignoresSafeArea())
            .navigationTitle("This week")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(LZ.tealDeep)
                }
            }
        }
        .onAppear(perform: loadDeltas)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Saved").uppercaseCaption()
            Text("Your map is updated.")
                .font(.system(size: 26, weight: .medium))
                .tracking(-0.57)
                .foregroundStyle(LZ.ink)
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("Overall avg")
                    .font(.system(size: 12))
                    .foregroundStyle(LZ.inkMute)
                Text(String(format: "%.1f", checkIn.overallAverage))
                    .font(.system(size: 32, weight: .light).monospacedDigit())
                    .tracking(-0.6)
                    .foregroundStyle(LZ.ink)
                Spacer()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(LZ.cream)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
        .padding(.horizontal, 18)
        .padding(.top, 12)
    }

    private var deltaList: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Changes from last week").uppercaseCaption()
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            VStack(spacing: 0) {
                ForEach(Array(ZoneRegistry.all.enumerated()), id: \.element.id) { idx, def in
                    HStack(spacing: 12) {
                        ZoneGlyph(glyph: def.glyph, size: 17, stroke: 1.6)
                            .foregroundStyle(def.color)
                            .frame(width: 22)
                        Text(def.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(LZ.ink)
                        Spacer()
                        Text("\(checkIn.score(for: def.id))")
                            .font(.system(size: 15, weight: .medium).monospacedDigit())
                            .foregroundStyle(LZ.ink)
                        if let delta = deltas[def.id], delta != 0 {
                            DeltaChip(delta: delta)
                        }
                    }
                    .padding(.vertical, 12)

                    if idx != ZoneRegistry.all.count - 1 {
                        Rectangle().fill(LZ.ruleSoft).frame(height: 0.5)
                    }
                }
            }
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
            )
            .padding(.horizontal, 18)
        }
    }

    private func loadDeltas() {
        let service = CheckInService(modelContext: modelContext)
        for zone in ZoneID.allCases {
            deltas[zone] = try? service.deltaFromLastWeek(for: zone, current: checkIn)
        }
    }
}

struct DeltaChip: View {
    let delta: Int
    var body: some View {
        let positive = delta > 0
        let accent: Color = positive ? LZ.zGrowth : LZ.zVitality
        return HStack(spacing: 2) {
            Image(systemName: positive ? "arrow.up" : "arrow.down")
                .font(.system(size: 8, weight: .bold))
            Text("\(abs(delta))")
                .font(.system(size: 10, weight: .semibold).monospacedDigit())
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Capsule().fill(accent.opacity(0.12)))
        .foregroundStyle(accent)
    }
}
