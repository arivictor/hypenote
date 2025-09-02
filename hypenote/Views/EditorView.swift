//
//  EditorView.swift
//  hypenote
//
//  Created by Ari Laverty on 1/9/2025.
//

import SwiftUI

struct EditorView: View {
    @ObservedObject var store: NotesStore
    @State private var editingContent: String = ""
    @State private var isEditing = false
    
    var body: some View {
        Group {
            if let selectedNote = store.selectedNote {
                VStack(spacing: 0) {
                    // Title bar
                    titleBar(for: selectedNote)
                    
                    // Editor area
                    editorArea(for: selectedNote)
                }
                .onAppear {
                    editingContent = selectedNote.content
                }
                .onChange(of: selectedNote.id) { _ in
                    saveCurrentChanges()
                    editingContent = selectedNote.content
                }
            } else {
                // Empty state
                VStack(spacing: 24) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.tertiary)
                    
                    VStack(spacing: 8) {
                        Text("Select a note to start writing")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Choose a note from the sidebar or create a new one to begin")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: {
                        store.createNote()
                    }) {
                        Label("Create New Note", systemImage: "plus")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.textBackgroundColor))
            }
        }
    }
    
    @ViewBuilder
    private func titleBar(for note: Note) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    Text("Modified \(formatDate(note.modifiedAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !note.content.isEmpty {
                        Text("\(note.content.count) characters")
                            .font(.caption)
                            .foregroundColor(.tertiary)
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    // Share functionality
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(note.content, forType: .string)
                }) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Copy to clipboard")
                
                Button(action: {
                    store.deleteNote(note)
                }) {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Delete note")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.regularMaterial)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(.separator),
            alignment: .bottom
        )
    }
    
    @ViewBuilder
    private func editorArea(for note: Note) -> some View {
        TextEditor(text: $editingContent)
            .font(.system(.body, design: .rounded))
            .lineSpacing(6)
            .textEditorStyle(.plain)
            .padding(20)
            .scrollContentBackground(.hidden)
            .background(Color(NSColor.textBackgroundColor))
            .onChange(of: editingContent) { newValue in
                // Debounced save
                isEditing = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if isEditing {
                        saveCurrentChanges()
                        isEditing = false
                    }
                }
            }
    }
    
    private func saveCurrentChanges() {
        guard var currentNote = store.selectedNote else { return }
        
        if currentNote.content != editingContent {
            currentNote.updateContent(editingContent)
            store.updateNote(currentNote)
            store.selectedNote = currentNote // Update the selected note reference
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    let store = NotesStore()
    EditorView(store: store)
        .frame(width: 600, height: 400)
}