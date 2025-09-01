//
//  hypenoteApp.swift
//  hypenote
//
//  Main app entry point
//

import SwiftUI

@main
struct hypenoteApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Note") {
                    // TODO: Send new note command
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandGroup(after: .saveItem) {
                Button("Toggle Preview") {
                    // TODO: Send toggle preview command
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
            }
        }
    }
}
