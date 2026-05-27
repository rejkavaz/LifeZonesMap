import SwiftUI

enum AppTab: String, CaseIterable {
    case map, check, pulse
    var label: String {
        switch self {
        case .map:   return "Map"
        case .check: return "Check In"
        case .pulse: return "Pulse"
        }
    }
}

struct LZTabBar: View {
    @Binding var active: AppTab

    var body: some View {
        ZStack(alignment: .bottom) {
            // Fade gradient over the screen edge
            LinearGradient(
                colors: [LZ.paper.opacity(0), LZ.paper.opacity(0.94), LZ.paper],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 84)
            .allowsHitTesting(false)

            HStack {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    Button { active = tab } label: {
                        VStack(spacing: 4) {
                            TabIconShape(tab: tab, active: active == tab)
                                .stroke(active == tab ? LZ.tealDeep : LZ.inkMute,
                                        style: StrokeStyle(
                                            lineWidth: active == tab ? 1.8 : 1.5,
                                            lineCap: .round, lineJoin: .round
                                        ))
                                .frame(width: 22, height: 22)
                            Text(tab.label)
                                .font(.system(size: 10.5,
                                              weight: active == tab ? .semibold : .medium))
                                .tracking(0.4)
                                .foregroundStyle(active == tab ? LZ.tealDeep : LZ.inkMute)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 28)
            .overlay(
                Rectangle()
                    .fill(LZ.ruleSoft)
                    .frame(height: 0.5)
                    .frame(maxWidth: .infinity, alignment: .top),
                alignment: .top
            )
        }
        .frame(height: 84)
    }
}

// Custom tab icons — matched to phone.jsx TabIcon

struct TabIconShape: Shape {
    let tab: AppTab
    var active: Bool

    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * s, y: rect.minY + y * s)
        }
        var path = Path()

        switch tab {
        case .map:
            // Top diamond
            path.move(to: p(12, 3));  path.addLine(to: p(21, 8))
            path.addLine(to: p(12, 13)); path.addLine(to: p(3, 8))
            path.closeSubpath()
            // Bottom diamond
            path.move(to: p(12, 13)); path.addLine(to: p(21, 18))
            path.addLine(to: p(12, 21)); path.addLine(to: p(3, 18))
            path.closeSubpath()
        case .check:
            // Rounded square + check
            let r: CGFloat = 3 * s
            path.addRoundedRect(in: CGRect(x: p(4, 4).x, y: p(4, 4).y,
                                           width: 16 * s, height: 16 * s),
                                cornerSize: CGSize(width: r, height: r))
            path.move(to: p(8, 12)); path.addLine(to: p(11, 15)); path.addLine(to: p(16, 9))
        case .pulse:
            // Heartbeat line
            path.move(to: p(3, 12)); path.addLine(to: p(7, 12))
            path.addLine(to: p(9, 7)); path.addLine(to: p(12, 17))
            path.addLine(to: p(14, 11)); path.addLine(to: p(16, 14))
            path.addLine(to: p(21, 14))
        }
        return path
    }
}
