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
                VStack(spacing: DS.Spacing.s24) {
                    // Header
                    VStack(spacing: DS.Spacing.s8) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color(hex: "#1D9E75"))
                        Text("Map updated")
                            .font(.title2).fontWeight(.semibold)
                        Text(checkIn.weekStartDate.isoWeekLabel)
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.top)

                    // Overall score
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Overall")
                                .font(.caption).foregroundStyle(.secondary)
                            Text(String(format: "%.1f", checkIn.overallAverage))
                                .font(.system(size: 48, weight: .thin))
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(hex: "#1D9E75").opacity(0.08), in: RoundedRectangle(cornerRadius: DS.Radius.lg))
                    .padding(.horizontal)

                    // Per-zone deltas
                    VStack(spacing: DS.Spacing.s8) {
                        Text("Changes from last week")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        ForEach(ZoneRegistry.all) { def in
                            deltaRow(def: def)
                        }
                    }
                }
                .padding(.bottom, DS.Spacing.s32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("This week")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear { loadDeltas() }
    }

    private func deltaRow(def: ZoneDefinition) -> some View {
        HStack {
            Image(systemName: def.iconName).foregroundStyle(def.color)
            Text(def.name).font(.subheadline)
            Spacer()
            Text("\(checkIn.score(for: def.id))").font(.subheadline).fontWeight(.medium)
            if let delta = deltas[def.id] {
                deltaChip(delta)
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .padding(.horizontal)
    }

    private func deltaChip(_ delta: Int) -> some View {
        let positive = delta >= 0
        return Text(delta == 0 ? "–" : (positive ? "+\(delta)" : "\(delta)"))
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, DS.Spacing.s8)
            .padding(.vertical, DS.Spacing.s4)
            .background((positive ? Color.green : Color.red).opacity(0.15), in: Capsule())
            .foregroundStyle(positive ? .green : .red)
    }

    private func loadDeltas() {
        let service = CheckInService(modelContext: modelContext)
        for zone in ZoneID.allCases {
            deltas[zone] = try? service.deltaFromLastWeek(for: zone, current: checkIn)
        }
    }
}
