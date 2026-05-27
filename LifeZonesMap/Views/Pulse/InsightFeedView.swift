import SwiftUI

struct InsightFeedView: View {
    let insights: [ZoneInsight]
    var onDismiss: (ZoneInsight) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s8) {
            Text("Insights")
                .font(.headline)
                .padding(.horizontal)

            if insights.isEmpty {
                emptyState
            } else {
                ForEach(insights.filter { !$0.dismissed }, id: \.id) { insight in
                    InsightCard(insight: insight, onDismiss: { onDismiss(insight) })
                        .padding(.horizontal)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.s8) {
            Image(systemName: "chart.xyaxis.line")
                .font(.title)
                .foregroundStyle(.quaternary)
            Text("Check in 3 more times to unlock pattern insights.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(DS.Spacing.s32)
        .background(.background, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
        .padding(.horizontal)
    }
}

struct InsightCard: View {
    let insight: ZoneInsight
    var onDismiss: () -> Void

    private var accentColor: Color {
        switch insight.type {
        case .warning:     return Color(hex: "#BA7517")
        case .positive:    return Color(hex: "#639922")
        case .correlation: return Color(hex: "#378ADD")
        case .trend:       return Color(hex: "#7F77DD")
        }
    }

    private var iconName: String {
        switch insight.type {
        case .warning:     return "exclamationmark.triangle.fill"
        case .positive:    return "arrow.up.circle.fill"
        case .correlation: return "arrow.left.arrow.right.circle.fill"
        case .trend:       return "chart.line.uptrend.xyaxis.circle.fill"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(accentColor)
                .frame(width: 4)

            HStack(alignment: .top, spacing: DS.Spacing.s12) {
                Image(systemName: iconName)
                    .foregroundStyle(accentColor)
                    .font(.title3)

                Text(insight.body)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Button {
                    withAnimation(DS.Anim.sheet) { onDismiss() }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(DS.Spacing.s16)
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.lg)
                .strokeBorder(.separator, lineWidth: 0.5)
        )
    }
}
