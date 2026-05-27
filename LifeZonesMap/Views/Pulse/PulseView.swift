import SwiftUI
import SwiftData

struct PulseView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = PulseViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.checkIns.isEmpty {
                    emptyState
                } else {
                    pulseContent
                }
            }
            .navigationTitle("Pulse")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !vm.checkIns.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ShareLink(
                            item: ExportService().exportJSON(checkIns: vm.checkIns),
                            preview: SharePreview("Life Zones Export", image: Image(systemName: "map.fill"))
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
        .onAppear { vm.load(modelContext: modelContext) }
    }

    // MARK: - Content

    private var pulseContent: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.s16) {
                // Period header
                periodHeader
                    .padding(.horizontal)

                // Stat row
                if vm.checkIns.count >= 2 {
                    statsRow.padding(.horizontal)
                }

                // Trend chart
                if vm.checkIns.count >= 2 {
                    TrendChartView(checkIns: vm.checkIns)
                        .padding(.horizontal)
                }

                // Insight feed
                InsightFeedView(
                    insights: vm.insights,
                    onDismiss: { vm.dismiss(insight: $0) }
                )

                // Zone connections
                if vm.checkIns.count >= 4 {
                    ZoneConnectionsView(correlationStrength: { vm.correlationStrength(between: $0, and: $1) })
                        .padding(.horizontal)
                }

                // Reflection prompt
                reflectionCard
                    .padding(.horizontal)
            }
            .padding(.bottom, DS.Spacing.s32)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var periodHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.periodLabel)
                    .font(.title2).fontWeight(.semibold)
                Text("\(vm.checkIns.count) check-in\(vm.checkIns.count == 1 ? "" : "s")")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var statsRow: some View {
        HStack(spacing: DS.Spacing.s12) {
            StatCard(
                label: "Overall avg",
                value: String(format: "%.1f", vm.overallAverage),
                icon: "chart.bar.fill",
                color: Color(hex: "#1D9E75")
            )
            if let (zone, delta) = vm.mostImprovedZone {
                StatCard(
                    label: "Most improved",
                    value: ZoneRegistry.definition(for: zone).name,
                    icon: "arrow.up.circle.fill",
                    color: ZoneRegistry.definition(for: zone).color
                )
            }
            if let (zone, _) = vm.mostConsistentZone {
                StatCard(
                    label: "Most consistent",
                    value: ZoneRegistry.definition(for: zone).name,
                    icon: "minus.circle.fill",
                    color: ZoneRegistry.definition(for: zone).color
                )
            }
        }
    }

    private var reflectionCard: some View {
        let zone = vm.mostImprovedZone?.0 ?? .vitality
        let def  = ZoneRegistry.definition(for: zone)
        return VStack(alignment: .leading, spacing: DS.Spacing.s8) {
            Label("Reflection", systemImage: "quote.bubble.fill")
                .font(.headline)
                .foregroundStyle(def.color)
            Text("What would it look like if \(def.name) was 2 points higher next week?")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(def.color.opacity(0.08), in: RoundedRectangle(cornerRadius: DS.Radius.lg))
    }

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.s16) {
            Spacer()
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 56))
                .foregroundStyle(.quaternary)
            Text("Your pulse will appear after 2 check-ins.")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("Check in weekly to surface patterns and insights.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }
}

struct StatCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.s12)
        .background(.background, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }
}
