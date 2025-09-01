//
//  QuickEntryWindowController.swift
//  hypenote
//
//  Global quick entry window for capturing notes
//

import SwiftUI
import AppKit

class QuickEntryWindowController: NSWindowController {
    private var appViewModel: AppViewModel?
    
    convenience init(appViewModel: AppViewModel) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Quick Entry"
        window.level = .floating
        window.isMovableByWindowBackground = true
        
        self.init(window: window)
        self.appViewModel = appViewModel
        
        let contentView = QuickEntryView(
            appViewModel: appViewModel,
            onClose: { [weak self] in
                self?.close()
            }
        )
        
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct QuickEntryView: View {
    @ObservedObject var appViewModel: AppViewModel
    let onClose: () -> Void
    
    @State private var title = ""
    @State private var body = ""
    @State private var tags = ""
    @State private var isCreating = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Quick Note Entry")
                    .font(.headline)
                
                Spacer()
                
                Button("Cancel") {
                    onClose()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            
            // Title field
            VStack(alignment: .leading, spacing: 4) {
                Text("Title")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("Note title (optional)", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        // Focus moves to body
                    }
            }
            
            // Tags field
            VStack(alignment: .leading, spacing: 4) {
                Text("Tags")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("Tags (comma separated)", text: $tags)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Body field
            VStack(alignment: .leading, spacing: 4) {
                Text("Content")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $body)
                    .font(.system(.body, design: .monospaced))
                    .border(Color.gray.opacity(0.3), width: 1)
                    .cornerRadius(4)
            }
            
            // Actions
            HStack {
                Spacer()
                
                Button("Create Note") {
                    createNote()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(body.isEmpty)
            }
        }
        .padding()
        .frame(width: 500, height: 300)
        .onAppear {
            // Focus the body field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // TextEditor focus is handled automatically
            }
        }
    }
    
    private func createNote() {
        guard !body.isEmpty else { return }
        
        isCreating = true
        
        let parsedTags = tags
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        Task {
            await appViewModel.createNote(
                title: title.isEmpty ? "Quick Note" : title,
                body: body,
                tags: parsedTags
            )
            
            await MainActor.run {
                onClose()
            }
        }
    }
}

#Preview {
    QuickEntryView(
        appViewModel: AppViewModel(),
        onClose: {}
    )
}