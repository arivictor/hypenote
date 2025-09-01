//
//  HotkeyManager.swift
//  hypenote
//
//  Global hotkey registration and handling
//

import AppKit
import Carbon

class HotkeyManager: ObservableObject {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerUPP?
    private var eventHandlerRef: EventHandlerRef?
    private var eventHandlerInstalled = false
    
    private let hotkeySignature: FourCharCode = 0x68706E74 // 'hpnt'
    private let hotkeyID: UInt32 = 1
    
    var onHotkeyPressed: (() -> Void)?
    
    init() {
        setupEventHandler()
    }
    
    deinit {
        unregisterHotkey()
        removeEventHandler()
    }
    
    /// Register global hotkey (Cmd+Shift+N by default)
    func registerHotkey(keyCode: UInt32 = 45, modifiers: UInt32 = UInt32(cmdKey + shiftKey)) -> Bool {
        unregisterHotkey() // Remove existing hotkey first
        
        let eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            EventHotKeyID(signature: hotkeySignature, id: hotkeyID),
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr {
            self.hotKeyRef = hotKeyRef
            return true
        } else {
            print("Failed to register hotkey: \(status)")
            return false
        }
    }
    
    /// Unregister global hotkey
    func unregisterHotkey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }
    
    private func setupEventHandler() {
        eventHandler = NewEventHandlerUPP { (nextHandler, theEvent, userData) -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            
            let hotkeyManager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                theEvent,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            
            if status == noErr && hotKeyID.signature == hotkeyManager.hotkeySignature && hotKeyID.id == hotkeyManager.hotkeyID {
                DispatchQueue.main.async {
                    hotkeyManager.onHotkeyPressed?()
                }
                return noErr
            }
            
            return OSStatus(eventNotHandledErr)
        }
        
        guard let eventHandler = eventHandler else { return }
        
        let eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        var eventHandlerRef: EventHandlerRef?
        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            eventHandler,
            1,
            [eventType],
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
        
        self.eventHandlerRef = eventHandlerRef
        eventHandlerInstalled = (status == noErr)
        
        if !eventHandlerInstalled {
            print("Failed to install event handler: \(status)")
        }
    }
    
    private func removeEventHandler() {
        if eventHandlerInstalled {
            if let eventHandlerRef = eventHandlerRef {
                RemoveEventHandler(eventHandlerRef)
                self.eventHandlerRef = nil
            }
            if let eventHandler = eventHandler {
                DisposeEventHandlerUPP(eventHandler)
                self.eventHandler = nil
            }
            eventHandlerInstalled = false
        }
    }
}