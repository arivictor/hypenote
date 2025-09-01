//
//  VaultManager.swift
//  hypenote
//
//  Manages vault location and note storage operations
//

import Foundation
import SwiftUI

@MainActor
class VaultManager: ObservableObject {
    @Published var vaultURL: URL?
    @Published var isLoading = false
    @Published var error: VaultError?
    
    private let userDefaults = UserDefaults.standard
    private let vaultURLKey = "VaultURL"
    
    enum VaultError: LocalizedError {
        case noVaultSelected
        case invalidVaultPath
        case fileSystemError(String)
        case parseError(String)
        
        var errorDescription: String? {
            switch self {
            case .noVaultSelected:
                return "No vault location selected"
            case .invalidVaultPath:
                return "Invalid vault path"
            case .fileSystemError(let message):
                return "File system error: \(message)"
            case .parseError(let message):
                return "Parse error: \(message)"
            }
        }
    }
    
    init() {
        loadVaultURL()
    }
    
    /// Load vault URL from UserDefaults
    private func loadVaultURL() {
        if let data = userDefaults.data(forKey: vaultURLKey) {
            var isStale: Bool = false
            if let url = try? URL(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale) {
                self.vaultURL = url
            }
        }
    }
    
    /// Set vault URL and save bookmark
    func setVaultURL(_ url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            userDefaults.set(bookmarkData, forKey: vaultURLKey)
            self.vaultURL = url
            self.error = nil
        } catch {
            self.error = .fileSystemError(error.localizedDescription)
        }
    }
    
    /// Create default vault directory in app container
    func createDefaultVault() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let appSupportURL = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            
            let vaultURL = appSupportURL.appendingPathComponent("hypenote-vault")
            
            try FileManager.default.createDirectory(
                at: vaultURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
            
            setVaultURL(vaultURL)
        } catch {
            self.error = .fileSystemError(error.localizedDescription)
        }
    }
    
    /// Get notes directory URL
    var notesURL: URL? {
        return vaultURL?.appendingPathComponent("notes")
    }
    
    /// Get templates directory URL
    var templatesURL: URL? {
        return vaultURL?.appendingPathComponent("templates")
    }
    
    /// Get trash directory URL
    var trashURL: URL? {
        return vaultURL?.appendingPathComponent("trash")
    }
    
    /// Ensure necessary directories exist
    func ensureDirectoriesExist() throws {
        guard let vaultURL = vaultURL else {
            throw VaultError.noVaultSelected
        }
        
        let directories = [
            vaultURL.appendingPathComponent("notes"),
            vaultURL.appendingPathComponent("templates"),
            vaultURL.appendingPathComponent("trash")
        ]
        
        for directory in directories {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
    
    /// Check if vault is properly configured
    var isVaultReady: Bool {
        guard let vaultURL = vaultURL else { return false }
        
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: vaultURL.path,
            isDirectory: &isDirectory
        )
        
        return exists && isDirectory.boolValue
    }
}