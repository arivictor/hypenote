//
//  hypenoteTests.swift
//  hypenoteTests
//
//  Core functionality tests for hypenote
//

import Testing
@testable import hypenote

struct hypenoteTests {
    
    @Test func noteCreation() async throws {
        let note = Note(title: "Test Note", tags: ["test"], body: "This is a test note")
        
        #expect(!note.id.isEmpty)
        #expect(note.title == "Test Note")
        #expect(note.tags == ["test"])
        #expect(note.body == "This is a test note")
        #expect(note.id.count == 14) // yyyymmddhhmmss format
    }
    
    @Test func zettelkastenIDGeneration() async throws {
        let id1 = Note.generateZettelkastenID()
        let id2 = Note.generateZettelkastenID()
        
        #expect(id1.count == 14)
        #expect(id2.count == 14)
        
        // IDs should be different (unless generated in same second)
        if id1 == id2 {
            // Wait and try again
            try await Task.sleep(nanoseconds: 1_100_000_000) // 1.1 seconds
            let id3 = Note.generateZettelkastenID()
            #expect(id1 != id3)
        }
    }
    
    @Test func slugifiedTitle() async throws {
        let note1 = Note(title: "My Test Note", body: "")
        #expect(note1.slugifiedTitle == "my-test-note")
        
        let note2 = Note(title: "Note with Special Characters!@#", body: "")
        #expect(note2.slugifiedTitle == "note-with-special-characters")
        
        let note3 = Note(title: "", body: "")
        #expect(note3.slugifiedTitle == "untitled")
    }
    
    @Test func filename() async throws {
        let note = Note(title: "Test Note", body: "")
        let expectedFilename = "\(note.id) test-note.md"
        #expect(note.filename == expectedFilename)
    }
    
    @Test func wikilinkExtraction() async throws {
        let note = Note(
            title: "Test Note",
            body: "This note links to [[Another Note]] and [[#20250109140000]] and [[Third Note]]."
        )
        
        let wikilinks = note.wikilinks
        #expect(wikilinks.count == 3)
        #expect(wikilinks.contains("Another Note"))
        #expect(wikilinks.contains("#20250109140000"))
        #expect(wikilinks.contains("Third Note"))
    }
    
    @Test func wikilinkContains() async throws {
        let note = Note(
            title: "Test Note",
            body: "This note links to [[Target Note]] and [[#123456789]]."
        )
        
        #expect(note.containsWikilink(to: "Target Note"))
        #expect(note.containsWikilink(to: "123456789"))
        #expect(!note.containsWikilink(to: "Non-existent Note"))
    }
    
    @Test func yamlFrontMatterGeneration() async throws {
        let note = Note(
            id: "20250109140000",
            title: "Test Note",
            tags: ["test", "sample"],
            createdAt: Date(timeIntervalSince1970: 1704808800), // 2024-01-09 14:00:00 UTC
            updatedAt: Date(timeIntervalSince1970: 1704808800),
            body: "Test body"
        )
        
        let frontMatter = YAMLParser.generateFrontMatter(for: note)
        
        #expect(frontMatter.contains("id: 20250109140000"))
        #expect(frontMatter.contains("title: Test Note"))
        #expect(frontMatter.contains("tags: [test, sample]"))
        #expect(frontMatter.contains("---"))
    }
    
    @Test func yamlParsing() async throws {
        let content = """
        ---
        id: 20250109140000
        title: Test Note
        tags: [test, sample]
        createdAt: 2024-01-09T14:00:00.000Z
        updatedAt: 2024-01-09T14:00:00.000Z
        ---
        
        This is the body content.
        """
        
        let (metadata, body) = YAMLParser.parseFrontMatter(from: content)
        
        #expect(metadata["id"] as? String == "20250109140000")
        #expect(metadata["title"] as? String == "Test Note")
        #expect(metadata["tags"] as? [String] == ["test", "sample"])
        #expect(body.trimmingCharacters(in: .whitespacesAndNewlines) == "This is the body content.")
    }
    
    @Test func noteTouch() async throws {
        var note = Note(title: "Test Note", body: "")
        let originalUpdatedAt = note.updatedAt
        
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        note.touch()
        
        #expect(note.updatedAt > originalUpdatedAt)
    }
}
