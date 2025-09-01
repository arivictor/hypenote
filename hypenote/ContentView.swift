//
//  ContentView.swift
//  hypenote
//
//  Main app content view with split layout
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appViewModel = AppViewModel()
    
    var body: some View {
        Group {
            if appViewModel.showingVaultPicker {
                VaultPickerView(appViewModel: appViewModel)
            } else {
                mainInterface
            }
        }
        .task {
            await appViewModel.initializeApp()
        }
    }
    
    @ViewBuilder
    private var mainInterface: some View {
        NavigationSplitView {
            NoteListView(appViewModel: appViewModel)
                .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        } content: {
            if let selectedNote = appViewModel.selectedNote {
                BacklinksView(
                    note: selectedNote,
                    backlinks: appViewModel.noteIndex.getBacklinks(for: selectedNote),
                    appViewModel: appViewModel
                )
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
            }
        } detail: {
            NoteEditorView(appViewModel: appViewModel)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: {
                    Task {
                        await appViewModel.createNote()
                    }
                }) {
                    Image(systemName: "plus")
                }
                .help("New Note (⌘N)")
                
                Button(action: {
                    appViewModel.noteIndex.clearFilters()
                }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                .help("Clear Filters")
                
                Menu {
                    Button("Settings...") {
                        // TODO: Show settings
                    }
                    
                    Divider()
                    
                    Button("Choose Vault...") {
                        appViewModel.showingVaultPicker = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .help("More Options")
            }
        }
        .searchable(text: $appViewModel.noteIndex.searchText, prompt: "Search notes...")
    }
}

#Preview {
    ContentView()
}
