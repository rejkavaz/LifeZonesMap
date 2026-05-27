import SwiftUI
import Charts

struct TrendChartView: View {
    let checkIns: [WeeklyCheckIn]

    private let df: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "M/d"; return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s8) {
            Text("Trends")
                .font(.headline)

            Chart {
                ForEach(ZoneID.allCases) { zone in
                    let def = ZoneRegistry.definition(for: zone)
                    ForEach(checkIns, id: \.weekStartDate) { checkIn in
                        LineMark(
                            x: .value("Week", checkIn.weekStartDate),
                            y: .value("Score", checkIn.score(for: zone)),
                            series: .value("Zone", def.name)
                        )
                        .foregroundStyle(def.color)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                    }
                }
            }
            .chartYScale(domain: 0...10)
            .chartYAxis {
                AxisMarks(values: [0, 2, 4, 6, 8, 10]) { val in
                    AxisValueLabel()
                        .font(.caption2)
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                }
            }
            .chartXAxis {
                AxisMarks(values: checkIns.map(\.weekStartDate)) { val in
                    if let date = val.as(Date.self) {
                        AxisValueLabel {
                            Text(df.string(from: date))
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 200)

            // Legend
            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: DS.Spacing.s4) {
                ForEach(ZoneRegistry.all) { def in
                    HStack(spacing: 4) {
                        Circle().fill(def.color).frame(width: 8, height: 8)
                        Text(def.name).font(.caption2).lineLimit(1)
                    }
                }
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
    }
}
