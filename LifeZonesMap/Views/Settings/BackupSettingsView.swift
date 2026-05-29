import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Settings view dedicated to backup + restore. Reachable from Settings →
/// Data → Backup & restore. Exports a complete, versioned JSON archive
/// including media. Imports either by replacing the store or merging.
struct BackupSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var exportItem: BackupExportItem?
    @State private var exportError: String?
    @State private var showingFileImporter = false
    @State private var pendingImportData: Data?
    @State private var pendingImportFilename: String?
    @State private var showingImportConfirm = false
    @State private var importResult: BackupService.ImportSummary?
    @State private var importErrorMsg: String?

    @Query private var checkIns: [WeeklyCheckIn]
    @Query private var reflections: [WeeklyReflection]
    @Query private var moodDrops: [MoodDrop]
    @Query private var promptResponses: [PromptResponse]

    var body: some View {
        List {
            currentDataSection
            exportSection
            importSection
            if let summary = importResult {
                importSuccessSection(summary)
            }
            if let msg = importErrorMsg {
                importErrorSection(msg)
            }
        }
        .scrollContentBackground(.hidden)
        .background(LZ.paper.ignoresSafeArea())
        .tint(LZ.tealDeep)
        .navigationTitle("Backup & restore")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $exportItem) { item in
            ShareSheet(items: [item.fileURL])
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.json, UTType(filenameExtension: "lifezones") ?? .json],
            allowsMultipleSelection: false
        ) { result in
            handlePickedFile(result)
        }
        .confirmationDialog(
            "Import this backup?",
            isPresented: $showingImportConfirm,
            titleVisibility: .visible
        ) {
            Button("Merge — keep current, add what's new") {
                performImport(mode: .merge)
            }
            Button("Replace everything", role: .destructive) {
                performImport(mode: .replace)
            }
            Button("Cancel", role: .cancel) {
                pendingImportData = nil
                pendingImportFilename = nil
            }
        } message: {
            if let name = pendingImportFilename {
                Text("\(name)\n\nMerge inserts only entries with new IDs. Replace wipes everything currently in the app first.")
            }
        }
    }

    // MARK: - Sections

    private var currentDataSection: some View {
        Section {
            statRow("Check-ins",       count: checkIns.count)
            statRow("Reflections",     count: reflections.count)
            statRow("Mood drops",      count: moodDrops.count)
            statRow("Prompt answers",  count: promptResponses.count)
        } header: {
            Text("What's in your store right now")
        }
    }

    private var exportSection: some View {
        Section {
            Button(action: doExport) {
                Label("Export full backup", systemImage: "square.and.arrow.up")
            }
            if let err = exportError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(LZ.zVitality)
            }
        } header: {
            Text("Export")
        } footer: {
            Text("Saves a single JSON file with every check-in, reflection, mood drop, prompt answer, goal, custom prompt, preferences, and any attached photos / voice notes. Share via AirDrop, iCloud Drive, email — anywhere.")
        }
    }

    private var importSection: some View {
        Section {
            Button {
                showingFileImporter = true
            } label: {
                Label("Import from file", systemImage: "square.and.arrow.down")
            }
        } header: {
            Text("Import")
        } footer: {
            Text("Use this when moving to a new phone or restoring after deleting the app. Confirm replace or merge when prompted.")
        }
    }

    private func importSuccessSection(_ s: BackupService.ImportSummary) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(LZ.zGrowth)
                    Text("Imported")
                        .font(.subheadline.weight(.semibold))
                }
                Text(s.description)
                    .font(.caption)
                    .foregroundStyle(LZ.inkSoft)
            }
            .padding(.vertical, 4)
        }
    }

    private func importErrorSection(_ msg: String) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(LZ.zVitality)
                    Text("Import failed")
                        .font(.subheadline.weight(.semibold))
                }
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(LZ.inkSoft)
            }
            .padding(.vertical, 4)
        }
    }

    private func statRow(_ label: String, count: Int) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(count)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

    private func doExport() {
        let service = BackupService(modelContext: modelContext)
        do {
            let data = try service.exportArchive()
            // Stable filename with date stamp for sorting in iCloud Drive
            let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
            let filename = "lifezones-backup-\(df.string(from: Date())).json"
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(filename)
            try data.write(to: tempURL)
            exportItem = BackupExportItem(fileURL: tempURL)
            exportError = nil
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func handlePickedFile(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            // Security-scoped resource — required for files picked outside
            // the app's container (e.g. iCloud Drive, Files app).
            let didStart = url.startAccessingSecurityScopedResource()
            defer { if didStart { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url)
                pendingImportData = data
                pendingImportFilename = url.lastPathComponent
                showingImportConfirm = true
                importErrorMsg = nil
            } catch {
                importErrorMsg = "Couldn't read the file: \(error.localizedDescription)"
            }
        case .failure(let error):
            importErrorMsg = error.localizedDescription
        }
    }

    private func performImport(mode: BackupService.ImportMode) {
        guard let data = pendingImportData else { return }
        let service = BackupService(modelContext: modelContext)
        do {
            let summary = try service.importArchive(data, mode: mode)
            importResult = summary
            importErrorMsg = nil
        } catch {
            importErrorMsg = error.localizedDescription
            importResult = nil
        }
        pendingImportData = nil
        pendingImportFilename = nil
    }
}

/// Identifiable wrapper so we can use `.sheet(item:)` for the share sheet.
private struct BackupExportItem: Identifiable {
    let id = UUID()
    let fileURL: URL
}
