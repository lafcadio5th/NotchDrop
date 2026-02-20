//
//  TodoListView.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import SwiftUI

/// Displays the list of todo items.
///
/// Active (incomplete) todos appear first, followed by completed todos
/// which are visually dimmed. Each row has a checkbox toggle and a
/// delete button.
struct TodoListView: View {
    @ObservedObject var todoManager = TodoManager.shared

    var body: some View {
        let activeTodos = todoManager.todos.filter { !$0.isDone }
        let completedTodos = todoManager.todos.filter { $0.isDone }

        if todoManager.todos.isEmpty {
            emptyState
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 4) {
                    ForEach(activeTodos) { todo in
                        todoRow(todo, isDone: false)
                    }
                    ForEach(completedTodos) { todo in
                        todoRow(todo, isDone: true)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("No todos yet")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.3))
            Text("Press Enter after typing to add one")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.2))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func todoRow(_ todo: TodoItem, isDone: Bool) -> some View {
        HStack(spacing: 8) {
            // Checkbox
            Button {
                guard let id = todo.id else { return }
                todoManager.toggleTodo(id)
            } label: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(isDone ? Color(red: 0.23, green: 0.51, blue: 0.96) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(
                                isDone
                                    ? Color(red: 0.23, green: 0.51, blue: 0.96)
                                    : Color.white.opacity(0.2),
                                lineWidth: 1.5
                            )
                    )
                    .overlay {
                        if isDone {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 14, height: 14)
            }
            .buttonStyle(.plain)

            // Content text
            Text(todo.content)
                .font(.system(size: 12))
                .foregroundStyle(isDone ? .white.opacity(0.3) : .white.opacity(0.8))
                .strikethrough(isDone, color: .white.opacity(0.3))
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            // Delete button
            Button {
                guard let id = todo.id else { return }
                todoManager.deleteTodo(id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.2))
            }
            .buttonStyle(.plain)
            .opacity(0.6)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
