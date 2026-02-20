//
//  NoteItem.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import Foundation
import GRDB

struct NoteItem: Codable, FetchableRecord, PersistableRecord, Identifiable, Sendable {
    var id: Int64?
    var content: String
    var createdAt: Date
    var updatedAt: Date

    static let databaseTableName = "notes"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
