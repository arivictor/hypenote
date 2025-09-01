//
//  BacklinksView.swift
//  hypenote
//
//  Shows backlinks and outgoing links for the current note
//

import SwiftUI

struct BacklinksView: View {
    let note: Note
    let backlinks: [Note]
    @ObservedObject var appViewModel: AppViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("Links")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Outgoing links section
                    if !note.wikilinks.isEmpty {
                        linkSection(
                            title: "Outgoing Links",
                            systemImage: "arrow.up.right",
                            links: note.wikilinks,
                            linkType: .outgoing
                        )
                    }
                    
                    // Backlinks section
                    if !backlinks.isEmpty {
                        linkSection(
                            title: "Backlinks",
                            systemImage: "arrow.down.left",
                            notes: backlinks,
                            linkType: .incoming
                        )
                    }
                    
                    // Graph view section
                    if !note.wikilinks.isEmpty || !backlinks.isEmpty {
                        GraphSectionView(
                            note: note,
                            backlinks: backlinks,
                            appViewModel: appViewModel
                        )
                    }
                    
                    if note.wikilinks.isEmpty && backlinks.isEmpty {
                        emptyState
                    }
                }
                .padding()
            }
        }
    }
    
    @ViewBuilder
    private func linkSection(
        title: String,
        systemImage: String,
        links: [String]? = nil,
        notes: [Note]? = nil,
        linkType: LinkType
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(links?.count ?? notes?.count ?? 0)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let links = links {
                ForEach(links, id: \.self) { link in
                    OutgoingLinkRow(
                        wikilink: link,
                        appViewModel: appViewModel
                    )
                }
            }
            
            if let notes = notes {
                ForEach(notes, id: \.id) { linkedNote in
                    BacklinkRow(
                        note: linkedNote,
                        currentNote: note,
                        appViewModel: appViewModel
                    )
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "link")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("No Links")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Create wikilinks like [[Note Title]] or [[#20250101120000]] to connect your notes")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    enum LinkType {
        case incoming, outgoing
    }
}

struct OutgoingLinkRow: View {
    let wikilink: String
    @ObservedObject var appViewModel: AppViewModel
    
    private var targetNotes: [Note] {
        appViewModel.noteIndex.findNotes(matching: wikilink)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "link")
                    .font(.caption)
                    .foregroundColor(.accentColor)
                
                if targetNotes.count == 1, let target = targetNotes.first {
                    Button(action: {
                        appViewModel.selectedNote = target
                    }) {
                        Text(wikilink)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                } else if targetNotes.count > 1 {
                    Menu {
                        ForEach(targetNotes, id: \.id) { note in
                            Button(note.title.isEmpty ? "Untitled" : note.title) {
                                appViewModel.selectedNote = note
                            }
                        }
                    } label: {
                        HStack {
                            Text(wikilink)
                                .font(.subheadline)
                            Image(systemName: "chevron.down.circle")
                                .font(.caption2)
                        }
                        .foregroundColor(.primary)
                    }
                    .menuStyle(.borderlessButton)
                } else {
                    HStack {
                        Text(wikilink)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("(not found)")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
            }
            
            if targetNotes.isEmpty {
                Button("Create Note") {
                    Task {
                        await appViewModel.createNote(title: wikilink)
                    }
                }
                .font(.caption)
                .controlSize(.mini)
            }
        }
        .padding(.vertical, 2)
    }
}

struct BacklinkRow: View {
    let note: Note
    let currentNote: Note
    @ObservedObject var appViewModel: AppViewModel
    
    var body: some View {
        Button(action: {
            appViewModel.selectedNote = note
        }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(note.title.isEmpty ? "Untitled" : note.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(note.updatedAt, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Show context where the link appears
                if let context = extractLinkContext(from: note.body, linkingTo: currentNote) {
                    Text(context)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .padding(.vertical, 2)
    }
    
    private func extractLinkContext(from body: String, linkingTo targetNote: Note) -> String? {
        let lines = body.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.contains("[[") && 
               (trimmedLine.lowercased().contains(targetNote.title.lowercased()) || 
                trimmedLine.contains("#\(targetNote.id)")) {
                return trimmedLine
            }
        }
        
        return nil
    }
}

struct GraphSectionView: View {
    let note: Note
    let backlinks: [Note]
    @ObservedObject var appViewModel: AppViewModel
    @State private var showingGraph = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "circle.hexagongrid")
                    .foregroundColor(.accentColor)
                Text("Graph View")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Button(showingGraph ? "Hide" : "Show") {
                    showingGraph.toggle()
                }
                .font(.caption)
            }
            
            if showingGraph {
                LocalGraphView(
                    centerNote: note,
                    connectedNotes: backlinks + appViewModel.noteIndex.findNotes(matching: note.wikilinks.joined()),
                    appViewModel: appViewModel
                )
                .frame(height: 200)
                .background(.quaternary)
                .cornerRadius(8)
            }
        }
    }
}

#Preview {
    let appViewModel = AppViewModel()
    let sampleNote = Note(title: "Sample Note", body: "This is a sample note with [[Another Note]] link")
    
    BacklinksView(
        note: sampleNote,
        backlinks: [],
        appViewModel: appViewModel
    )
    .frame(width: 250)
}