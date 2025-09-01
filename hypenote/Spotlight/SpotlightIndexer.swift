//
//  SpotlightIndexer.swift
//  hypenote
//
//  Core Spotlight indexing for system-wide note search
//

import Foundation
import CoreSpotlight
import UniformTypeIdentifiers

@MainActor
class SpotlightIndexer: ObservableObject {
    private let searchableIndex = CSSearchableIndex.default()
    private let bundleIdentifier = Bundle.main.bundleIdentifier ?? "ari.hypenote"
    
    /// Index a single note for Spotlight search
    func indexNote(_ note: Note) async {
        let searchableItem = createSearchableItem(for: note)
        
        do {
            try await searchableIndex.indexSearchableItems([searchableItem])
        } catch {
            print("Error indexing note \(note.id): \(error)")
        }
    }
    
    /// Index multiple notes
    func indexNotes(_ notes: [Note]) async {
        let searchableItems = notes.map { createSearchableItem(for: $0) }
        
        do {
            try await searchableIndex.indexSearchableItems(searchableItems)
        } catch {
            print("Error indexing notes: \(error)")
        }
    }
    
    /// Remove a note from Spotlight index
    func removeNote(_ note: Note) async {
        do {
            try await searchableIndex.deleteSearchableItems(withIdentifiers: [note.id])
        } catch {
            print("Error removing note \(note.id) from index: \(error)")
        }
    }
    
    /// Remove all notes from Spotlight index
    func removeAllNotes() async {
        do {
            try await searchableIndex.deleteSearchableItems(withDomainIdentifiers: [bundleIdentifier])
        } catch {
            print("Error removing all notes from index: \(error)")
        }
    }
    
    /// Create a searchable item for a note
    private func createSearchableItem(for note: Note) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(contentType: UTType.text)
        
        // Basic metadata
        attributeSet.title = note.title.isEmpty ? "Untitled" : note.title
        attributeSet.contentDescription = note.body
        attributeSet.identifier = note.id
        
        // Dates
        attributeSet.contentCreationDate = note.createdAt
        attributeSet.contentModificationDate = note.updatedAt
        
        // Keywords (tags)
        attributeSet.keywords = note.tags
        
        // Content for full-text search
        attributeSet.textContent = "\(note.title) \(note.body) \(note.tags.joined(separator: " "))"
        
        // Custom attributes
        attributeSet.setValue(note.id as NSString, forCustomKey: CSCustomAttributeKey(keyName: "zettelkasten_id")!)
        attributeSet.setValue(note.filename as NSString, forCustomKey: CSCustomAttributeKey(keyName: "filename")!)
        
        // Domain identifier for easy removal
        attributeSet.domainIdentifier = bundleIdentifier
        
        // Create searchable item
        let searchableItem = CSSearchableItem(
            uniqueIdentifier: note.id,
            domainIdentifier: bundleIdentifier,
            attributeSet: attributeSet
        )
        
        return searchableItem
    }
    
    /// Check if Spotlight indexing is available
    var isIndexingAvailable: Bool {
        return CSSearchableIndex.isIndexingAvailable()
    }
    
    /// Get indexing status
    func checkIndexingStatus() async -> String {
        do {
            let status = try await searchableIndex.fetchLastClientState()
            return status.isEmpty ? "Not indexed" : "Indexed"
        } catch {
            return "Error checking status"
        }
    }
}