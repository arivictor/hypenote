//
//  AppViewModel.swift
//  hypenote
//
//  Main app view model managing vault and note state
//

import Foundation
import SwiftUI

@MainActor
class AppViewModel: ObservableObject {
    @Published var vaultManager = VaultManager()
    @Published var fileStorage: FileStorage
    @Published var noteIndex: NoteIndex
    @Published var selectedNote: Note?
    @Published var showingVaultPicker = false
    
    // Advanced features
    @Published var spotlightIndexer = SpotlightIndexer()
    @Published var hotkeyManager = HotkeyManager()
    @Published var importExportManager: ImportExportManager
    @Published var quickEntryWindowController: QuickEntryWindowController?
    
    init() {
        self.fileStorage = FileStorage(vaultManager: vaultManager)
        self.noteIndex = NoteIndex(fileStorage: fileStorage)
        self.importExportManager = ImportExportManager(
            fileStorage: fileStorage,
            noteIndex: noteIndex,
            spotlightIndexer: spotlightIndexer
        )
        
        // Set up initial state
        if !vaultManager.isVaultReady {
            showingVaultPicker = true
        }
        
        setupHotkeyManager()
    }
    
    /// Initialize app by loading notes if vault is ready
    func initializeApp() async {
        if vaultManager.isVaultReady {
            await noteIndex.loadNotes()
            
            // Index notes for Spotlight if enabled
            if spotlightIndexer.isIndexingAvailable {
                await spotlightIndexer.indexNotes(noteIndex.notes)
            }
        }
    }
    
    /// Create a new note
    func createNote(title: String = "New Note", body: String = "", tags: [String] = []) async {
        var note = Note(title: title, tags: tags, body: body)
        note.touch()
        
        do {
            try await fileStorage.saveNote(note)
            noteIndex.addNote(note)
            selectedNote = note
            
            // Index for Spotlight
            await spotlightIndexer.indexNote(note)
        } catch {
            print("Error creating note: \(error)")
        }
    }
    
    /// Save existing note
    func saveNote(_ note: Note) async {
        var updatedNote = note
        updatedNote.touch()
        
        do {
            try await fileStorage.saveNote(updatedNote)
            noteIndex.updateNote(updatedNote)
            
            if selectedNote?.id == note.id {
                selectedNote = updatedNote
            }
            
            // Update Spotlight index
            await spotlightIndexer.indexNote(updatedNote)
        } catch {
            print("Error saving note: \(error)")
        }
    }
    
    /// Delete note
    func deleteNote(_ note: Note) async {
        do {
            try await fileStorage.moveNoteToTrash(note)
            noteIndex.removeNote(note)
            
            if selectedNote?.id == note.id {
                selectedNote = nil
            }
            
            // Remove from Spotlight index
            await spotlightIndexer.removeNote(note)
        } catch {
            print("Error deleting note: \(error)")
        }
    }
    
    /// Rename note and update wikilinks
    func renameNote(_ note: Note, newTitle: String) async {
        let oldTitle = note.title
        let oldFilename = note.filename
        
        var updatedNote = note
        updatedNote.title = newTitle
        updatedNote.touch()
        
        do {
            // Save note with new title
            try await fileStorage.saveNote(updatedNote)
            
            // Rename file if filename changed
            if oldFilename != updatedNote.filename {
                try await fileStorage.renameNote(updatedNote, oldFilename: oldFilename)
            }
            
            // Update wikilinks in other notes
            await noteIndex.updateWikilinks(oldTitle: oldTitle, newTitle: newTitle, noteId: note.id)
            
            noteIndex.updateNote(updatedNote)
            
            if selectedNote?.id == note.id {
                selectedNote = updatedNote
            }
            
            // Update Spotlight index
            await spotlightIndexer.indexNote(updatedNote)
        } catch {
            print("Error renaming note: \(error)")
        }
    }
    
    /// Set vault location
    func setVaultLocation(_ url: URL) async {
        vaultManager.setVaultURL(url)
        
        if vaultManager.isVaultReady {
            showingVaultPicker = false
            await noteIndex.loadNotes()
            
            // Reindex for Spotlight
            await spotlightIndexer.indexNotes(noteIndex.notes)
        }
    }
    
    /// Create default vault
    func createDefaultVault() async {
        await vaultManager.createDefaultVault()
        
        if vaultManager.isVaultReady {
            showingVaultPicker = false
            await noteIndex.loadNotes()
        }
    }
    
    /// Show quick entry window
    func showQuickEntry() {
        if quickEntryWindowController == nil {
            quickEntryWindowController = QuickEntryWindowController(appViewModel: self)
        }
        quickEntryWindowController?.showWindow(nil)
    }
    
    /// Setup hotkey manager
    private func setupHotkeyManager() {
        hotkeyManager.onHotkeyPressed = { [weak self] in
            self?.showQuickEntry()
        }
        
        // Register default hotkey (Cmd+Shift+N)
        _ = hotkeyManager.registerHotkey()
    }
}