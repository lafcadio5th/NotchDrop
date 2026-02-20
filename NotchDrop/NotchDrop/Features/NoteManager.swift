//
//  NoteManager.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import Foundation
import Combine

/// Manages note items, wrapping DatabaseManager with business logic
/// including free tier quota enforcement and content validation.
class NoteManager: ObservableObject {
    static let shared = NoteManager()

    @Published var notes: [NoteItem] = []

    /// Reloads all notes from the database.
    func refresh() {
        notes = (try? DatabaseManager.shared.fetchNotes()) ?? []
    }

    /// Adds a new note.
    /// - Parameter content: The note text content.
    /// - Returns: `true` if the note was added successfully, `false` if
    ///   the free tier limit is reached or the content is empty.
    func addNote(_ content: String) -> Bool {
        guard ProManager.shared.canAddNote() else { return false }
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        _ = try? DatabaseManager.shared.addNote(content)
        refresh()
        return true
    }

    /// Permanently deletes a note.
    /// - Parameter id: The note's database ID.
    func deleteNote(_ id: Int64) {
        try? DatabaseManager.shared.deleteNote(id)
        refresh()
    }
}
