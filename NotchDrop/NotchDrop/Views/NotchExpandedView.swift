//
//  NotchExpandedView.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import SwiftUI

/// The three tabs available in the expanded notch UI.
enum NotchTab: String, CaseIterable {
    case todos = "Todos"
    case notes = "Notes"
    case files = "Files"
}

/// The main UI that appears when the notch expands.
///
/// Layout (top to bottom):
/// 1. Quick input field (`QuickInputView`)
/// 2. Tab bar (Todos / Notes / Files)
/// 3. Content area displaying the selected tab's list
///
/// The background is a dark glassmorphic panel with square top
/// corners (connecting seamlessly to the notch) and rounded bottom
/// corners (20px radius).
struct NotchExpandedView: View {
    @State private var selectedTab: NotchTab = .todos

    @ObservedObject private var todoManager = TodoManager.shared
    @ObservedObject private var noteManager = NoteManager.shared
    @ObservedObject private var fileShelfManager = FileShelfManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Camera notch spacer — leave room for the physical camera area
            Spacer()
                .frame(height: 32)

            VStack(spacing: 10) {
                // Quick input field
                QuickInputView(selectedTab: $selectedTab)

                // Tab bar
                tabBar

                // Content area
                contentArea
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            NotchBackground()
        )
        .onAppear {
            todoManager.refresh()
            noteManager.refresh()
            fileShelfManager.refresh()
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 2) {
            ForEach(NotchTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(2)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func tabButton(_ tab: NotchTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 3) {
                Text(tab.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(
                        selectedTab == tab
                            ? .white
                            : .white.opacity(0.4)
                    )

                Text("\(countForTab(tab))")
                    .font(.system(size: 9))
                    .foregroundStyle(
                        selectedTab == tab
                            ? .white.opacity(0.5)
                            : .white.opacity(0.25)
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(
                selectedTab == tab
                    ? Color.white.opacity(0.1)
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    private func countForTab(_ tab: NotchTab) -> Int {
        switch tab {
        case .todos: return todoManager.todos.count
        case .notes: return noteManager.notes.count
        case .files: return fileShelfManager.files.count
        }
    }

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        switch selectedTab {
        case .todos:
            TodoListView(todoManager: todoManager)
        case .notes:
            NoteListView(noteManager: noteManager)
        case .files:
            FileShelfView(fileShelfManager: fileShelfManager)
        }
    }
}

// MARK: - Notch Background Shape

/// A custom background for the expanded notch panel:
/// - Top corners: square (0 radius), connecting to the notch
/// - Bottom corners: rounded (20px radius)
private struct NotchBackground: View {
    var body: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 20,
            bottomTrailingRadius: 20,
            topTrailingRadius: 0
        )
        .fill(Color(red: 0.04, green: 0.04, blue: 0.047).opacity(0.97))
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 20,
                bottomTrailingRadius: 20,
                topTrailingRadius: 0
            )
            .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 20, y: 6)
        .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
    }
}
