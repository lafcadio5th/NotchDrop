//
//  TodoManager.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import Foundation
import Combine

/// Manages todo items, wrapping DatabaseManager with business logic
/// including free tier quota enforcement and content validation.
class TodoManager: ObservableObject {
    static let shared = TodoManager()

    @Published var todos: [TodoItem] = []

    /// Reloads all todos from the database (active and completed).
    func refresh() {
        todos = (try? DatabaseManager.shared.fetchAllTodos()) ?? []
    }

    /// Adds a new todo item.
    /// - Parameter content: The todo text content.
    /// - Returns: `true` if the todo was added successfully, `false` if
    ///   the free tier limit is reached or the content is empty.
    func addTodo(_ content: String) -> Bool {
        guard ProManager.shared.canAddTodo() else { return false }
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        _ = try? DatabaseManager.shared.addTodo(content)
        refresh()
        return true
    }

    /// Toggles the completion state of a todo.
    /// - Parameter id: The todo's database ID.
    func toggleTodo(_ id: Int64) {
        try? DatabaseManager.shared.toggleTodo(id)
        refresh()
    }

    /// Permanently deletes a todo.
    /// - Parameter id: The todo's database ID.
    func deleteTodo(_ id: Int64) {
        try? DatabaseManager.shared.deleteTodo(id)
        refresh()
    }
}
