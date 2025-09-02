//
//  ContentView.swift
//  hypenote
//
//  Main app content view with split layout
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appViewModel = AppViewModel()
    @State private var showingSettings = false
    
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
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                appViewModel: appViewModel,
                hotkeyManager: appViewModel.hotkeyManager,
                importExportManager: appViewModel.importExportManager,
                spotlightIndexer: appViewModel.spotlightIndexer
            )
        }
    }
    
    @ViewBuilder
    private var mainInterface: some View {
        NavigationSplitView {
            NoteListView(appViewModel: appViewModel)
                .navigationSplitViewColumnWidth(min: 250, ideal: 280, max: 350)
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
                
                Menu {
                    Button("Settings...") {
                        showingSettings = true
                    }
                    .keyboardShortcut(",", modifiers: .command)
                    
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
    }
}

#Preview {
    ContentView()
}
