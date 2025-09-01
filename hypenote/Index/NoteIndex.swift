//
//  NoteIndex.swift
//  hypenote
//
//  In-memory index for notes with backlinks and search capabilities
//

import Foundation
import Combine

@MainActor
class NoteIndex: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var selectedTags: Set<String> = []
    
    private var backlinksIndex: [String: Set<String>] = [:]
    private var tagsIndex: [String: Set<String>] = [:]
    private var titleIndex: [String: String] = [:]
    
    private let fileStorage: FileStorage
    private var cancellables = Set<AnyCancellable>()
    
    // Debouncing for note updates to prevent list bouncing
    private var pendingUpdates: [String: Note] = [:]
    private var updateTimer: Timer?
    private var isActivelyEditing = false
    
    deinit {
        updateTimer?.invalidate()
    }
    
    init(fileStorage: FileStorage) {
        self.fileStorage = fileStorage
        setupSearchPublisher()
    }
    
    /// Setup search text publisher with debouncing
    private func setupSearchPublisher() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    /// Load all notes and rebuild indexes
    func loadNotes() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let loadedNotes = try await fileStorage.loadAllNotes()
            notes = loadedNotes.sorted { $0.updatedAt > $1.updatedAt }
            rebuildIndexes()
        } catch {
            print("Error loading notes: \(error)")
        }
    }
    
    /// Add new note to index
    func addNote(_ note: Note) {
        notes.append(note)
        notes.sort { $0.updatedAt > $1.updatedAt }
        indexNote(note)
    }
    
    /// Update existing note in index with debouncing to prevent list bouncing
    func updateNote(_ note: Note) {
        // Store the pending update
        pendingUpdates[note.id] = note
        
        // Cancel existing timer
        updateTimer?.invalidate()
        
        // If actively editing, debounce the update
        if isActivelyEditing {
            updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
                self?.processPendingUpdates()
            }
        } else {
            // Process immediately if not actively editing
            processPendingUpdates()
        }
    }
    
    /// Process all pending note updates
    private func processPendingUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
        
        for (noteId, note) in pendingUpdates {
            performImmediateUpdate(note)
        }
        
        pendingUpdates.removeAll()
        
        // Only sort if not actively editing to prevent bouncing
        if !isActivelyEditing {
            notes.sort { $0.updatedAt > $1.updatedAt }
        }
    }
    
    /// Perform immediate note update without sorting
    private func performImmediateUpdate(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            let oldNote = notes[index]
            notes[index] = note
            
            // Remove old indexing
            removeNoteFromIndexes(oldNote)
            
            // Add new indexing
            indexNote(note)
        }
    }
    
    /// Set active editing state to control list reordering
    func setActivelyEditing(_ editing: Bool) {
        isActivelyEditing = editing
        
        // If we're done editing, process any pending updates and sort
        if !editing {
            processPendingUpdates()
        }
    }
    
    /// Remove note from index
    func removeNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        removeNoteFromIndexes(note)
    }
    
    /// Get backlinks for a specific note
    func getBacklinks(for note: Note) -> [Note] {
        let backlinkIds = backlinksIndex[note.id] ?? []
        return notes.filter { backlinkIds.contains($0.id) }
    }
    
    /// Get all unique tags with counts
    var tagCounts: [(tag: String, count: Int)] {
        var counts: [String: Int] = [:]
        
        for note in filteredNotes {
            for tag in note.tags {
                counts[tag, default: 0] += 1
            }
        }
        
        return counts.map { (tag: $0.key, count: $0.value) }
            .sorted { $0.tag < $1.tag }
    }
    
    /// Get filtered notes based on search and tags
    var filteredNotes: [Note] {
        var filtered = notes
        
        // Filter by tags
        if !selectedTags.isEmpty {
            filtered = filtered.filter { note in
                !Set(note.tags).isDisjoint(with: selectedTags)
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            filtered = filtered.filter { note in
                note.title.lowercased().contains(lowercasedSearch) ||
                note.body.lowercased().contains(lowercasedSearch) ||
                note.tags.contains { $0.lowercased().contains(lowercasedSearch) }
            }
        }
        
        return filtered
    }
    
    /// Find note by title (case insensitive)
    func findNote(byTitle title: String) -> Note? {
        let lowercasedTitle = title.lowercased()
        return notes.first { $0.title.lowercased() == lowercasedTitle }
    }
    
    /// Find note by ID
    func findNote(byId id: String) -> Note? {
        return notes.first { $0.id == id }
    }
    
    /// Find notes that match wikilink
    func findNotes(matching wikilink: String) -> [Note] {
        // Check if it's an ID-based link
        if wikilink.hasPrefix("#") {
            let id = String(wikilink.dropFirst())
            if let note = findNote(byId: id) {
                return [note]
            }
        }
        
        // Search by title
        let lowercasedLink = wikilink.lowercased()
        return notes.filter { $0.title.lowercased().contains(lowercasedLink) }
    }
    
    /// Update wikilinks when a note is renamed
    func updateWikilinks(oldTitle: String, newTitle: String, noteId: String) async {
        let oldTitlePattern = "\\[\\[\(NSRegularExpression.escapedPattern(for: oldTitle))\\]\\]"
        let idPattern = "\\[\\[#\(NSRegularExpression.escapedPattern(for: noteId))\\]\\]"
        
        for var note in notes {
            if note.id == noteId { continue } // Don't update the renamed note itself
            
            var updated = false
            
            // Replace title-based links
            if let regex = try? NSRegularExpression(pattern: oldTitlePattern, options: .caseInsensitive) {
                let newBody = regex.stringByReplacingMatches(
                    in: note.body,
                    options: [],
                    range: NSRange(location: 0, length: note.body.count),
                    withTemplate: "[[\(newTitle)]]"
                )
                
                if newBody != note.body {
                    note.body = newBody
                    note.touch()
                    updated = true
                }
            }
            
            if updated {
                updateNote(note)
                
                // Save updated note
                do {
                    try await fileStorage.saveNote(note)
                } catch {
                    print("Error updating wikilinks in note \(note.id): \(error)")
                }
            }
        }
    }
    
    /// Rebuild all indexes
    private func rebuildIndexes() {
        backlinksIndex.removeAll()
        tagsIndex.removeAll()
        titleIndex.removeAll()
        
        for note in notes {
            indexNote(note)
        }
    }
    
    /// Index a single note
    private func indexNote(_ note: Note) {
        // Index title
        titleIndex[note.title.lowercased()] = note.id
        
        // Index tags
        for tag in note.tags {
            tagsIndex[tag, default: []].insert(note.id)
        }
        
        // Index backlinks
        for wikilink in note.wikilinks {
            if wikilink.hasPrefix("#") {
                // ID-based link
                let targetId = String(wikilink.dropFirst())
                backlinksIndex[targetId, default: []].insert(note.id)
            } else {
                // Title-based link - find target note
                if let targetNote = findNote(byTitle: wikilink) {
                    backlinksIndex[targetNote.id, default: []].insert(note.id)
                }
            }
        }
    }
    
    /// Remove note from all indexes
    private func removeNoteFromIndexes(_ note: Note) {
        // Remove from title index
        titleIndex.removeValue(forKey: note.title.lowercased())
        
        // Remove from tags index
        for tag in note.tags {
            tagsIndex[tag]?.remove(note.id)
            if tagsIndex[tag]?.isEmpty == true {
                tagsIndex.removeValue(forKey: tag)
            }
        }
        
        // Remove from backlinks index
        for key in backlinksIndex.keys {
            backlinksIndex[key]?.remove(note.id)
            if backlinksIndex[key]?.isEmpty == true {
                backlinksIndex.removeValue(forKey: key)
            }
        }
    }
    
    /// Toggle tag selection
    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    /// Clear all filters
    func clearFilters() {
        searchText = ""
        selectedTags.removeAll()
    }
}