//
//  Note.swift
//  hypenote
//
//  Core note model with Zettelkasten ID and metadata
//

import Foundation

struct Note: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var tags: [String]
    let createdAt: Date
    var updatedAt: Date
    var body: String
    
    /// Generate a Zettelkasten ID in format yyyymmddhhmmss
    static func generateZettelkastenID() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        return formatter.string(from: Date())
    }
    
    /// Create a new note with auto-generated ID
    init(title: String = "", tags: [String] = [], body: String = "") {
        self.id = Note.generateZettelkastenID()
        self.title = title
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
        self.body = body
    }
    
    /// Create note with specific ID (for loading from file)
    init(id: String, title: String, tags: [String], createdAt: Date, updatedAt: Date, body: String) {
        self.id = id
        self.title = title
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.body = body
    }
    
    /// Get slugified title for filename
    var slugifiedTitle: String {
        let cleanTitle = title.isEmpty ? "untitled" : title
        return cleanTitle
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
            .prefix(50)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
            .description
    }
    
    /// Generate filename for this note
    var filename: String {
        return "\(id) \(slugifiedTitle).md"
    }
    
    /// Update the note's updatedAt timestamp
    mutating func touch() {
        self.updatedAt = Date()
    }
    
    /// Extract wikilinks from the note body
    var wikilinks: [String] {
        let pattern = #"\[\[([^\]]+)\]\]"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let nsString = body as NSString
        let results = regex.matches(in: body, options: [], range: NSRange(location: 0, length: nsString.length))
        
        return results.map { match in
            nsString.substring(with: match.range(at: 1))
        }
    }
    
    /// Check if this note contains a wikilink to another note
    func containsWikilink(to target: String) -> Bool {
        return wikilinks.contains { link in
            link.lowercased() == target.lowercased() || 
            link == "#\(target)" // ID-based link
        }
    }
}