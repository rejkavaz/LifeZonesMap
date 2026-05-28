import SwiftUI
import SwiftData

struct PulseView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = PulseViewModel()
    @State private var showYearOverview = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 24)
                        .padding(.top, 6)
                        .padding(.bottom, 8)

                    if vm.isLoading {
                        ProgressView().padding(.top, 60).tint(LZ.tealDeep)
                    } else if vm.checkIns.isEmpty {
                        emptyState
                    } else {
                        content
                    }
                }
                .padding(.bottom, 100)
            }
            .background(LZ.paper.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        YearOverviewView()
                    } label: {
                        Image(systemName: "square.grid.3x3")
                            .foregroundStyle(LZ.tealDeep)
                    }
                    .accessibilityLabel("Year overview")
                }
            }
        }
        .onAppear { vm.load(modelContext: modelContext) }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Pulse Report").uppercaseCaption()
            HStack(alignment: .firstTextBaseline) {
                Text(vm.periodLabel.isEmpty ? "—" : monthName(vm.periodLabel))
                    .font(.system(size: 30, weight: .medium))
                    .tracking(-0.66)
                    .foregroundStyle(LZ.ink)
                Spacer()
                Text("\(vm.checkIns.count) check-in\(vm.checkIns.count == 1 ? "" : "s") · \(currentYear())")
                    .font(.system(size: 12))
                    .foregroundStyle(LZ.inkMute)
            }
            .padding(.top, 4)
        }
    }

    private func monthName(_ s: String) -> String {
        s.components(separatedBy: " ").first ?? s
    }
    private func currentYear() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy"; return f.string(from: Date())
    }

    // MARK: - Body content

    private var content: some View {
        VStack(spacing: 0) {
            // Stat cards
            HStack(spacing: 8) {
                StatCard(
                    label: "Avg score",
                    value: String(format: "%.1f", vm.overallAverage),
                    sub: "of 10"
                )
                if let (zone, delta) = vm.mostImprovedZone, delta > 0 {
                    StatCard(
                        label: "Most improved",
                        value: ZoneRegistry.definition(for: zone).name,
                        sub: "+\(delta)",
                        trendUp: true,
                        color: ZoneRegistry.definition(for: zone).color
                    )
                }
                if let (zone, sigma) = vm.mostConsistentZone {
                    StatCard(
                        label: "Most consistent",
                        value: ZoneRegistry.definition(for: zone).name,
                        sub: String(format: "σ %.1f", sigma),
                        color: ZoneRegistry.definition(for: zone).color
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)

            // Trend chart
            sectionTitle("Across the month")
            TrendChartView(checkIns: vm.checkIns)
                .padding(.horizontal, 18)

            // Insight feed
            sectionTitle("What we noticed")
            InsightFeedView(
                insights: vm.insights,
                onDismiss: { vm.dismiss(insight: $0) }
            )

            // Reflection feed — recent saved responses to the post-checkin prompt
            sectionTitle("In your own words")
            ReflectionFeedView(limit: 3)

            // Zone connections
            if vm.checkIns.count >= 4 {
                sectionTitle("How your zones move together")
                ZoneConnectionsView(
                    correlationStrength: { vm.correlationStrength(between: $0, and: $1) }
                )
                .padding(.horizontal, 18)
            }
        }
    }

    private func sectionTitle(_ s: String) -> some View {
        HStack {
            SectionTitle(text: s)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 14) {
            ZoneGlyph(glyph: .focus, size: 38, stroke: 1.4)
                .foregroundStyle(LZ.inkMute.opacity(0.45))
            Text("Your pulse will appear after 2 check-ins.")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(LZ.ink)
                .multilineTextAlignment(.center)
            Text("Quiet reflection compounds. We're patient.")
                .font(LZType.serifItalic(13))
                .foregroundStyle(LZ.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 80)
        .padding(.horizontal, 32)
    }
}

// MARK: - Stat card

struct StatCard: View {
    let label: String
    let value: String
    let sub: String
    var trendUp: Bool = false
    var color: Color = LZ.ink

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).uppercaseCaption(size: 9.5, tracking: 1.9)
            Text(value)
                .font(.system(size: value.count > 6 ? 14 : 20, weight: .medium))
                .tracking(-0.24)
                .foregroundStyle(color)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
            HStack(spacing: 4) {
                if trendUp {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(color)
                }
                Text(sub)
                    .font(.system(size: 10.5).monospacedDigit())
                    .foregroundStyle(LZ.inkSoft)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(LZ.cream)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
    }
}
