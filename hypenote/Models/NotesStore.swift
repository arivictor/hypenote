//
//  NotesStore.swift
//  hypenote
//
//  Created by Ari Laverty on 1/9/2025.
//

import Foundation
import SwiftUI

class NotesStore: ObservableObject {
    @Published var notes: [Note] = []
    @Published var folders: [Folder] = []
    @Published var selectedNote: Note?
    @Published var selectedFolder: UUID?
    
    private let notesKey = "SavedNotes"
    private let foldersKey = "SavedFolders"
    
    init() {
        loadData()
        
        // Create sample data if empty
        if notes.isEmpty && folders.isEmpty {
            createSampleData()
        }
    }
    
    // MARK: - Note Management
    
    func createNote(in folderId: UUID? = nil) {
        let newNote = Note(folderId: folderId)
        notes.append(newNote)
        selectedNote = newNote
        saveData()
    }
    
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
            saveData()
        }
    }
    
    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        if selectedNote?.id == note.id {
            selectedNote = nil
        }
        saveData()
    }
    
    // MARK: - Folder Management
    
    func createFolder(name: String, parentId: UUID? = nil) {
        let newFolder = Folder(name: name, parentId: parentId)
        folders.append(newFolder)
        selectedFolder = newFolder.id
        saveData()
    }
    
    func deleteFolder(_ folder: Folder) {
        // Move notes out of folder
        for index in notes.indices {
            if notes[index].folderId == folder.id {
                notes[index].folderId = nil
            }
        }
        
        // Remove folder
        folders.removeAll { $0.id == folder.id }
        
        if selectedFolder == folder.id {
            selectedFolder = nil
        }
        saveData()
    }
    
    // MARK: - Filtering
    
    func notesInFolder(_ folderId: UUID?) -> [Note] {
        return notes.filter { $0.folderId == folderId }.sorted { $0.modifiedAt > $1.modifiedAt }
    }
    
    func subfolders(of parentId: UUID?) -> [Folder] {
        return folders.filter { $0.parentId == parentId }.sorted { $0.name < $1.name }
    }
    
    // MARK: - Persistence
    
    private func saveData() {
        if let notesData = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(notesData, forKey: notesKey)
        }
        
        if let foldersData = try? JSONEncoder().encode(folders) {
            UserDefaults.standard.set(foldersData, forKey: foldersKey)
        }
    }
    
    private func loadData() {
        if let notesData = UserDefaults.standard.data(forKey: notesKey),
           let decodedNotes = try? JSONDecoder().decode([Note].self, from: notesData) {
            self.notes = decodedNotes
        }
        
        if let foldersData = UserDefaults.standard.data(forKey: foldersKey),
           let decodedFolders = try? JSONDecoder().decode([Folder].self, from: foldersData) {
            self.folders = decodedFolders
        }
    }
    
    private func createSampleData() {
        // Create a sample folder
        let sampleFolder = Folder(name: "Personal")
        folders.append(sampleFolder)
        
        // Create sample notes
        var welcomeNote = Note(title: "Welcome to HypeNote", content: """
# Welcome to HypeNote

This is your new note-taking app! Here are some features:

- **Clean, minimal design** inspired by Apple Notes and Bear
- **Organize with folders** to keep your notes structured  
- **Rich text editing** with Markdown-style formatting
- **Quick note creation** with intuitive buttons
- **Right-click menus** for easy management

Start writing your first note by clicking the "+" button in the sidebar!
""")
        notes.append(welcomeNote)
        
        var quickNote = Note(title: "Quick Ideas", content: """
# Quick Ideas

- Build a better note-taking workflow
- Implement dark mode
- Add search functionality
- Support for images and attachments
""", folderId: sampleFolder.id)
        notes.append(quickNote)
        
        selectedNote = welcomeNote
        saveData()
    }
}