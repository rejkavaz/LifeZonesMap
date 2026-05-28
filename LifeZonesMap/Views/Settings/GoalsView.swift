import SwiftUI
import SwiftData

/// Set a gentle target band for each zone. Never enforced, never nagged
/// about — shown as a faint horizontal band behind the trend chart.
struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [ZoneGoal]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                ForEach(ZoneID.allCases) { zone in
                    goalRow(for: zone)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(LZ.paper.ignoresSafeArea())
        .navigationTitle("Goals")
        .navigationBarTitleDisplayMode(.large)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Optional bands").uppercaseCaption()
            Text("Where would you like each zone to live?")
                .font(.system(size: 22, weight: .medium))
                .tracking(-0.45)
                .foregroundStyle(LZ.ink)
            Text("These show as faint strips behind your trend chart. Never enforced. Skip what you don't care about.")
                .font(LZType.serifItalic(13))
                .lineSpacing(2)
                .foregroundStyle(LZ.inkSoft)
        }
        .padding(.horizontal, 6)
    }

    private func goalRow(for zone: ZoneID) -> some View {
        let def = ZoneRegistry.definition(for: zone)
        let existing = goals.first { $0.zoneIDRaw == zone.rawValue }
        let lower = existing?.lowerBound ?? 5
        let upper = existing?.upperBound ?? 8
        let enabled = existing != nil

        return ZoneGoalEditor(
            definition: def,
            enabled: enabled,
            lower: lower,
            upper: upper,
            onChange: { newLower, newUpper in
                if let existing {
                    existing.lowerBound = max(1, min(10, newLower))
                    existing.upperBound = max(existing.lowerBound + 1, min(10, newUpper))
                } else {
                    let goal = ZoneGoal(zone: zone, lower: newLower, upper: newUpper)
                    modelContext.insert(goal)
                }
                try? modelContext.save()
            },
            onClear: {
                if let existing {
                    modelContext.delete(existing)
                    try? modelContext.save()
                }
            }
        )
    }
}

struct ZoneGoalEditor: View {
    let definition: ZoneDefinition
    let enabled: Bool
    @State var lower: Int
    @State var upper: Int
    var onChange: (Int, Int) -> Void
    var onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZoneGlyph(glyph: definition.glyph, size: 18, stroke: 1.6)
                    .foregroundStyle(definition.color)
                Text(definition.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(LZ.ink)
                Spacer()
                if enabled {
                    Text("\(lower) – \(upper)")
                        .font(.system(size: 14, weight: .medium).monospacedDigit())
                        .foregroundStyle(definition.color)
                    Button("Clear") { onClear() }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(LZ.inkMute)
                } else {
                    Button {
                        onChange(lower, upper)
                    } label: {
                        Text("Set")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(definition.color.opacity(0.15))
                            .clipShape(Capsule())
                            .foregroundStyle(definition.color)
                    }
                }
            }

            if enabled {
                // Custom dual-thumb band picker
                bandSliders
            }
        }
        .padding(14)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var bandSliders: some View {
        VStack(spacing: 6) {
            // Visual band preview
            GeometryReader { geo in
                let w = geo.size.width
                let lowerX = w * CGFloat(lower) / 10
                let upperX = w * CGFloat(upper) / 10

                ZStack(alignment: .leading) {
                    Capsule().fill(LZ.cream).frame(height: 10)
                    Rectangle()
                        .fill(definition.color.opacity(0.25))
                        .frame(width: max(0, upperX - lowerX), height: 10)
                        .offset(x: lowerX)
                    // tick marks
                    ForEach([1, 5, 10], id: \.self) { v in
                        let tx = w * CGFloat(v) / 10
                        Circle().fill(LZ.inkMute).frame(width: 2, height: 2)
                            .position(x: tx, y: 5)
                    }
                }
            }
            .frame(height: 10)

            HStack(spacing: 12) {
                stepper(label: "Lower", value: $lower, color: definition.color, max: upper - 1)
                stepper(label: "Upper", value: $upper, color: definition.color, min: lower + 1)
            }
        }
        .onChange(of: lower) { onChange(lower, upper) }
        .onChange(of: upper) { onChange(lower, upper) }
    }

    private func stepper(label: String, value: Binding<Int>, color: Color, min: Int = 1, max: Int = 10) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(LZ.inkMute)
            Spacer()
            Button {
                if value.wrappedValue > min { value.wrappedValue -= 1 }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(value.wrappedValue > min ? color : LZ.rule)
            }
            .buttonStyle(.plain)
            Text("\(value.wrappedValue)")
                .font(.system(size: 15, weight: .medium).monospacedDigit())
                .frame(width: 22)
            Button {
                if value.wrappedValue < max { value.wrappedValue += 1 }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(value.wrappedValue < max ? color : LZ.rule)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(LZ.cream)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
