//
//  TodoItem.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import Foundation
import GRDB

struct TodoItem: Codable, FetchableRecord, PersistableRecord, Identifiable, Sendable {
    var id: Int64?
    var content: String
    var isDone: Bool
    var createdAt: Date
    var updatedAt: Date

    static let databaseTableName = "todos"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
