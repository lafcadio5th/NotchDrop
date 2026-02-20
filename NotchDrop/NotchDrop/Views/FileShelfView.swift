//
//  FileShelfView.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import SwiftUI

/// Displays a grid of shelved files.
///
/// Each cell shows a file type icon, the filename (truncated), and a
/// delete button on hover. Clicking a cell opens the file in its
/// default application.
struct FileShelfView: View {
    @ObservedObject var fileShelfManager = FileShelfManager.shared

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 4)

    var body: some View {
        if fileShelfManager.files.isEmpty {
            emptyState
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(fileShelfManager.files) { file in
                        fileCell(file)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("Drop files to the notch")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.3))
            Text("Drag any file onto the notch area")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.2))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func fileCell(_ file: FileItem) -> some View {
        ZStack(alignment: .topTrailing) {
            Button {
                fileShelfManager.openFile(file)
            } label: {
                VStack(spacing: 4) {
                    Text(iconForFile(file.originalName))
                        .font(.system(size: 20))

                    Text(file.originalName)
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .padding(6)
                .background(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            // Delete button
            Button {
                guard let id = file.id else { return }
                fileShelfManager.deleteFile(id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .buttonStyle(.plain)
            .offset(x: 4, y: -4)
        }
    }

    /// Returns an emoji icon based on the file extension.
    private func iconForFile(_ name: String) -> String {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "\u{1F4C4}"         // page facing up
        case "png", "jpg", "jpeg", "gif", "webp", "heic", "svg":
            return "\u{1F3A8}"                  // artist palette
        case "xlsx", "xls", "csv":
            return "\u{1F4CA}"                  // bar chart
        case "doc", "docx", "txt", "rtf", "md":
            return "\u{1F4C3}"                  // page with curl
        case "ppt", "pptx", "key":
            return "\u{1F4CA}"                  // bar chart (presentation)
        case "zip", "rar", "7z", "tar", "gz":
            return "\u{1F4E6}"                  // package
        case "mp3", "wav", "aac", "flac", "m4a":
            return "\u{1F3B5}"                  // musical note
        case "mp4", "mov", "avi", "mkv", "m4v":
            return "\u{1F3AC}"                  // clapper board
        case "swift", "py", "js", "ts", "html", "css", "json":
            return "\u{1F4BB}"                  // laptop
        default:
            return "\u{1F4C1}"                  // file folder
        }
    }
}
