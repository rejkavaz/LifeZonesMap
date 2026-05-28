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

    // MARK: - PDF Report — designed to mirror the on-screen Pulse view

    func exportPDFReport(
        checkIns: [WeeklyCheckIn],
        insights: [ZoneInsight],
        reflections: [WeeklyReflection] = []
    ) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { ctx in
            ctx.beginPage()
            let g = ctx.cgContext

            // Cream background to match the app
            uiColor("#F2EBDC").setFill()
            g.fill(pageRect)

            let leftCol: CGFloat = 56
            let rightEdge: CGFloat = 556
            let contentWidth: CGFloat = rightEdge - leftCol
            var y: CGFloat = 60

            // ── Eyebrow + title ─────────────────────────────────────
            drawCaption("PULSE REPORT", at: CGPoint(x: leftCol, y: y))
            y += 18

            let monthLabel: String = {
                guard let latest = checkIns.max(by: { $0.weekStartDate < $1.weekStartDate }) else { return "—" }
                let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
                return f.string(from: latest.weekStartDate)
            }()
            drawText(monthLabel,
                     at: CGPoint(x: leftCol, y: y),
                     font: .systemFont(ofSize: 32, weight: .medium),
                     color: uiColor("#262320"))

            drawText("\(checkIns.count) check-in\(checkIns.count == 1 ? "" : "s")",
                     at: CGPoint(x: rightEdge, y: y + 12),
                     font: .systemFont(ofSize: 12),
                     color: uiColor("#9A9182"),
                     align: .right)

            y += 44

            // ── Stat cards row ──────────────────────────────────────
            let cardW = (contentWidth - 16) / 3
            let cardH: CGFloat = 78
            let avgAll: Double = {
                let all = checkIns.flatMap { $0.scores.values }
                return all.isEmpty ? 0 : Double(all.reduce(0, +)) / Double(all.count)
            }()
            let mostImproved = computeMostImproved(checkIns: checkIns)
            let mostConsistent = computeMostConsistent(checkIns: checkIns)

            drawStatCard(
                rect: CGRect(x: leftCol, y: y, width: cardW, height: cardH),
                label: "AVG SCORE", value: String(format: "%.1f", avgAll),
                sub: "of 10"
            )
            if let m = mostImproved {
                drawStatCard(
                    rect: CGRect(x: leftCol + cardW + 8, y: y, width: cardW, height: cardH),
                    label: "MOST IMPROVED", value: m.0,
                    sub: m.1 > 0 ? "+\(m.1)" : "\(m.1)",
                    color: zoneColor(m.2)
                )
            }
            if let c = mostConsistent {
                drawStatCard(
                    rect: CGRect(x: leftCol + (cardW + 8) * 2, y: y, width: cardW, height: cardH),
                    label: "MOST CONSISTENT", value: c.0,
                    sub: String(format: "σ %.1f", c.1),
                    color: zoneColor(c.2)
                )
            }
            y += cardH + 28

            // ── Trend chart ────────────────────────────────────────
            drawSectionRule("Across the period", y: y, leftCol: leftCol, rightEdge: rightEdge)
            y += 20

            let chartRect = CGRect(x: leftCol, y: y, width: contentWidth, height: 180)
            drawTrendChart(in: chartRect, checkIns: checkIns)
            y += chartRect.height + 8

            // Legend — 2 columns of 4
            let legendItemHeight: CGFloat = 16
            let legendCols: CGFloat = 2
            let legendColWidth = contentWidth / legendCols
            for (i, zone) in ZoneID.allCases.enumerated() {
                let col = i % Int(legendCols)
                let row = i / Int(legendCols)
                let x = leftCol + CGFloat(col) * legendColWidth
                let ly = y + CGFloat(row) * legendItemHeight
                drawLegendRow(zone: zone, x: x, y: ly, width: legendColWidth - 12, checkIns: checkIns)
            }
            y += CGFloat(Int(ceil(Double(ZoneID.allCases.count) / Double(legendCols)))) * legendItemHeight + 24

            // ── Insights ─────────────────────────────────────────────
            let topInsights = insights.filter { !$0.dismissed }.prefix(3)
            if !topInsights.isEmpty {
                drawSectionRule("What we noticed", y: y, leftCol: leftCol, rightEdge: rightEdge)
                y += 20
                for insight in topInsights {
                    y = drawInsightCard(insight: insight, x: leftCol, y: y, width: contentWidth)
                    y += 8
                }
                y += 12
            }

            // ── Reflections ──────────────────────────────────────────
            let topReflections = reflections.prefix(2)
            if !topReflections.isEmpty {
                drawSectionRule("In your own words", y: y, leftCol: leftCol, rightEdge: rightEdge)
                y += 20
                for r in topReflections {
                    y = drawReflectionCard(reflection: r, x: leftCol, y: y, width: contentWidth)
                    y += 8
                }
            }

            // ── Footer ───────────────────────────────────────────────
            drawText("Generated by Life Zones Map · private & on-device",
                     at: CGPoint(x: leftCol, y: 760),
                     font: .systemFont(ofSize: 9),
                     color: uiColor("#9A9182"))
            let datestamp = ISO8601DateFormatter().string(from: Date())
            drawText(datestamp,
                     at: CGPoint(x: rightEdge, y: 760),
                     font: .systemFont(ofSize: 9),
                     color: uiColor("#9A9182"),
                     align: .right)
        }
    }

    // MARK: - PDF building blocks

    private func drawStatCard(rect: CGRect, label: String, value: String, sub: String, color: UIColor? = nil) {
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.saveGState()
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 10)
        uiColor("#FAF6EB").setFill()
        path.fill()
        uiColor("#E6DEC9").setStroke()
        path.lineWidth = 0.5
        path.stroke()

        drawCaption(label, at: CGPoint(x: rect.minX + 10, y: rect.minY + 10))
        drawText(value,
                 at: CGPoint(x: rect.minX + 10, y: rect.minY + 30),
                 font: .systemFont(ofSize: value.count > 8 ? 14 : 18, weight: .medium),
                 color: color ?? uiColor("#262320"))
        drawText(sub,
                 at: CGPoint(x: rect.minX + 10, y: rect.minY + rect.height - 18),
                 font: .monospacedDigitSystemFont(ofSize: 10, weight: .regular),
                 color: uiColor("#5B554A"))
        ctx.restoreGState()
    }

    private func drawSectionRule(_ text: String, y: CGFloat, leftCol: CGFloat, rightEdge: CGFloat) {
        drawCaption(text, at: CGPoint(x: leftCol, y: y))
        let lineY = y + 8
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setStrokeColor(uiColor("#E6DEC9").cgColor)
        ctx.setLineWidth(0.5)
        let labelWidth = (text as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: 11, weight: .semibold)]).width + 4 * CGFloat(text.count) * 0.18
        ctx.move(to: CGPoint(x: leftCol + labelWidth + 12, y: lineY))
        ctx.addLine(to: CGPoint(x: rightEdge, y: lineY))
        ctx.strokePath()
    }

    private func drawTrendChart(in rect: CGRect, checkIns: [WeeklyCheckIn]) {
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.saveGState()

        // Background
        let card = UIBezierPath(roundedRect: rect, cornerRadius: 12)
        uiColor("#FAF6EB").setFill()
        card.fill()
        uiColor("#E6DEC9").setStroke()
        card.lineWidth = 0.5
        card.stroke()

        let sorted = checkIns.sorted { $0.weekStartDate < $1.weekStartDate }
        guard sorted.count >= 2 else {
            drawText("More weeks needed",
                     at: CGPoint(x: rect.midX, y: rect.midY - 6),
                     font: .systemFont(ofSize: 12),
                     color: uiColor("#9A9182"),
                     align: .center)
            ctx.restoreGState()
            return
        }

        let pad = (l: 32.0, r: 32.0, t: 18.0, b: 28.0)
        let chartL = rect.minX + pad.l
        let chartR = rect.maxX - pad.r
        let chartT = rect.minY + pad.t
        let chartB = rect.maxY - pad.b
        let chartW = chartR - chartL
        let chartH = chartB - chartT
        let n = sorted.count - 1

        // Y gridlines
        for v in [0.0, 2.5, 5.0, 7.5, 10.0] {
            let yy = chartT + (1 - v / 10) * chartH
            ctx.setStrokeColor(uiColor("#D8CFBC").cgColor)
            ctx.setLineWidth(0.5)
            ctx.setLineDash(phase: 0, lengths: v == 0 || v == 10 ? [] : [3, 3])
            ctx.move(to: CGPoint(x: chartL, y: yy))
            ctx.addLine(to: CGPoint(x: chartR, y: yy))
            ctx.strokePath()
            ctx.setLineDash(phase: 0, lengths: [])
            drawText("\(Int(v))",
                     at: CGPoint(x: chartL - 4, y: yy - 4),
                     font: .monospacedDigitSystemFont(ofSize: 9, weight: .regular),
                     color: uiColor("#9A9182"),
                     align: .right)
        }

        // X labels (W1, W2, ...)
        for (i, _) in sorted.enumerated() {
            let x = chartL + (CGFloat(i) / CGFloat(n)) * chartW
            drawText("W\(i + 1)",
                     at: CGPoint(x: x, y: chartB + 8),
                     font: .systemFont(ofSize: 9, weight: .semibold),
                     color: uiColor("#9A9182"),
                     align: .center)
        }

        // Series
        for zone in ZoneID.allCases {
            let color = zoneColor(zone)
            ctx.setStrokeColor(color.withAlphaComponent(0.95).cgColor)
            ctx.setLineWidth(1.5)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)

            var first = true
            for (i, c) in sorted.enumerated() {
                let v = CGFloat(c.score(for: zone))
                let x = chartL + (CGFloat(i) / CGFloat(n)) * chartW
                let yy = chartT + (1 - v / 10) * chartH
                if first { ctx.move(to: CGPoint(x: x, y: yy)); first = false }
                else { ctx.addLine(to: CGPoint(x: x, y: yy)) }
            }
            ctx.strokePath()

            // End-dot
            if let last = sorted.last {
                let v = CGFloat(last.score(for: zone))
                let x = chartR
                let yy = chartT + (1 - v / 10) * chartH
                ctx.setFillColor(color.cgColor)
                ctx.fillEllipse(in: CGRect(x: x - 2.5, y: yy - 2.5, width: 5, height: 5))
            }
        }
        ctx.restoreGState()
    }

    private func drawLegendRow(zone: ZoneID, x: CGFloat, y: CGFloat, width: CGFloat, checkIns: [WeeklyCheckIn]) {
        let ctx = UIGraphicsGetCurrentContext()!
        let color = zoneColor(zone)
        let def = ZoneRegistry.definition(for: zone)

        ctx.setFillColor(color.cgColor)
        ctx.fill(CGRect(x: x, y: y + 6, width: 14, height: 2.5))
        drawText(def.name,
                 at: CGPoint(x: x + 22, y: y),
                 font: .systemFont(ofSize: 10.5, weight: .medium),
                 color: uiColor("#5B554A"))

        let sorted = checkIns.sorted { $0.weekStartDate < $1.weekStartDate }
        if let f = sorted.first, let l = sorted.last {
            let txt = String(format: "%.1f → %.1f", Double(f.score(for: zone)), Double(l.score(for: zone)))
            drawText(txt,
                     at: CGPoint(x: x + width, y: y),
                     font: .monospacedDigitSystemFont(ofSize: 10, weight: .regular),
                     color: uiColor("#9A9182"),
                     align: .right)
        }
    }

    @discardableResult
    private func drawInsightCard(insight: ZoneInsight, x: CGFloat, y: CGFloat, width: CGFloat) -> CGFloat {
        let ctx = UIGraphicsGetCurrentContext()!
        let height: CGFloat = 50

        let accent: UIColor
        let label: String
        switch insight.type {
        case .warning:     accent = uiColor("#C19036"); label = "WATCH"
        case .positive:    accent = uiColor("#5E8C5A"); label = "LIFT"
        case .correlation: accent = uiColor("#3C6E91"); label = "PATTERN"
        case .trend:       accent = uiColor("#6E5B8A"); label = "TREND"
        }

        let rect = CGRect(x: x, y: y, width: width, height: height)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 10)
        UIColor.white.setFill()
        path.fill()
        uiColor("#E6DEC9").setStroke()
        path.lineWidth = 0.5
        path.stroke()

        // Accent rail
        accent.setFill()
        ctx.fill(CGRect(x: x, y: y, width: 3, height: height))

        drawCaption(label, at: CGPoint(x: x + 12, y: y + 10), color: accent, size: 8.5)
        let bodyAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11.5),
            .foregroundColor: uiColor("#262320")
        ]
        let bodyRect = CGRect(x: x + 12, y: y + 22, width: width - 24, height: height - 26)
        (insight.body as NSString).draw(in: bodyRect, withAttributes: bodyAttr)

        return y + height
    }

    @discardableResult
    private func drawReflectionCard(reflection: WeeklyReflection, x: CGFloat, y: CGFloat, width: CGFloat) -> CGFloat {
        let ctx = UIGraphicsGetCurrentContext()!
        let height: CGFloat = 64

        let rect = CGRect(x: x, y: y, width: width, height: height)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 10)
        uiColor("#FAF6EB").setFill()
        path.fill()
        uiColor("#E6DEC9").setStroke()
        path.lineWidth = 0.5
        path.stroke()

        // Quote rule
        uiColor("#15795A").withAlphaComponent(0.5).setFill()
        ctx.fill(CGRect(x: x + 12, y: y + 24, width: 2, height: height - 32))

        let df = DateFormatter(); df.dateFormat = "MMM d"
        drawCaption("WEEK OF \(df.string(from: reflection.weekStartDate))".uppercased(),
                    at: CGPoint(x: x + 12, y: y + 10))
        drawText(reflection.prompt,
                 at: CGPoint(x: x + 12, y: y + 22),
                 font: .systemFont(ofSize: 9.5, weight: .medium),
                 color: uiColor("#5B554A"))
        let attr: [NSAttributedString.Key: Any] = [
            .font: UIFont.italicSystemFont(ofSize: 12),
            .foregroundColor: uiColor("#262320")
        ]
        let bodyRect = CGRect(x: x + 22, y: y + 34, width: width - 32, height: height - 38)
        (reflection.response as NSString).draw(in: bodyRect, withAttributes: attr)
        return y + height
    }

    // MARK: - Stat helpers

    private func computeMostImproved(checkIns: [WeeklyCheckIn]) -> (String, Int, ZoneID)? {
        guard checkIns.count >= 2 else { return nil }
        let sorted = checkIns.sorted { $0.weekStartDate < $1.weekStartDate }
        let first = sorted.first!, last = sorted.last!
        let bestPair = ZoneID.allCases
            .map { ($0, last.score(for: $0) - first.score(for: $0)) }
            .max(by: { $0.1 < $1.1 })
        guard let pair = bestPair, pair.1 > 0 else { return nil }
        let def = ZoneRegistry.definition(for: pair.0)
        return (def.name, pair.1, pair.0)
    }

    private func computeMostConsistent(checkIns: [WeeklyCheckIn]) -> (String, Double, ZoneID)? {
        guard checkIns.count >= 3 else { return nil }
        let pair = ZoneID.allCases.map { zone -> (ZoneID, Double) in
            let xs = checkIns.map { Double($0.score(for: zone)) }
            let mean = xs.reduce(0, +) / Double(xs.count)
            let variance = xs.map { pow($0 - mean, 2) }.reduce(0, +) / Double(xs.count)
            return (zone, sqrt(variance))
        }.min(by: { $0.1 < $1.1 })
        guard let p = pair else { return nil }
        return (ZoneRegistry.definition(for: p.0).name, p.1, p.0)
    }

    // MARK: - Drawing primitives

    private func drawText(
        _ string: String,
        at point: CGPoint,
        font: UIFont,
        color: UIColor,
        align: NSTextAlignment = .left
    ) {
        let paragraph = NSMutableParagraphStyle(); paragraph.alignment = align
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        let ns = NSAttributedString(string: string, attributes: attrs)
        let size = ns.size()
        let drawPoint: CGPoint
        switch align {
        case .right:  drawPoint = CGPoint(x: point.x - size.width, y: point.y)
        case .center: drawPoint = CGPoint(x: point.x - size.width / 2, y: point.y)
        default:      drawPoint = point
        }
        ns.draw(at: drawPoint)
    }

    private func drawCaption(_ text: String, at point: CGPoint, color: UIColor? = nil, size: CGFloat = 11) {
        drawText(text,
                 at: point,
                 font: .systemFont(ofSize: size, weight: .semibold),
                 color: color ?? uiColor("#9A9182"))
    }

    // MARK: - Color helpers

    private func uiColor(_ hex: String) -> UIColor {
        let v = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: v).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }

    private func zoneColor(_ zone: ZoneID) -> UIColor {
        switch zone {
        case .vitality:   return uiColor("#BE5A45")
        case .deepWork:   return uiColor("#3C6E91")
        case .connection: return uiColor("#2D9474")
        case .innerWorld: return uiColor("#6E5B8A")
        case .creation:   return uiColor("#CC8A4A")
        case .foundation: return uiColor("#B6913E")
        case .growth:     return uiColor("#5E8C5A")
        }
    }
}
