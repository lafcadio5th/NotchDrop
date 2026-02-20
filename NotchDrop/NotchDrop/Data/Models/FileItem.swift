//
//  FileItem.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import Foundation
import GRDB

struct FileItem: Codable, FetchableRecord, PersistableRecord, Identifiable, Sendable {
    var id: Int64?
    var originalName: String
    var storedPath: String
    var fileSize: Int64
    var thumbnailPath: String?
    var createdAt: Date

    static let databaseTableName = "files"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
