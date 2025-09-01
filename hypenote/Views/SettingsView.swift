//
//  SettingsView.swift
//  hypenote
//
//  App settings and preferences
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var appViewModel: AppViewModel
    @ObservedObject var hotkeyManager: HotkeyManager
    @ObservedObject var importExportManager: ImportExportManager
    @ObservedObject var spotlightIndexer: SpotlightIndexer
    
    @State private var showingVaultPicker = false
    @State private var showingImportPicker = false
    @State private var showingExportPicker = false
    @State private var autosaveInterval: Double = 30
    @State private var enableSpotlightIndexing = true
    @State private var enableQuickEntry = true
    
    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            vaultTab
                .tabItem {
                    Label("Vault", systemImage: "folder")
                }
            
            importExportTab
                .tabItem {
                    Label("Import/Export", systemImage: "arrow.up.arrow.down")
                }
            
            advancedTab
                .tabItem {
                    Label("Advanced", systemImage: "slider.horizontal.3")
                }
        }
        .frame(width: 500, height: 400)
    }
    
    @ViewBuilder
    private var generalTab: some View {
        Form {
            Section("Editor") {
                HStack {
                    Text("Autosave interval:")
                    Spacer()
                    Slider(value: $autosaveInterval, in: 5...300, step: 5) {
                        Text("Autosave")
                    }
                    Text("\(Int(autosaveInterval))s")
                        .frame(width: 30, alignment: .trailing)
                }
                
                Toggle("Enable live preview by default", isOn: .constant(true))
            }
            
            Section("Quick Entry") {
                Toggle("Enable global quick entry", isOn: $enableQuickEntry)
                    .onChange(of: enableQuickEntry) { enabled in
                        if enabled {
                            _ = hotkeyManager.registerHotkey()
                        } else {
                            hotkeyManager.unregisterHotkey()
                        }
                    }
                
                if enableQuickEntry {
                    HStack {
                        Text("Hotkey:")
                        Spacer()
                        Text("⌘⇧N")
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.quaternary)
                            .cornerRadius(4)
                    }
                }
            }
            
            Section("Search") {
                Toggle("Enable Spotlight indexing", isOn: $enableSpotlightIndexing)
                    .onChange(of: enableSpotlightIndexing) { enabled in
                        Task {
                            if enabled {
                                await spotlightIndexer.indexNotes(appViewModel.noteIndex.notes)
                            } else {
                                await spotlightIndexer.removeAllNotes()
                            }
                        }
                    }
                
                if enableSpotlightIndexing {
                    Text("Notes will be searchable from Spotlight and system search")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var vaultTab: some View {
        Form {
            Section("Current Vault") {
                if let vaultURL = appViewModel.vaultManager.vaultURL {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading) {
                            Text(vaultURL.lastPathComponent)
                                .font(.headline)
                            Text(vaultURL.path)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                } else {
                    Text("No vault selected")
                        .foregroundColor(.secondary)
                }
                
                Button("Choose Vault Location...") {
                    showingVaultPicker = true
                }
            }
            
            Section("Vault Statistics") {
                HStack {
                    Text("Total notes:")
                    Spacer()
                    Text("\(appViewModel.noteIndex.notes.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Total tags:")
                    Spacer()
                    Text("\(appViewModel.noteIndex.tagCounts.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Storage location:")
                    Spacer()
                    Text(appViewModel.vaultManager.vaultURL?.path.contains("iCloud") == true ? "iCloud" : "Local")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Vault Actions") {
                Button("Create Backup...") {
                    showingExportPicker = true
                }
                
                Button("Rebuild Search Index") {
                    Task {
                        await appViewModel.noteIndex.loadNotes()
                        await spotlightIndexer.indexNotes(appViewModel.noteIndex.notes)
                    }
                }
            }
        }
        .padding()
        .fileImporter(
            isPresented: $showingVaultPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    Task {
                        await appViewModel.setVaultLocation(url)
                    }
                }
            case .failure(let error):
                print("Error selecting vault: \(error)")
            }
        }
    }
    
    @ViewBuilder
    private var importExportTab: some View {
        Form {
            Section("Import") {
                VStack(alignment: .leading, spacing: 8) {
                    Button("Import Markdown Files...") {
                        showingImportPicker = true
                    }
                    
                    Text("Import a folder of .md files with optional YAML front matter")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if importExportManager.isImporting {
                    ProgressView("Importing...", value: importExportManager.importProgress, total: 1.0)
                }
            }
            
            Section("Export") {
                VStack(alignment: .leading, spacing: 8) {
                    Button("Export All Notes...") {
                        showingExportPicker = true
                    }
                    
                    Text("Export all notes as Markdown files with YAML front matter")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if importExportManager.isExporting {
                    ProgressView("Exporting...", value: importExportManager.exportProgress, total: 1.0)
                }
            }
            
            if let error = importExportManager.lastError {
                Section("Error") {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .padding()
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    Task {
                        await importExportManager.importNotesFromFolder(url)
                    }
                }
            case .failure(let error):
                print("Error selecting import folder: \(error)")
            }
        }
        .fileExporter(
            isPresented: $showingExportPicker,
            document: ExportDocument(notes: appViewModel.noteIndex.notes),
            contentType: .folder,
            defaultFilename: "hypenote-export"
        ) { result in
            switch result {
            case .success(let url):
                Task {
                    await importExportManager.exportNotes(appViewModel.noteIndex.notes, to: url)
                }
            case .failure(let error):
                print("Error selecting export location: \(error)")
            }
        }
    }
    
    @ViewBuilder
    private var advancedTab: some View {
        Form {
            Section("Debug") {
                HStack {
                    Text("App version:")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Build:")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                        .foregroundColor(.secondary)
                }
                
                Button("Reset All Settings") {
                    // Reset to defaults
                    autosaveInterval = 30
                    enableSpotlightIndexing = true
                    enableQuickEntry = true
                }
                .foregroundColor(.red)
            }
        }
        .padding()
    }
}

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.folder] }
    
    let notes: [Note]
    
    init(notes: [Note]) {
        self.notes = notes
    }
    
    init(configuration: ReadConfiguration) throws {
        self.notes = []
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(directoryWithFileWrappers: [:])
    }
}

#Preview {
    SettingsView(
        appViewModel: AppViewModel(),
        hotkeyManager: HotkeyManager(),
        importExportManager: ImportExportManager(
            fileStorage: FileStorage(vaultManager: VaultManager()),
            noteIndex: NoteIndex(fileStorage: FileStorage(vaultManager: VaultManager())),
            spotlightIndexer: SpotlightIndexer()
        ),
        spotlightIndexer: SpotlightIndexer()
    )
}