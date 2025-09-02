//
//  Folder.swift
//  hypenote
//
//  Created by Ari Laverty on 1/9/2025.
//

import Foundation

struct Folder: Identifiable, Codable {
    let id = UUID()
    var name: String
    var createdAt: Date
    var parentId: UUID?
    
    init(name: String, parentId: UUID? = nil) {
        self.name = name
        self.createdAt = Date()
        self.parentId = parentId
    }
}