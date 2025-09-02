/*
    Project: HypeNote 📝
    Authors:
    - Ari Laverty (gh: arivictor)
    
    © 2025 Ari Laverty. All rights reserved.
    License: Apache-2.0 + Common Clause
*/

import SwiftUI
import Foundation

struct Note: Identifiable, Hashable {
    let id = UUID()
    var body: String
    
    var title: String {
        body.components(separatedBy: .newlines).first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Untitled"
    }
}

struct NoteDetailView: View {
    @Binding var note: Note
    
    var body: some View {
        ZStack {
            // Match system background for uniform look
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()
            
            TextEditor(text: $note.body)
                .scrollContentBackground(.hidden) // hide default white
                .font(.body)
                .padding()
                .background(Color.clear)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    @Previewable @State var sampleNote = Note(body: "preview\nPreview body")
    NoteDetailView(note: $sampleNote)
}

struct ContentView: View {
    @State private var notes: [Note] = [
        Note(body: "Welcome\nStart writing notes here!")
    ]
    @State private var selectedNote: Note?
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedNote) {
                ForEach(notes) { note in
                    Text(note.title)
                        .tag(note)
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 200)
            .toolbar {
                Button("New Note") {
                    let newNote = Note(body: "Untitled")
                    notes.append(newNote)
                    selectedNote = newNote
                }
            }
        } detail: {
            if let note = selectedNote {
                NoteDetailView(note: binding(for: note))
            } else {
                Text("Select a note")
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func binding(for note: Note) -> Binding<Note> {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else {
            fatalError("Note not found")
        }
        return $notes[index]
    }
}

#Preview {
    ContentView()
}

@main
struct HypeNoteApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
    }
}
