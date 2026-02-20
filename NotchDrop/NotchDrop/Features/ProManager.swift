//
//  ProManager.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import Foundation
import Combine

/// Manages Pro subscription state and enforces free tier limits.
///
/// Free tier quotas:
/// - 10 active (incomplete) todos
/// - 10 notes
/// - 15 files
///
/// Completed todos do NOT count toward the free limit.
/// Hitting a limit prevents adding new items but never deletes existing data.
class ProManager: ObservableObject {
    static let shared = ProManager()

    /// Whether the user has an active Pro subscription.
    /// StoreKit 2 integration will update this value.
    @Published var isPro: Bool = false

    // MARK: - Free Tier Limits

    let freeTodoLimit = 10
    let freeNoteLimit = 10
    let freeFileLimit = 15

    // MARK: - Quota Checks

    func canAddTodo() -> Bool {
        if isPro { return true }
        return (try? DatabaseManager.shared.activeTodoCount()) ?? 0 < freeTodoLimit
    }

    func canAddNote() -> Bool {
        if isPro { return true }
        return (try? DatabaseManager.shared.noteCount()) ?? 0 < freeNoteLimit
    }

    func canAddFile() -> Bool {
        if isPro { return true }
        return (try? DatabaseManager.shared.fileCount()) ?? 0 < freeFileLimit
    }
}
