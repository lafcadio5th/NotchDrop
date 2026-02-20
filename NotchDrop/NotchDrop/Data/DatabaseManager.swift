//
//  DatabaseManager.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import Foundation
import GRDB

/// Manages all database operations for NotchDrop.
/// Marked nonisolated to opt out of MainActor default isolation,
/// since GRDB database closures run synchronously and must not be
/// confined to MainActor.
nonisolated class DatabaseManager: @unchecked Sendable {
    nonisolated static let shared = DatabaseManager()

    private let dbPool: DatabasePool?

    private init() {
        self.dbPool = DatabaseManager.createPool()
    }

    private static func createPool() -> DatabasePool? {
        do {
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!
            let dbDir = appSupport.appendingPathComponent("NotchDrop", isDirectory: true)
            try FileManager.default.createDirectory(at: dbDir, withIntermediateDirectories: true)

            let dbPath = dbDir.appendingPathComponent("notchdrop.sqlite").path
            let pool = try DatabasePool(path: dbPath)

            try migrate(pool)
            NSLog("Database initialized at: \(dbPath)")
            return pool
        } catch {
            NSLog("Database init error: \(error)")
            return nil
        }
    }

    private static func migrate(_ dbPool: DatabasePool) throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_create_tables") { db in
            try db.create(table: "todos") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("content", .text).notNull()
                t.column("isDone", .boolean).notNull().defaults(to: false)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }

            try db.create(table: "notes") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("content", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }

            try db.create(table: "files") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("originalName", .text).notNull()
                t.column("storedPath", .text).notNull()
                t.column("fileSize", .integer).notNull()
                t.column("thumbnailPath", .text)
                t.column("createdAt", .datetime).notNull()
            }
        }

        try migrator.migrate(dbPool)
    }

    // MARK: - Todos

    func addTodo(_ content: String) throws -> TodoItem {
        guard let dbPool = dbPool else { throw DatabaseError(message: "DB not initialized") }
        return try dbPool.write { db in
            let todo = TodoItem(
                content: content,
                isDone: false,
                createdAt: Date(),
                updatedAt: Date()
            )
            return try todo.inserted(db)
        }
    }

    func fetchActiveTodos() throws -> [TodoItem] {
        guard let dbPool = dbPool else { return [] }
        return try dbPool.read { db in
            try TodoItem
                .filter(Column("isDone") == false)
                .order(Column("createdAt").desc)
                .fetchAll(db)
        }
    }

    func fetchAllTodos() throws -> [TodoItem] {
        guard let dbPool = dbPool else { return [] }
        return try dbPool.read { db in
            try TodoItem.order(Column("createdAt").desc).fetchAll(db)
        }
    }

    func toggleTodo(_ id: Int64) throws {
        guard let dbPool = dbPool else { return }
        try dbPool.write { db in
            if var todo = try TodoItem.fetchOne(db, key: id) {
                todo.isDone.toggle()
                todo.updatedAt = Date()
                try todo.update(db)
            }
        }
    }

    func deleteTodo(_ id: Int64) throws {
        guard let dbPool = dbPool else { return }
        try dbPool.write { db in
            _ = try TodoItem.deleteOne(db, key: id)
        }
    }

    func activeTodoCount() throws -> Int {
        guard let dbPool = dbPool else { return 0 }
        return try dbPool.read { db in
            try TodoItem.filter(Column("isDone") == false).fetchCount(db)
        }
    }

    // MARK: - Notes

    func addNote(_ content: String) throws -> NoteItem {
        guard let dbPool = dbPool else { throw DatabaseError(message: "DB not initialized") }
        return try dbPool.write { db in
            let note = NoteItem(
                content: content,
                createdAt: Date(),
                updatedAt: Date()
            )
            return try note.inserted(db)
        }
    }

    func fetchNotes() throws -> [NoteItem] {
        guard let dbPool = dbPool else { return [] }
        return try dbPool.read { db in
            try NoteItem.order(Column("createdAt").desc).fetchAll(db)
        }
    }

    func deleteNote(_ id: Int64) throws {
        guard let dbPool = dbPool else { return }
        try dbPool.write { db in
            _ = try NoteItem.deleteOne(db, key: id)
        }
    }

    func noteCount() throws -> Int {
        guard let dbPool = dbPool else { return 0 }
        return try dbPool.read { db in
            try NoteItem.fetchCount(db)
        }
    }

    // MARK: - Files

    func addFile(
        originalName: String,
        storedPath: String,
        fileSize: Int64,
        thumbnailPath: String?
    ) throws -> FileItem {
        guard let dbPool = dbPool else { throw DatabaseError(message: "DB not initialized") }
        return try dbPool.write { db in
            let file = FileItem(
                originalName: originalName,
                storedPath: storedPath,
                fileSize: fileSize,
                thumbnailPath: thumbnailPath,
                createdAt: Date()
            )
            return try file.inserted(db)
        }
    }

    func fetchFiles() throws -> [FileItem] {
        guard let dbPool = dbPool else { return [] }
        return try dbPool.read { db in
            try FileItem.order(Column("createdAt").desc).fetchAll(db)
        }
    }

    func deleteFile(_ id: Int64) throws -> FileItem? {
        guard let dbPool = dbPool else { return nil }
        return try dbPool.write { db in
            let file = try FileItem.fetchOne(db, key: id)
            _ = try FileItem.deleteOne(db, key: id)
            return file
        }
    }

    func fileCount() throws -> Int {
        guard let dbPool = dbPool else { return 0 }
        return try dbPool.read { db in
            try FileItem.fetchCount(db)
        }
    }
}
