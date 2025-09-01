//
//  YAMLParser.swift
//  hypenote
//
//  Light YAML parser for note front matter using regex and line scanning
//

import Foundation

struct YAMLParser {
    /// Parse YAML front matter from markdown content
    static func parseFrontMatter(from content: String) -> (metadata: [String: Any], body: String) {
        let lines = content.components(separatedBy: .newlines)
        
        guard lines.count > 0 && lines[0].trimmingCharacters(in: .whitespaces) == "---" else {
            // No front matter found
            return (metadata: [:], body: content)
        }
        
        var metadata: [String: Any] = [:]
        var frontMatterLines: [String] = []
        var bodyStartIndex = 0
        
        // Find the end of front matter
        var foundEnd = false
        for (index, line) in lines.enumerated() {
            if index == 0 { continue } // Skip first ---
            
            if line.trimmingCharacters(in: .whitespaces) == "---" {
                bodyStartIndex = index + 1
                foundEnd = true
                break
            }
            
            frontMatterLines.append(line)
        }
        
        guard foundEnd else {
            // Malformed front matter
            return (metadata: [:], body: content)
        }
        
        // Parse YAML key-value pairs
        for line in frontMatterLines {
            if let (key, value) = parseYAMLLine(line) {
                metadata[key] = value
            }
        }
        
        // Extract body
        let bodyLines = Array(lines[bodyStartIndex...])
        let body = bodyLines.joined(separator: "\n")
        
        return (metadata: metadata, body: body)
    }
    
    /// Parse a single YAML line
    private static func parseYAMLLine(_ line: String) -> (String, Any)? {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        
        // Skip empty lines and comments
        if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
            return nil
        }
        
        // Simple key: value parsing
        let components = trimmedLine.components(separatedBy: ": ")
        guard components.count >= 2 else { return nil }
        
        let key = components[0].trimmingCharacters(in: .whitespaces)
        let valueString = components[1...].joined(separator: ": ").trimmingCharacters(in: .whitespaces)
        
        // Parse different value types
        let value = parseYAMLValue(valueString)
        
        return (key, value)
    }
    
    /// Parse YAML value (string, array, date, etc.)
    private static func parseYAMLValue(_ valueString: String) -> Any {
        let trimmed = valueString.trimmingCharacters(in: .whitespaces)
        
        // Array format: [item1, item2, item3]
        if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
            let arrayContent = String(trimmed.dropFirst().dropLast())
            let items = arrayContent.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            return items
        }
        
        // Date format (ISO 8601)
        if let date = ISO8601DateFormatter().date(from: trimmed) {
            return date
        }
        
        // Try alternative date format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = dateFormatter.date(from: trimmed) {
            return date
        }
        
        // Default to string
        return trimmed
    }
    
    /// Generate YAML front matter from note metadata
    static func generateFrontMatter(for note: Note) -> String {
        var yaml = ["---"]
        
        yaml.append("id: \(note.id)")
        yaml.append("title: \(note.title)")
        
        let formatter = ISO8601DateFormatter()
        yaml.append("createdAt: \(formatter.string(from: note.createdAt))")
        yaml.append("updatedAt: \(formatter.string(from: note.updatedAt))")
        
        if !note.tags.isEmpty {
            let tagsString = "[\(note.tags.joined(separator: ", "))]"
            yaml.append("tags: \(tagsString)")
        } else {
            yaml.append("tags: []")
        }
        
        yaml.append("---")
        yaml.append("")
        
        return yaml.joined(separator: "\n")
    }
    
    /// Parse note from file content
    static func parseNote(from content: String, fileURL: URL) -> Note? {
        let (metadata, body) = parseFrontMatter(from: content)
        
        guard let id = metadata["id"] as? String else {
            return nil
        }
        
        let title = metadata["title"] as? String ?? ""
        let tags = metadata["tags"] as? [String] ?? []
        let createdAt = metadata["createdAt"] as? Date ?? Date()
        let updatedAt = metadata["updatedAt"] as? Date ?? Date()
        
        return Note(
            id: id,
            title: title,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt,
            body: body
        )
    }
}