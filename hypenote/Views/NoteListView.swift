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
            // Search bar
            SearchBar(text: $appViewModel.noteIndex.searchText)
                .padding(.horizontal)
                .padding(.top, 8)
            
            // Tag filter section
            if !appViewModel.noteIndex.tagCounts.isEmpty {
                TagFilterView(
                    tagCounts: appViewModel.noteIndex.tagCounts,
                    selectedTags: $appViewModel.noteIndex.selectedTags
                )
                .padding(.horizontal)
            }
            
            // Notes list
            List(appViewModel.noteIndex.filteredNotes, id: \.id, selection: $appViewModel.selectedNote) { note in
                NoteRowView(note: note)
                    .tag(note)
            }
            .listStyle(.sidebar)
            
            // Toolbar
            HStack {
                Button(action: {
                    Task {
                        await appViewModel.createNote()
                    }
                }) {
                    Image(systemName: "plus")
                }
                .help("New Note (⌘N)")
                
                Spacer()
                
                if !appViewModel.noteIndex.filteredNotes.isEmpty {
                    Text("\(appViewModel.noteIndex.filteredNotes.count) notes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(.bar)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search notes...", text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.quaternary)
        .cornerRadius(8)
    }
}

struct TagFilterView: View {
    let tagCounts: [(tag: String, count: Int)]
    @Binding var selectedTags: Set<String>
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tags")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !selectedTags.isEmpty {
                    Button("Clear") {
                        selectedTags.removeAll()
                    }
                    .font(.caption)
                }
                
                Button(action: {
                    isExpanded.toggle()
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            if isExpanded {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 80), spacing: 4)
                ], spacing: 4) {
                    ForEach(tagCounts, id: \.tag) { tagCount in
                        TagChip(
                            tag: tagCount.tag,
                            count: tagCount.count,
                            isSelected: selectedTags.contains(tagCount.tag)
                        ) {
                            if selectedTags.contains(tagCount.tag) {
                                selectedTags.remove(tagCount.tag)
                            } else {
                                selectedTags.insert(tagCount.tag)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct TagChip: View {
    let tag: String
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(tag)
                    .font(.caption)
                
                Text("\(count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? .accentColor : .quaternary)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct NoteRowView: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text(note.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !note.body.isEmpty {
                Text(note.body)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            if !note.tags.isEmpty {
                HStack {
                    ForEach(note.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary)
                            .cornerRadius(4)
                    }
                    
                    if note.tags.count > 3 {
                        Text("+\(note.tags.count - 3)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NoteListView(appViewModel: AppViewModel())
        .frame(width: 300)
}