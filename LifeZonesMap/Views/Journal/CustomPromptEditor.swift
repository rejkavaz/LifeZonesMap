import SwiftUI
import SwiftData

struct CustomPromptEditor: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var text: String = ""
    @State private var selectedZone: ZoneID?    // nil = cross-zone
    @FocusState private var focused: Bool

    /// If set, we're editing rather than creating.
    var editing: CustomPrompt?

    init(editing: CustomPrompt? = nil) {
        self.editing = editing
        if let editing {
            _text = State(initialValue: editing.text)
            _selectedZone = State(initialValue: editing.zone)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    promptField
                    zonePicker
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(LZ.paper.ignoresSafeArea())
            .navigationTitle(editing == nil ? "New prompt" : "Edit prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(LZ.inkSoft)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .foregroundStyle(canSave ? LZ.tealDeep : LZ.inkMute)
                        .disabled(!canSave)
                }
            }
        }
        .onAppear { focused = true }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your own question").uppercaseCaption()
            Text("Sit with something specific.")
                .font(.system(size: 22, weight: .medium))
                .tracking(-0.45)
                .foregroundStyle(LZ.ink)
        }
    }

    private var promptField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("THE QUESTION").uppercaseCaption()
            TextField("What's something you've been quietly noticing?", text: $text, axis: .vertical)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(LZ.ink)
                .lineLimit(2...6)
                .focused($focused)
                .padding(14)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var zonePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CATEGORY · OPTIONAL").uppercaseCaption()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    chip(label: "Open", isSelected: selectedZone == nil, color: LZ.tealDeep) {
                        selectedZone = nil
                    }
                    ForEach(ZoneID.allCases) { zone in
                        let def = ZoneRegistry.definition(for: zone)
                        chip(label: def.name, isSelected: selectedZone == zone, color: def.color) {
                            selectedZone = zone
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func chip(label: String, isSelected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(Capsule().fill(isSelected ? color.opacity(0.15) : Color.clear))
                .overlay(Capsule().strokeBorder(isSelected ? color : LZ.rule, lineWidth: 0.5))
                .foregroundStyle(isSelected ? color : LZ.inkSoft)
        }
        .buttonStyle(.plain)
    }

    private var canSave: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 8
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let editing {
            editing.text = trimmed
            editing.zoneIDRaw = selectedZone?.rawValue
        } else {
            modelContext.insert(CustomPrompt(text: trimmed, zone: selectedZone))
        }
        try? modelContext.save()
        dismiss()
    }
}
