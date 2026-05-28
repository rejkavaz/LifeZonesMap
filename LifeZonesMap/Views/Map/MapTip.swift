import SwiftUI
import SwiftData

/// First-launch hint overlay on the Map: a small dashed pointer with
/// a single line of copy. Auto-dismisses on tap and stores a flag so
/// it never shows again.
struct MapTip: View {
    @Bindable var prefs: UserPreferences
    @State private var visible = true

    var body: some View {
        if visible && !prefs.hasSeenMapTip {
            VStack(spacing: 6) {
                HStack(alignment: .top, spacing: 8) {
                    // Dashed L shape pointing up at the canvas above
                    Canvas { ctx, size in
                        var p = Path()
                        p.move(to: CGPoint(x: 12, y: 0))
                        p.addLine(to: CGPoint(x: 12, y: size.height - 6))
                        p.addLine(to: CGPoint(x: size.width - 8, y: size.height - 6))
                        ctx.stroke(
                            p,
                            with: .color(LZ.tealDeep),
                            style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                        )
                        // arrow head
                        var head = Path()
                        head.move(to: CGPoint(x: size.width - 8, y: size.height - 10))
                        head.addLine(to: CGPoint(x: size.width - 2, y: size.height - 6))
                        head.addLine(to: CGPoint(x: size.width - 8, y: size.height - 2))
                        ctx.stroke(head, with: .color(LZ.tealDeep), lineWidth: 1)
                    }
                    .frame(width: 56, height: 36)

                    Text("Tap any zone for its history")
                        .font(LZType.serifItalic(13.5))
                        .foregroundStyle(LZ.tealDeep)
                        .lineSpacing(2)
                        .padding(.top, 12)
                }
                .padding(.horizontal, 8)
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
            .onTapGesture { dismiss() }
            .onAppear {
                // Auto-dismiss after 8 seconds — easy to miss is better than nagging.
                DispatchQueue.main.asyncAfter(deadline: .now() + 8) { dismiss() }
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeInOut(duration: 0.35)) { visible = false }
        prefs.hasSeenMapTip = true
    }
}
