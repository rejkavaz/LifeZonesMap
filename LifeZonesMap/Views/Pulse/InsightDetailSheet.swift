import SwiftUI
import SwiftData
import Charts

/// Tap any insight card on Pulse → this sheet opens, showing the underlying
/// data that produced the insight. Builds trust in the pattern engine and
/// teaches the user to read their own numbers.
struct InsightDetailSheet: View {
    let insight: ZoneInsight
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WeeklyCheckIn.weekStartDate, order: .reverse) private var allCheckIns: [WeeklyCheckIn]

    private var zones: [ZoneID] {
        insight.zoneIDs.compactMap { ZoneID(rawValue: $0) }
    }

    /// Check-ins whose week falls inside the insight's range.
    private var relevantCheckIns: [WeeklyCheckIn] {
        let start = insight.weekRangeStart
        let end   = insight.weekRangeEnd
        return allCheckIns
            .filter { $0.weekStartDate >= start && $0.weekStartDate <= end }
            .sorted { $0.weekStartDate < $1.weekStartDate }
    }

    private var accent: Color {
        switch insight.type {
        case .warning:     return Color(hex: "#C19036")
        case .positive:    return LZ.zGrowth
        case .correlation: return LZ.zDeepWork
        case .trend:       return LZ.zInner
        }
    }

    private var label: String {
        switch insight.type {
        case .warning:     return "WATCH"
        case .positive:    return "LIFT"
        case .correlation: return "PATTERN"
        case .trend:       return "TREND"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    headerCard
                    explanationCard
                    if !relevantCheckIns.isEmpty {
                        chartCard
                        valuesCard
                    }
                    methodologyCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(LZ.paper.ignoresSafeArea())
            .navigationTitle("Why this insight?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(LZ.tealDeep)
                }
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).uppercaseCaption(color: accent)
            Text(insight.body)
                .font(.system(size: 17, weight: .medium))
                .lineSpacing(3)
                .foregroundStyle(LZ.ink)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(accent.opacity(0.3), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Explanation

    private var explanationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WHAT THE ENGINE SAW").uppercaseCaption()
            Text(explanationText)
                .font(LZType.serifItalic(14))
                .lineSpacing(2.5)
                .foregroundStyle(LZ.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LZ.cream)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var explanationText: String {
        switch insight.type {
        case .correlation:
            if zones.count == 2 {
                return "Across the weeks below, the engine looked at the per-week scores for \(zoneName(zones[0])) and \(zoneName(zones[1])) and computed their Pearson correlation. A coefficient above 0.65 (or below −0.65) is meaningful enough to flag."
            }
            return "The engine compared your zone scores week-over-week and noticed a relationship strong enough to flag."
        case .trend:
            if !zones.isEmpty {
                return "\(zoneName(zones[0])) showed a linear slope across the last 4 weeks above the noise threshold. The chart below shows the actual values; the slope is what produced this insight."
            }
            return "The engine fit a linear trend across recent check-ins and the slope was strong enough to call out."
        case .warning:
            return "Multiple zones moved in a direction worth noticing. The chart below shows the actual scores so you can see what the engine saw."
        case .positive:
            return "Recent scores moved in a direction worth naming. The chart below shows what made the engine surface this."
        }
    }

    // MARK: - Chart

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("THE NUMBERS").uppercaseCaption()
            Chart {
                ForEach(zones, id: \.self) { zone in
                    let def = ZoneRegistry.definition(for: zone)
                    ForEach(relevantCheckIns, id: \.weekStartDate) { c in
                        LineMark(
                            x: .value("Week", c.weekStartDate),
                            y: .value("Score", c.score(for: zone))
                        )
                        .foregroundStyle(def.color)
                        .lineStyle(StrokeStyle(lineWidth: 2.4))
                        .interpolationMethod(.catmullRom)
                        PointMark(
                            x: .value("Week", c.weekStartDate),
                            y: .value("Score", c.score(for: zone))
                        )
                        .foregroundStyle(def.color)
                        .symbolSize(36)
                    }
                }
            }
            .chartYScale(domain: 0...10)
            .chartYAxis {
                AxisMarks(values: [0, 5, 10]) { _ in
                    AxisValueLabel().font(.caption2)
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { val in
                    if let d = val.as(Date.self) {
                        AxisValueLabel {
                            Text(d, format: .dateTime.month(.abbreviated).day())
                                .font(.system(size: 9))
                        }
                    }
                }
            }
            .frame(height: 200)
            HStack(spacing: 12) {
                ForEach(zones, id: \.self) { zone in
                    let def = ZoneRegistry.definition(for: zone)
                    HStack(spacing: 5) {
                        Capsule().fill(def.color).frame(width: 12, height: 2)
                        Text(def.name)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(LZ.inkSoft)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Values table

    private var valuesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WEEK-BY-WEEK").uppercaseCaption()
            VStack(spacing: 6) {
                ForEach(relevantCheckIns, id: \.weekStartDate) { c in
                    HStack {
                        Text(c.weekStartDate.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.system(size: 12).monospacedDigit())
                            .foregroundStyle(LZ.inkSoft)
                        Spacer()
                        ForEach(zones, id: \.self) { zone in
                            let def = ZoneRegistry.definition(for: zone)
                            HStack(spacing: 3) {
                                Circle().fill(def.color).frame(width: 5, height: 5)
                                Text("\(c.score(for: zone))")
                                    .font(.system(size: 13, weight: .medium).monospacedDigit())
                                    .foregroundStyle(LZ.ink)
                            }
                            .padding(.leading, 8)
                        }
                    }
                    .padding(.vertical, 4)
                    if c.weekStartDate != relevantCheckIns.last?.weekStartDate {
                        Rectangle().fill(LZ.ruleSoft).frame(height: 0.5)
                    }
                }
            }
        }
        .padding(14)
        .background(LZ.cream)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Methodology

    private var methodologyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HOW IT'S COMPUTED").uppercaseCaption()
            Text(methodologyText)
                .font(.system(size: 12.5))
                .lineSpacing(2)
                .foregroundStyle(LZ.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var methodologyText: String {
        switch insight.type {
        case .correlation:
            return "Pearson product-moment correlation coefficient computed over your last ≥4 weeks. Threshold |r| > 0.65 to flag. Drain insights (special case of correlation) require a zone's score ≥ 8 while another drops ≥ 2 in the same week, repeated ≥ 2 times."
        case .trend:
            return "Linear regression slope across the last 4 weeks. Threshold |slope| > 0.8 score-points per week to surface as a trend. Weekday patterns require 3+ check-ins on a given weekday differing ≥ 1.0 from the global mean."
        case .warning:
            return "Recovery warnings fire when 5+ of 7 zones are below 5 in the same check-in. Trend warnings use linear regression with slope < −0.8."
        case .positive:
            return "Lift insights use linear regression with slope > 0.8 OR — for the self-compassion variant — fire when 3+ zones drop 2+ points week-over-week (the kind framing is intentional, not algorithmic celebration)."
        }
    }

    private func zoneName(_ z: ZoneID) -> String {
        ZoneRegistry.definition(for: z).name
    }
}
