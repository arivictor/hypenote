//
//  FileWatcher.swift
//  hypenote
//
//  File system monitoring for external changes
//

import Foundation
import Combine

@MainActor
class FileWatcher: ObservableObject {
    private var dispatchSource: DispatchSourceFileSystemObject?
    private let fileManager = FileManager.default
    
    var onFileChanged: (() -> Void)?
    
    /// Start watching a directory for changes
    func startWatching(url: URL) {
        stopWatching()
        
        guard url.hasDirectoryPath else { return }
        
        let fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor != -1 else { return }
        
        dispatchSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename],
            queue: DispatchQueue.main
        )
        
        dispatchSource?.setEventHandler { [weak self] in
            self?.onFileChanged?()
        }
        
        dispatchSource?.setCancelHandler {
            close(fileDescriptor)
        }
        
        dispatchSource?.resume()
    }
    
    /// Stop watching for file changes
    func stopWatching() {
        dispatchSource?.cancel()
        dispatchSource = nil
    }
    
    deinit {
        stopWatching()
    }
}