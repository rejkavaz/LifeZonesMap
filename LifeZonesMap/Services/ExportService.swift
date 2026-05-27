import Foundation
import UIKit

final class ExportService {

    // MARK: - JSON

    func exportJSON(checkIns: [WeeklyCheckIn]) -> Data {
        let iso = ISO8601DateFormatter()
        let dicts: [[String: Any]] = checkIns.map { c in
            [
                "week_start": iso.string(from: c.weekStartDate),
                "created_at": iso.string(from: c.createdAt),
                "scores": c.scores,
                "tags":   c.tags,
                "notes":  c.notes
            ]
        }
        return (try? JSONSerialization.data(withJSONObject: dicts, options: [.prettyPrinted, .sortedKeys])) ?? Data()
    }

    // MARK: - CSV

    func exportCSV(checkIns: [WeeklyCheckIn]) -> Data {
        let zones = ZoneID.allCases
        var lines: [String] = []

        let header = (["week_start"] + zones.map(\.rawValue) + zones.map { "\($0.rawValue)_tag" }).joined(separator: ",")
        lines.append(header)

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        for c in checkIns.sorted(by: { $0.weekStartDate < $1.weekStartDate }) {
            var row = [df.string(from: c.weekStartDate)]
            row += zones.map { "\(c.score(for: $0))" }
            row += zones.map { c.tag(for: $0) ?? "" }
            lines.append(row.joined(separator: ","))
        }

        return lines.joined(separator: "\n").data(using: .utf8) ?? Data()
    }

    // MARK: - PDF Report

    func exportPDFReport(checkIns: [WeeklyCheckIn], insights: [ZoneInsight]) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { ctx in
            ctx.beginPage()
            let g = ctx.cgContext

            // Background
            UIColor.systemBackground.setFill()
            g.fill(pageRect)

            var y: CGFloat = 48

            // Header
            let titleAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .semibold),
                .foregroundColor: UIColor(red: 0.11, green: 0.62, blue: 0.46, alpha: 1)
            ]
            "Life Zones Map".draw(at: CGPoint(x: 48, y: y), withAttributes: titleAttr)
            y += 36

            // Date range
            if let first = checkIns.sorted(by: { $0.weekStartDate < $1.weekStartDate }).first,
               let last  = checkIns.sorted(by: { $0.weekStartDate < $1.weekStartDate }).last {
                let df = DateFormatter(); df.dateStyle = .medium
                let subtitle = "\(df.string(from: first.weekStartDate)) – \(df.string(from: last.weekStartDate))"
                let subAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.secondaryLabel
                ]
                subtitle.draw(at: CGPoint(x: 48, y: y), withAttributes: subAttr)
                y += 28
            }

            // Divider
            g.setStrokeColor(UIColor.separator.cgColor)
            g.setLineWidth(0.5)
            g.move(to: CGPoint(x: 48, y: y)); g.addLine(to: CGPoint(x: 564, y: y))
            g.strokePath()
            y += 20

            // Zone averages as bars
            let sectionAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
            "Zone Averages".draw(at: CGPoint(x: 48, y: y), withAttributes: sectionAttr)
            y += 20

            let barAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.label
            ]

            for zone in ZoneID.allCases {
                let def = ZoneRegistry.definition(for: zone)
                let scores = checkIns.map { Double($0.score(for: zone)) }
                let avg = scores.isEmpty ? 0 : scores.reduce(0,+) / Double(scores.count)
                let label = "\(def.name): \(String(format: "%.1f", avg))"
                label.draw(at: CGPoint(x: 48, y: y), withAttributes: barAttr)

                let barW = (avg / 10.0) * 300
                let barRect = CGRect(x: 160, y: y + 2, width: barW, height: 10)
                UIColor(def.color).setFill()
                UIBezierPath(roundedRect: barRect, cornerRadius: 3).fill()
                y += 20
            }

            y += 12

            // Top insights
            "Key Insights".draw(at: CGPoint(x: 48, y: y), withAttributes: sectionAttr)
            y += 20

            let bodyAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.secondaryLabel
            ]
            for insight in insights.prefix(3) where !insight.dismissed {
                let bullet = "• \(insight.body)"
                let nsStr = NSAttributedString(string: bullet, attributes: bodyAttr)
                let textRect = CGRect(x: 48, y: y, width: 516, height: 60)
                nsStr.draw(in: textRect)
                y += 36
            }

            // Footer
            let footerAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9),
                .foregroundColor: UIColor.tertiaryLabel
            ]
            "Generated by Life Zones Map — private & on-device".draw(
                at: CGPoint(x: 48, y: 756), withAttributes: footerAttr
            )
        }
    }
}
