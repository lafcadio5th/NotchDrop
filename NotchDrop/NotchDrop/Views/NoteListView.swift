//
//  NoteListView.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import SwiftUI

/// Displays the list of note items, newest first.
///
/// Each row shows the note text (truncated to one line), a relative
/// timestamp, and a delete button.
///
/// When the user is a Pro subscriber with an API key configured,
/// AI action buttons (Summarize, Extract Todos) appear at the top.
struct NoteListView: View {
    @ObservedObject var noteManager = NoteManager.shared
    @ObservedObject private var aiService = AIService.shared
    @ObservedObject private var proManager = ProManager.shared

    @State private var showSummary = false
    @State private var summaryText = ""
    @State private var extractedTodoCount = 0
    @State private var showTodoResult = false

    var body: some View {
        if noteManager.notes.isEmpty {
            emptyState
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 4) {
                    // AI action bar (Pro users with API key only)
                    if proManager.isPro && AIKeyManager.shared.hasKey(for: aiService.selectedProvider) {
                        aiActionBar
                    }

                    ForEach(noteManager.notes) { note in
                        noteRow(note)
                    }
                }
            }
            .popover(isPresented: $showSummary) {
                summaryPopover
            }
            .popover(isPresented: $showTodoResult) {
                todoResultPopover
            }
        }
    }

    // MARK: - AI Action Bar

    private var aiActionBar: some View {
        HStack(spacing: 6) {
            Button {
                Task { await performSummarize() }
            } label: {
                HStack(spacing: 4) {
                    if aiService.isProcessing {
                        ProgressView()
                            .controlSize(.mini)
                            .scaleEffect(0.7)
                    }
                    Text("\u{2726} Summarize")
                        .font(.system(size: 10, weight: .medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.purple.opacity(0.15))
                .foregroundStyle(.purple)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(aiService.isProcessing)

            Button {
                Task { await performExtractTodos() }
            } label: {
                HStack(spacing: 4) {
                    if aiService.isProcessing {
                        ProgressView()
                            .controlSize(.mini)
                            .scaleEffect(0.7)
                    }
                    Text("\u{2726} Extract Todos")
                        .font(.system(size: 10, weight: .medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.15))
                .foregroundStyle(.blue)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(aiService.isProcessing)

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
    }

    // MARK: - Summary Popover

    private var summaryPopover: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI Summary")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))

            ScrollView {
                Text(summaryText)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .frame(width: 300, height: 250)
    }

    // MARK: - Todo Result Popover

    private var todoResultPopover: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(.green)

            Text("\(extractedTodoCount) todos added")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))

            Text("Check your Todo list")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(16)
        .frame(width: 200)
    }

    // MARK: - AI Actions

    private func performSummarize() async {
        guard let result = await aiService.summarizeNotes(noteManager.notes) else { return }
        summaryText = result
        showSummary = true
    }

    private func performExtractTodos() async {
        guard let todos = await aiService.extractTodos(from: noteManager.notes) else { return }
        var added = 0
        for todo in todos {
            if TodoManager.shared.addTodo(todo) {
                added += 1
            }
        }
        extractedTodoCount = added
        showTodoResult = true
    }

    // MARK: - Existing Views

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("No notes yet")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.3))
            Text("Press \u{2318}Enter after typing to add one")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.2))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func noteRow(_ note: NoteItem) -> some View {
        HStack(spacing: 8) {
            // Note icon
            Text("\u{1F4DD}")
                .font(.system(size: 11))
                .opacity(0.4)

            // Content text
            Text(note.content)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            // Relative timestamp
            Text(relativeTime(from: note.createdAt))
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.2))

            // Delete button
            Button {
                guard let id = note.id else { return }
                noteManager.deleteNote(id)
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

    /// Returns a short relative time string (e.g. "2m", "1h", "3d").
    private func relativeTime(from date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 { return "now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h" }
        let days = hours / 24
        return "\(days)d"
    }
}
