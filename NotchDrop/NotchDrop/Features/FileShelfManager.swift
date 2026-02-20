//
//  FileShelfManager.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import Foundation
import AppKit
import Combine

/// Manages file shelf items, wrapping DatabaseManager with business logic
/// including free tier quota enforcement and file system operations.
///
/// Files are copied from their source location into a managed storage
/// directory under Application Support. The storage path can be
/// customized via the `fileStoragePath` UserDefaults key.
class FileShelfManager: ObservableObject {
    static let shared = FileShelfManager()

    @Published var files: [FileItem] = []

    /// The directory where managed file copies are stored.
    private var storageURL: URL {
        if let custom = UserDefaults.standard.string(forKey: "fileStoragePath") {
            return URL(fileURLWithPath: custom)
        }
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return appSupport.appendingPathComponent("NotchDrop/files", isDirectory: true)
    }

    /// Reloads all files from the database.
    func refresh() {
        files = (try? DatabaseManager.shared.fetchFiles()) ?? []
    }

    /// Copies a file into managed storage and records it in the database.
    /// - Parameter sourceURL: The original file location.
    /// - Returns: `true` if the file was added successfully, `false` if
    ///   the free tier limit is reached or a file system error occurred.
    func addFile(from sourceURL: URL) -> Bool {
        guard ProManager.shared.canAddFile() else { return false }

        do {
            try FileManager.default.createDirectory(
                at: storageURL,
                withIntermediateDirectories: true
            )

            let fileName = sourceURL.lastPathComponent
            let uniqueName = "\(UUID().uuidString)_\(fileName)"
            let destURL = storageURL.appendingPathComponent(uniqueName)

            try FileManager.default.copyItem(at: sourceURL, to: destURL)

            let attrs = try FileManager.default.attributesOfItem(atPath: destURL.path)
            let fileSize = (attrs[.size] as? Int64) ?? 0

            _ = try DatabaseManager.shared.addFile(
                originalName: fileName,
                storedPath: destURL.path,
                fileSize: fileSize,
                thumbnailPath: nil
            )

            refresh()
            return true
        } catch {
            NSLog("File add error: \(error)")
            return false
        }
    }

    /// Deletes a file from both the database and the file system.
    /// - Parameter id: The file's database ID.
    func deleteFile(_ id: Int64) {
        if let file = try? DatabaseManager.shared.deleteFile(id) {
            try? FileManager.default.removeItem(atPath: file.storedPath)
        }
        refresh()
    }

    /// Opens a file using the system's default application.
    /// - Parameter file: The file item to open.
    func openFile(_ file: FileItem) {
        NSWorkspace.shared.open(URL(fileURLWithPath: file.storedPath))
    }
}
