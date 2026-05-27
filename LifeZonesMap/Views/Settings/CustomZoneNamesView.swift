import SwiftUI

struct CustomZoneNamesView: View {
    let prefs: UserPreferences
    @State private var names: [ZoneID: String] = [:]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            ForEach(ZoneRegistry.all) { def in
                HStack(spacing: DS.Spacing.s12) {
                    Image(systemName: def.iconName)
                        .foregroundStyle(def.color)
                        .frame(width: 24)
                    TextField(def.name, text: Binding(
                        get: { names[def.id] ?? prefs.customZoneNames[def.id.rawValue] ?? "" },
                        set: { names[def.id] = $0 }
                    ))
                }
            }
        }
        .navigationTitle("Zone names")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
            }
        }
        .onAppear {
            for def in ZoneRegistry.all {
                names[def.id] = prefs.customZoneNames[def.id.rawValue]
            }
        }
    }

    private func save() {
        for (id, name) in names {
            if name.isEmpty {
                prefs.customZoneNames.removeValue(forKey: id.rawValue)
            } else {
                prefs.customZoneNames[id.rawValue] = name
            }
        }
        try? modelContext.save()
    }
}
