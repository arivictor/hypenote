//
//  SidebarView.swift
//  hypenote
//
//  Created by Ari Laverty on 1/9/2025.
//

import SwiftUI

struct SidebarView: View {
    @ObservedObject var store: NotesStore
    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with add buttons
            HStack {
                Menu {
                    Button(action: {
                        store.createNote()
                    }) {
                        Label("New Note", systemImage: "doc.badge.plus")
                    }
                    Button(action: {
                        showingNewFolderAlert = true
                    }) {
                        Label("New Folder", systemImage: "folder.badge.plus")
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                .menuStyle(.borderlessButton)
                .help("Add new note or folder")
                
                Spacer()
                
                Text("Notes")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Search button placeholder
                Button(action: {
                    // Search functionality placeholder
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Search notes")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.regularMaterial)
            
            Divider()
            
            // Content list
            List(selection: $store.selectedNote) {
                // Root level folders and notes
                FolderSectionView(store: store, parentId: nil)
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
        }
        .alert("New Folder", isPresented: $showingNewFolderAlert) {
            TextField("Folder Name", text: $newFolderName)
            Button("Cancel", role: .cancel) {
                newFolderName = ""
            }
            Button("Create") {
                if !newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    store.createFolder(name: newFolderName.trimmingCharacters(in: .whitespacesAndNewlines))
                    newFolderName = ""
                }
            }
        } message: {
            Text("Enter a name for the new folder")
        }
    }
}

struct FolderSectionView: View {
    @ObservedObject var store: NotesStore
    let parentId: UUID?
    
    var body: some View {
        ForEach(store.subfolders(of: parentId), id: \.id) { folder in
            DisclosureGroup {
                // Notes in this folder
                ForEach(store.notesInFolder(folder.id), id: \.id) { note in
                    NoteRowView(note: note, store: store)
                }
                
                // Subfolders
                FolderSectionView(store: store, parentId: folder.id)
            } label: {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.blue)
                    Text(folder.name)
                        .font(.system(.body, design: .rounded))
                }
            }
            .contextMenu {
                Button(action: {
                    store.createNote(in: folder.id)
                }) {
                    Label("New Note in Folder", systemImage: "doc.badge.plus")
                }
                
                Divider()
                
                Button("Rename Folder") {
                    // TODO: Implement rename
                }
                
                Button(action: {
                    store.deleteFolder(folder)
                }) {
                    Label("Delete Folder", systemImage: "trash")
                }
                .foregroundColor(.red)
            }
        }
        
        // Notes not in any folder (if parentId is nil)
        if parentId == nil {
            ForEach(store.notesInFolder(nil), id: \.id) { note in
                NoteRowView(note: note, store: store)
            }
        }
    }
}

struct NoteRowView: View {
    let note: Note
    @ObservedObject var store: NotesStore
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                if !note.content.isEmpty {
                    Text(previewText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text(formatDate(note.modifiedAt))
                        .font(.caption2)
                        .foregroundColor(.tertiary)
                    
                    if !note.content.isEmpty {
                        Spacer()
                        Text("\(note.content.count) chars")
                            .font(.caption2)
                            .foregroundColor(.tertiary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            store.selectedNote = note
        }
        .contextMenu {
            Button(action: {
                var duplicatedNote = note
                duplicatedNote = Note(title: note.title + " Copy", content: note.content, folderId: note.folderId)
                store.notes.append(duplicatedNote)
            }) {
                Label("Duplicate Note", systemImage: "doc.on.doc")
            }
            
            Button("Move to Folder") {
                // TODO: Implement move to folder
            }
            
            Divider()
            
            Button(action: {
                store.deleteNote(note)
            }) {
                Label("Delete Note", systemImage: "trash")
            }
            .foregroundColor(.red)
        }
    }
    
    private var previewText: String {
        // Clean up the content for preview
        let cleaned = note.content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
        return cleaned
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    SidebarView(store: NotesStore())
        .frame(width: 250)
}