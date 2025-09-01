//
//  FileStorage.swift
//  hypenote
//
//  Handles atomic file operations for note storage
//

import Foundation

@MainActor
class FileStorage: ObservableObject {
    private let vaultManager: VaultManager
    
    init(vaultManager: VaultManager) {
        self.vaultManager = vaultManager
    }
    
    /// Save note to file with atomic operation
    func saveNote(_ note: Note) async throws {
        guard let notesURL = vaultManager.notesURL else {
            throw VaultManager.VaultError.noVaultSelected
        }
        
        try vaultManager.ensureDirectoriesExist()
        
        let content = generateMarkdownContent(for: note)
        let fileURL = notesURL.appendingPathComponent(note.filename)
        
        // Atomic write: write to temporary file then replace
        let tempURL = fileURL.appendingPathExtension("tmp")
        
        try content.write(to: tempURL, atomically: true, encoding: .utf8)
        
        // Replace original file
        _ = fileURL.startAccessingSecurityScopedResource()
        defer { fileURL.stopAccessingSecurityScopedResource() }
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        
        try FileManager.default.moveItem(at: tempURL, to: fileURL)
    }
    
    /// Load note from file
    func loadNote(from fileURL: URL) async throws -> Note? {
        _ = fileURL.startAccessingSecurityScopedResource()
        defer { fileURL.stopAccessingSecurityScopedResource() }
        
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        return YAMLParser.parseNote(from: content, fileURL: fileURL)
    }
    
    /// Load all notes from vault
    func loadAllNotes() async throws -> [Note] {
        guard let notesURL = vaultManager.notesURL else {
            throw VaultManager.VaultError.noVaultSelected
        }
        
        try vaultManager.ensureDirectoriesExist()
        
        _ = notesURL.startAccessingSecurityScopedResource()
        defer { notesURL.stopAccessingSecurityScopedResource() }
        
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: notesURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ).filter { $0.pathExtension == "md" }
        
        var notes: [Note] = []
        
        for fileURL in fileURLs {
            if let note = try await loadNote(from: fileURL) {
                notes.append(note)
            }
        }
        
        return notes
    }
    
    /// Delete note file
    func deleteNote(_ note: Note) async throws {
        guard let notesURL = vaultManager.notesURL else {
            throw VaultManager.VaultError.noVaultSelected
        }
        
        let fileURL = notesURL.appendingPathComponent(note.filename)
        
        _ = fileURL.startAccessingSecurityScopedResource()
        defer { fileURL.stopAccessingSecurityScopedResource() }
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
    
    /// Move note to trash
    func moveNoteToTrash(_ note: Note) async throws {
        guard let notesURL = vaultManager.notesURL,
              let trashURL = vaultManager.trashURL else {
            throw VaultManager.VaultError.noVaultSelected
        }
        
        try vaultManager.ensureDirectoriesExist()
        
        let sourceURL = notesURL.appendingPathComponent(note.filename)
        let destinationURL = trashURL.appendingPathComponent(note.filename)
        
        _ = sourceURL.startAccessingSecurityScopedResource()
        _ = destinationURL.startAccessingSecurityScopedResource()
        defer {
            sourceURL.stopAccessingSecurityScopedResource()
            destinationURL.stopAccessingSecurityScopedResource()
        }
        
        if FileManager.default.fileExists(atPath: sourceURL.path) {
            try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
        }
    }
    
    /// Rename note file when title changes
    func renameNote(_ note: Note, oldFilename: String) async throws {
        guard let notesURL = vaultManager.notesURL else {
            throw VaultManager.VaultError.noVaultSelected
        }
        
        let oldURL = notesURL.appendingPathComponent(oldFilename)
        let newURL = notesURL.appendingPathComponent(note.filename)
        
        _ = oldURL.startAccessingSecurityScopedResource()
        _ = newURL.startAccessingSecurityScopedResource()
        defer {
            oldURL.stopAccessingSecurityScopedResource()
            newURL.stopAccessingSecurityScopedResource()
        }
        
        if FileManager.default.fileExists(atPath: oldURL.path) && oldURL != newURL {
            try FileManager.default.moveItem(at: oldURL, to: newURL)
        }
    }
    
    /// Generate markdown content with YAML front matter
    private func generateMarkdownContent(for note: Note) -> String {
        let frontMatter = YAMLParser.generateFrontMatter(for: note)
        return frontMatter + note.body
    }
    
    /// Check if file exists for note
    func noteFileExists(_ note: Note) -> Bool {
        guard let notesURL = vaultManager.notesURL else { return false }
        
        let fileURL = notesURL.appendingPathComponent(note.filename)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
}