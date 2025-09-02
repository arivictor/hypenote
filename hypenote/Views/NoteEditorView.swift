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
    @State private var showingPreview = false
    @State private var editingTitle = false
    @State private var newTitle = ""
    @State private var showingMetadata = false
    
    var body: some View {
        Group {
            if let selectedNote = appViewModel.selectedNote {
                VStack(spacing: 0) {
                    // Clean header with just title
                    noteHeader(for: selectedNote)
                    
                    // Main editor content
                    HStack(spacing: 0) {
                        // Editor pane
                        VStack(spacing: 0) {
                            TextEditor(text: binding(for: selectedNote, keyPath: \.body))
                                .font(.system(size: 14, design: .default))
                                .padding(20)
                                .scrollContentBackground(.hidden)
                                .background(.clear)
                        }
                        
                        if showingPreview {
                            Divider()
                            
                            // Preview pane
                            MarkdownPreviewView(markdown: editingNote?.body ?? selectedNote.body)
                        }
                    }
                }
                .background(.background)
                .onAppear {
                    editingNote = selectedNote
                    newTitle = selectedNote.title
                    // Mark as actively editing to prevent list bouncing
                    appViewModel.noteIndex.setActivelyEditing(true)
                }
                .onChange(of: selectedNote) { newNote in
                    // Mark as no longer actively editing the previous note
                    appViewModel.noteIndex.setActivelyEditing(false)
                    saveCurrentNote()
                    editingNote = newNote
                    newTitle = newNote.title
                    // Mark as actively editing the new note
                    appViewModel.noteIndex.setActivelyEditing(true)
                }
                .onDisappear {
                    // Mark as no longer actively editing when view disappears
                    appViewModel.noteIndex.setActivelyEditing(false)
                    saveCurrentNote()
                }
                .toolbar {
                    ToolbarItemGroup(placement: .automatic) {
                        Button(action: {
                            showingPreview.toggle()
                        }) {
                            Image(systemName: showingPreview ? "eye.slash" : "eye")
                        }
                        .help("Toggle Preview")
                        
                        Button(action: {
                            showingMetadata.toggle()
                        }) {
                            Image(systemName: "info.circle")
                        }
                        .help("Toggle Info")
                    }
                }
                .popover(isPresented: $showingMetadata, arrowEdge: .bottom) {
                    metadataView(for: selectedNote)
                        .padding()
                        .frame(width: 300)
                }
            } else {
                // No note selected state
                VStack(spacing: 20) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No Note Selected")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Select a note from the sidebar or create a new one")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
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
        HStack {
            // Clean title editing
            if editingTitle {
                TextField("Note title", text: $newTitle, onCommit: {
                    saveTitle()
                })
                .font(.title2)
                .fontWeight(.medium)
                .textFieldStyle(.plain)
                .onSubmit {
                    saveTitle()
                }
            } else {
                Button(action: {
                    editingTitle = true
                    newTitle = note.title
                }) {
                    Text(note.title.isEmpty ? "Untitled" : note.title)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.regularMaterial)
    }
    
    @ViewBuilder
    private func metadataView(for note: Note) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Note Information")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("ID:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(note.id)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Created:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(note.createdAt, style: .date)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Updated:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(note.updatedAt, style: .relative)
                        .foregroundColor(.secondary)
                }
                
                if !note.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tags:")
                            .fontWeight(.medium)
                        
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 60), spacing: 4)
                        ], spacing: 4) {
                            ForEach(note.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.quaternary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .font(.caption)
        }
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
                // Update local editing state to reflect saved changes
                await MainActor.run {
                    if let updatedNote = appViewModel.selectedNote, updatedNote.id == note.id {
                        editingNote = updatedNote
                    }
                }
            }
        }
    }
    
    private func saveTitle() {
        editingTitle = false
        
        if let selectedNote = appViewModel.selectedNote, newTitle != selectedNote.title {
            Task {
                await appViewModel.renameNote(selectedNote, newTitle: newTitle)
                // Update local state to reflect the saved title
                await MainActor.run {
                    if let updatedNote = appViewModel.selectedNote, updatedNote.id == selectedNote.id {
                        newTitle = updatedNote.title
                        editingNote = updatedNote
                    }
                }
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
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(markdown)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(.background)
    }
}

#Preview {
    NoteEditorView(appViewModel: AppViewModel())
}