//
//  ImportExportManager.swift
//  hypenote
//
//  Import and export functionality for notes
//

import Foundation
import SwiftUI

@MainActor
class ImportExportManager: ObservableObject {
    private let fileStorage: FileStorage
    private let noteIndex: NoteIndex
    private let spotlightIndexer: SpotlightIndexer
    
    @Published var isImporting = false
    @Published var isExporting = false
    @Published var importProgress: Double = 0
    @Published var exportProgress: Double = 0
    @Published var lastError: Error?
    
    init(fileStorage: FileStorage, noteIndex: NoteIndex, spotlightIndexer: SpotlightIndexer) {
        self.fileStorage = fileStorage
        self.noteIndex = noteIndex
        self.spotlightIndexer = spotlightIndexer
    }
    
    /// Import notes from a folder of Markdown files
    func importNotesFromFolder(_ folderURL: URL) async {
        isImporting = true
        importProgress = 0
        lastError = nil
        
        defer {
            isImporting = false
            importProgress = 0
        }
        
        do {
            _ = folderURL.startAccessingSecurityScopedResource()
            defer { folderURL.stopAccessingSecurityScopedResource() }
            
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: folderURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ).filter { $0.pathExtension.lowercased() == "md" }
            
            let totalFiles = fileURLs.count
            guard totalFiles > 0 else { return }
            
            for (index, fileURL) in fileURLs.enumerated() {
                do {
                    try await importSingleFile(fileURL)
                    importProgress = Double(index + 1) / Double(totalFiles)
                } catch {
                    print("Error importing file \(fileURL.lastPathComponent): \(error)")
                    lastError = error
                }
            }
            
            // Reload notes after import
            await noteIndex.loadNotes()
            
            // Reindex for Spotlight
            await spotlightIndexer.indexNotes(noteIndex.notes)
            
        } catch {
            lastError = error
            print("Error importing notes: \(error)")
        }
    }
    
    /// Export selected notes to a folder
    func exportNotes(_ notes: [Note], to folderURL: URL) async {
        isExporting = true
        exportProgress = 0
        lastError = nil
        
        defer {
            isExporting = false
            exportProgress = 0
        }
        
        do {
            _ = folderURL.startAccessingSecurityScopedResource()
            defer { folderURL.stopAccessingSecurityScopedResource() }
            
            let totalNotes = notes.count
            guard totalNotes > 0 else { return }
            
            for (index, note) in notes.enumerated() {
                do {
                    try await exportSingleNote(note, to: folderURL)
                    exportProgress = Double(index + 1) / Double(totalNotes)
                } catch {
                    print("Error exporting note \(note.id): \(error)")
                    lastError = error
                }
            }
            
        } catch {
            lastError = error
            print("Error exporting notes: \(error)")
        }
    }
    
    /// Import a single Markdown file
    private func importSingleFile(_ fileURL: URL) async throws {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        
        // Try to parse existing YAML front matter
        if let note = YAMLParser.parseNote(from: content, fileURL: fileURL) {
            // Note has valid front matter, use it
            try await fileStorage.saveNote(note)
        } else {
            // Create new note from plain markdown
            let filename = fileURL.deletingPathExtension().lastPathComponent
            let title = extractTitleFromContent(content) ?? filename
            
            var note = Note(title: title, body: content)
            
            // Try to extract tags from content
            note.tags = extractTagsFromContent(content)
            
            try await fileStorage.saveNote(note)
        }
    }
    
    /// Export a single note
    private func exportSingleNote(_ note: Note, to folderURL: URL) async throws {
        let frontMatter = YAMLParser.generateFrontMatter(for: note)
        let content = frontMatter + note.body
        
        let fileURL = folderURL.appendingPathComponent(note.filename)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    /// Extract title from markdown content (first # heading)
    private func extractTitleFromContent(_ content: String) -> String? {
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("# ") {
                return String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return nil
    }
    
    /// Extract tags from content (look for #tag patterns)
    private func extractTagsFromContent(_ content: String) -> [String] {
        let pattern = #"#(\w+)"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let nsString = content as NSString
        let results = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsString.length))
        
        var tags = Set<String>()
        for match in results {
            let tag = nsString.substring(with: match.range(at: 1))
            tags.insert(tag)
        }
        
        return Array(tags).sorted()
    }
    
    /// Create a backup of the entire vault
    func createVaultBackup(to destinationURL: URL) async {
        isExporting = true
        exportProgress = 0
        lastError = nil
        
        defer {
            isExporting = false
            exportProgress = 0
        }
        
        do {
            await exportNotes(noteIndex.notes, to: destinationURL)
        } catch {
            lastError = error
            print("Error creating vault backup: \(error)")
        }
    }
}