//
//  NoteListView.swift
//  hypenote
//
//  Sidebar note list with search and tag filtering
//

import SwiftUI

struct NoteListView: View {
    @ObservedObject var appViewModel: AppViewModel
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Simple search bar
            SearchBar(text: $appViewModel.noteIndex.searchText)
                .padding(.horizontal, 12)
                .padding(.top, 8)
            
            // Notes list
            List(appViewModel.noteIndex.filteredNotes, id: \.id, selection: $appViewModel.selectedNote) { note in
                NoteRowView(note: note)
                    .tag(note)
            }
            .listStyle(.sidebar)
            
            // Minimal bottom bar
            HStack {
                Button(action: {
                    Task {
                        await appViewModel.createNote()
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .help("New Note (⌘N)")
                
                Spacer()
                
                if !appViewModel.noteIndex.filteredNotes.isEmpty {
                    Text("\(appViewModel.noteIndex.filteredNotes.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            TextField("Search", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.quaternary.opacity(0.5))
        .cornerRadius(6)
    }
}

struct NoteRowView: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                
                Spacer()
                
                Text(note.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.tertiary)
            }
            
            if !note.body.isEmpty {
                Text(note.body)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NoteListView(appViewModel: AppViewModel())
        .frame(width: 300)
}