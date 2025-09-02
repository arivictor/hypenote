//
//  hypenoteApp.swift
//  hypenote
//
//  Created by Ari Laverty on 1/9/2025.
//

import SwiftUI

@main
struct hypenoteApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 1000, height: 700)
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Note") {
                    // This would be handled by the NotesStore
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("New Folder") {
                    // This would be handled by the NotesStore
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
    }
}
