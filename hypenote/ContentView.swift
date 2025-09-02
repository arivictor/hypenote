//
//  ContentView.swift
//  hypenote
//
//  Created by Ari Laverty on 1/9/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: NotesStore
    
    var body: some View {
        NavigationSplitView {
            SidebarView(store: store)
                .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        } detail: {
            EditorView(store: store)
        }
        .navigationTitle("HypeNote")
    }
}

#Preview {
    ContentView()
        .environmentObject(NotesStore())
}
