//
//  NoteEditorView.swift
//  hypenote
//
//  Split view editor with markdown preview
//

import SwiftUI

struct NoteEditorView: View {
    @ObservedObject var appViewModel: AppViewModel
    @State private var editingNote: Note?
    @State private var showingPreview = true
    @State private var editingTitle = false
    @State private var newTitle = ""
    @State private var newTags = ""
    
    var body: some View {
        Group {
            if let selectedNote = appViewModel.selectedNote {
                VStack(spacing: 0) {
                    // Header with title and metadata
                    noteHeader(for: selectedNote)
                    
                    Divider()
                    
                    // Editor content
                    HStack(spacing: 0) {
                        // Editor pane
                        VStack(spacing: 0) {
                            editorToolbar
                            
                            TextEditor(text: binding(for: selectedNote, keyPath: \.body))
                                .font(.system(.body, design: .monospaced))
                                .padding()
                        }
                        
                        if showingPreview {
                            Divider()
                            
                            // Preview pane
                            MarkdownPreviewView(markdown: editingNote?.body ?? selectedNote.body)
                        }
                    }
                }
                .onAppear {
                    editingNote = selectedNote
                    newTitle = selectedNote.title
                    newTags = selectedNote.tags.joined(separator: ", ")
                }
                .onChange(of: selectedNote) { newNote in
                    saveCurrentNote()
                    editingNote = newNote
                    newTitle = newNote?.title ?? ""
                    newTags = newNote?.tags.joined(separator: ", ") ?? ""
                }
                .onDisappear {
                    saveCurrentNote()
                }
            } else {
                // No note selected state
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No Note Selected")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Select a note from the sidebar or create a new one")
                        .foregroundColor(.secondary)
                    
                    Button("New Note") {
                        Task {
                            await appViewModel.createNote()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    @ViewBuilder
    private func noteHeader(for note: Note) -> some View {
        VStack(spacing: 8) {
            HStack {
                // Title editing
                if editingTitle {
                    TextField("Note title", text: $newTitle, onCommit: {
                        saveTitle()
                    })
                    .font(.title2)
                    .fontWeight(.bold)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        saveTitle()
                    }
                } else {
                    Button(action: {
                        editingTitle = true
                    }) {
                        Text(note.title.isEmpty ? "Untitled" : note.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                // Note metadata
                VStack(alignment: .trailing, spacing: 2) {
                    Text("ID: \(note.id)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Updated: \(note.updatedAt, style: .relative)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Tags editing
            HStack {
                Text("Tags:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("Add tags (comma separated)", text: $newTags, onCommit: {
                    saveTags()
                })
                .font(.caption)
                .textFieldStyle(.plain)
                .onSubmit {
                    saveTags()
                }
                
                Spacer()
            }
        }
        .padding()
        .background(.regularMaterial)
    }
    
    private var editorToolbar: some View {
        HStack {
            Button(action: {
                showingPreview.toggle()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: showingPreview ? "eye.slash" : "eye")
                    Text(showingPreview ? "Hide Preview" : "Show Preview")
                }
            }
            .help("Toggle Preview (⌘⇧P)")
            
            Spacer()
            
            Button(action: {
                Task {
                    if let note = editingNote {
                        await appViewModel.saveNote(note)
                    }
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save")
                }
            }
            .help("Save Note (⌘S)")
        }
        .padding()
        .background(.bar)
    }
    
    private func binding(for note: Note, keyPath: WritableKeyPath<Note, String>) -> Binding<String> {
        Binding(
            get: { editingNote?[keyPath: keyPath] ?? note[keyPath: keyPath] },
            set: { newValue in
                editingNote?[keyPath: keyPath] = newValue
            }
        )
    }
    
    private func saveCurrentNote() {
        if let note = editingNote {
            Task {
                await appViewModel.saveNote(note)
            }
        }
    }
    
    private func saveTitle() {
        editingTitle = false
        
        if let selectedNote = appViewModel.selectedNote, newTitle != selectedNote.title {
            Task {
                await appViewModel.renameNote(selectedNote, newTitle: newTitle)
            }
        }
    }
    
    private func saveTags() {
        if var note = editingNote {
            let tags = newTags
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            note.tags = tags
            editingNote = note
            
            Task {
                await appViewModel.saveNote(note)
            }
        }
    }
}

struct MarkdownPreviewView: View {
    let markdown: String
    
    var body: some View {
        ScrollView {
            if let attributedString = try? AttributedString(markdown: markdown) {
                Text(attributedString)
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(markdown)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(.regularMaterial)
    }
}

#Preview {
    NoteEditorView(appViewModel: AppViewModel())
}