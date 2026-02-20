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
struct NoteListView: View {
    @ObservedObject var noteManager = NoteManager.shared

    var body: some View {
        if noteManager.notes.isEmpty {
            emptyState
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 4) {
                    ForEach(noteManager.notes) { note in
                        noteRow(note)
                    }
                }
            }
        }
    }

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
