import SwiftUI
import Charts

struct ZoneHistoryView: View {
    let scores: [(Date, Int)]
    let color: Color

    var body: some View {
        Chart {
            ForEach(scores, id: \.0) { date, score in
                AreaMark(
                    x: .value("Week", date),
                    y: .value("Score", score)
                )
                .foregroundStyle(color.opacity(0.15))
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Week", date),
                    y: .value("Score", score)
                )
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Week", date),
                    y: .value("Score", score)
                )
                .foregroundStyle(color)
                .symbolSize(30)
            }
        }
        .chartYScale(domain: 0...10)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(values: [0, 5, 10]) { val in
                AxisValueLabel()
                    .font(.caption2)
            }
        }
    }
}
