# hypenote

![hypenote](cover.png)

A hyper minimal, fast Markdown Zettelkasten-style note app for macOS.

## Features

- **Zettelkasten ID System**: Each note has a unique ID in format `yyyymmddhhmmss`
- **File-based Storage**: Notes saved as UTF-8 .md files with YAML front matter
- **Wikilinks**: `[[Note Title]]` and `[[#ID]]` linking support
- **Live Preview**: Split-view editor with real-time Markdown preview
- **Backlinks**: Automatic discovery and display of incoming links
- **Search & Tags**: Full-text search with tag filtering
- **Local Graph**: Visual representation of note connections
- **Atomic File Operations**: Safe writes with temporary file replacement

## System Requirements

- macOS 14.0 or later
- Swift 5.9 or later

## Build Instructions

1. Clone the repository:
   ```bash
   git clone https://github.com/arivictor/hypenote.git
   cd hypenote
   ```

2. Open the project in Xcode:
   ```bash
   open hypenote.xcodeproj
   ```

3. Build and run (⌘R)

## Keyboard Shortcuts

- **⌘N** - New Note
- **⌘S** - Save Note
- **⌘⇧P** - Toggle Preview
- **⌘F** - Focus Search

## Project Architecture

### Core Components

- **Models/**: Core data structures (`Note`, `VaultManager`)
- **Storage/**: File operations and YAML parsing (`FileStorage`, `YAMLParser`)
- **Index/**: In-memory indexing and search (`NoteIndex`)
- **Views/**: SwiftUI interface components
- **ViewModels/**: MVVM view model layer

### Data Flow

1. **VaultManager** handles vault location and directory setup
2. **FileStorage** manages atomic file operations
3. **NoteIndex** maintains in-memory search indexes and backlinks
4. **AppViewModel** coordinates between storage and UI layers

### File Format

Notes are stored as Markdown files with YAML front matter:

```yaml
---
id: 20250109143022
title: My Note Title
createdAt: 2025-01-09T14:30:22.000Z
updatedAt: 2025-01-09T14:35:45.000Z
tags: [research, ideas]
---

# My Note Title

This is the note body with [[wikilink]] to another note.
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

MIT License - see LICENSE file for details.
