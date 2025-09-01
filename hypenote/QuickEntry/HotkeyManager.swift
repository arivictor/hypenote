//
//  HotkeyManager.swift
//  hypenote
//
//  Global hotkey registration and handling
//

import AppKit

class HotkeyManager: ObservableObject {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    
    var onHotkeyPressed: (() -> Void)?
    
    init() {
        // No setup needed for NSEvent monitoring
    }
    
    deinit {
        unregisterHotkey()
    }
    
    /// Register global hotkey (Cmd+Shift+N by default)
    func registerHotkey(keyCode: UInt32 = 45, modifiers: UInt32 = 0) -> Bool {
        unregisterHotkey() // Remove existing monitors first
        
        // Convert keyCode to character (45 is 'n')
        let keyCharacter = "n"
        let modifierFlags: NSEvent.ModifierFlags = [.command, .shift]
        
        // Monitor global key events
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(modifierFlags) && 
               event.charactersIgnoringModifiers?.lowercased() == keyCharacter {
                DispatchQueue.main.async {
                    self?.onHotkeyPressed?()
                }
            }
        }
        
        // Monitor local key events (when app is focused)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(modifierFlags) && 
               event.charactersIgnoringModifiers?.lowercased() == keyCharacter {
                DispatchQueue.main.async {
                    self?.onHotkeyPressed?()
                }
                return nil // Consume the event
            }
            return event
        }
        
        return globalMonitor != nil || localMonitor != nil
    }
    
    /// Unregister global hotkey
    func unregisterHotkey() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
}