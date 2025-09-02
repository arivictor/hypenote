
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
    var title: String
    var body: String
}

struct NoteDetailView: View {
    @Binding var note: Note
    var body: some View {
        VStack(alignment: .leading){
            TextField("Title", text: $note.title)
                .font(.title)
                .padding(.bottom)
            TextEditor(text: $note.body)
                .font(.body)
                .border(Color.white.opacity(0.5))
            
        }
        .padding()
        .navigationTitle(note.title)
    }
}

#Preview {
    @Previewable @State var sampleNote = Note(title: "preview", body: "Preview body")
    NoteDetailView(note: $sampleNote)
}

struct ContentView: View {
    @State private var notes: [Note] = [
        Note(title: "Welcome", body: "Start writing notes here!")
    ]
    @State private var selectedNote: Note?
    
    var body: some View {
        NavigationSplitView{
            List(selection: $selectedNote) {
                ForEach(notes){ note in
                    Text(note.title)
                        .tag(note)
                }
            }
            .navigationTitle("My Notes")
            .listStyle(.sidebar)
            .frame(minWidth: 200)
            .toolbar {
                Button("New Note"){
                    let newNote = Note(title: "Untitled", body: "")
                    notes.append(newNote)
                    selectedNote = newNote
                }
            }
        }
    detail:
        {
            if let note = selectedNote {
                NoteDetailView(note: binding(for: note))
            } else{
                Text("Select a note")
                    .foregroundStyle(.secondary)
            }
        }
    }
    private func binding(for note: Note) -> Binding<Note> {
        guard let index = notes.firstIndex(where: { $0.id == note.id}) else {
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
    }
}
