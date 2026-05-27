import SwiftUI

struct ZoneCard: View {
    let definition: ZoneDefinition
    @Binding var score: Int
    @Binding var selectedTag: String?
    @Binding var note: String
    var hapticsEnabled: Bool = true

    @State private var noteExpanded = false
    @FocusState private var noteFocused: Bool

    var body: some View {
        HStack(spacing: 0) {
            // Left color accent
            Rectangle()
                .fill(definition.color)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: DS.Spacing.s12) {
                // Zone identity + score
                HStack {
                    Image(systemName: definition.iconName)
                        .font(.body)
                        .foregroundStyle(definition.color)
                    Text(definition.name)
                        .font(.headline)
                    Spacer()
                    Text("\(score)")
                        .font(.system(size: 40, weight: .thin))
                        .foregroundStyle(definition.color)
                        .contentTransition(.numericText())
                        .animation(DS.Anim.spring, value: score)
                }

                // Slider
                Slider(value: Binding(
                    get: { Double(score) },
                    set: { newVal in
                        let rounded = Int(newVal.rounded())
                        if rounded != score {
                            score = rounded
                            if hapticsEnabled {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                    }
                ), in: 1...10, step: 1)
                .tint(definition.color)

                // Mood tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Spacing.s8) {
                        ForEach(definition.exampleTags, id: \.self) { tag in
                            TagPill(
                                label: tag,
                                isSelected: selectedTag == tag,
                                color: definition.color
                            ) {
                                selectedTag = (selectedTag == tag) ? nil : tag
                            }
                        }
                    }
                }

                // Note field
                if noteExpanded {
                    TextField("Optional note…", text: $note, axis: .vertical)
                        .font(.body)
                        .lineLimit(2...4)
                        .focused($noteFocused)
                        .onChange(of: note) {
                            if note.count > 120 { note = String(note.prefix(120)) }
                        }
                        .padding(DS.Spacing.s8)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                } else {
                    Button {
                        noteExpanded = true
                        noteFocused = true
                    } label: {
                        Label("Add note", systemImage: "square.and.pencil")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(DS.Spacing.s16)
        }
        .background(.background, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.lg)
                .strokeBorder(.separator, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg))
    }
}

struct TagPill: View {
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, DS.Spacing.s12)
                .padding(.vertical, DS.Spacing.s4)
                .background(isSelected ? color.opacity(0.2) : Color(.systemGray6), in: Capsule())
                .foregroundStyle(isSelected ? color : .secondary)
                .overlay(isSelected ? Capsule().strokeBorder(color.opacity(0.5), lineWidth: 1) : nil)
        }
        .buttonStyle(.plain)
        .animation(DS.Anim.sheet, value: isSelected)
    }
}
