//
//  KeyboardShortcuts.swift
//  hypenote
//
//  Keyboard shortcut definitions and handling
//

import SwiftUI

extension View {
    /// Add app-specific keyboard shortcuts
    func appKeyboardShortcuts(appViewModel: AppViewModel) -> some View {
        self.keyboardShortcut("n", modifiers: .command) {
            Task {
                await appViewModel.createNote()
            }
        }
        .keyboardShortcut("n", modifiers: [.command, .shift]) {
            appViewModel.showQuickEntry()
        }
        .keyboardShortcut("f", modifiers: .command) {
            // Focus search (handled by searchable modifier)
        }
    }
}