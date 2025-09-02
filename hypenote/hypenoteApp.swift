//
//  hypenoteApp.swift
//  hypenote
//
//  Created by Ari Laverty on 1/9/2025.
//

import SwiftUI

@main
struct hypenoteApp: App {
    @StateObject private var store = NotesStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
        .defaultSize(width: 1000, height: 700)
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Note") {
                    store.createNote()
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("New Folder") {
                    // This would show the new folder dialog
                    NotificationCenter.default.post(name: .newFolder, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
            
            CommandGroup(after: .toolbar) {
                Button("Focus Search") {
                    // Could focus search when implemented
                }
                .keyboardShortcut("f", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let newFolder = Notification.Name("newFolder")
}
