//
//  Note.swift
//  hypenote
//
//  Created by Ari Laverty on 1/9/2025.
//

import Foundation

struct Note: Identifiable, Codable {
    let id = UUID()
    var title: String
    var content: String
    var createdAt: Date
    var modifiedAt: Date
    var folderId: UUID?
    
    init(title: String = "Untitled", content: String = "", folderId: UUID? = nil) {
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.folderId = folderId
    }
    
    mutating func updateContent(_ newContent: String) {
        self.content = newContent
        self.modifiedAt = Date()
        
        // Auto-update title from first line if title is default
        if title == "Untitled" || title.isEmpty {
            let firstLine = newContent.components(separatedBy: .newlines).first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !firstLine.isEmpty {
                self.title = String(firstLine.prefix(50)) // Limit title length
            }
        }
    }
}