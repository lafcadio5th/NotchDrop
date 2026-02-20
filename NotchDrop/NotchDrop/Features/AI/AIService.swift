//
//  AIService.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import Combine
import Foundation

/// Central service that manages AI provider selection and orchestrates
/// AI-powered operations on notes and todos.
///
/// Usage is gated behind Pro: free-tier users cannot access AI features.
/// Users must also configure a valid API key for their chosen provider
/// via the Settings panel.
class AIService: ObservableObject {
    static let shared = AIService()

    @Published var isProcessing = false
    @Published var selectedProvider: String {
        didSet {
            UserDefaults.standard.set(selectedProvider, forKey: "ai_provider")
        }
    }
    @Published var lastError: String?

    init() {
        selectedProvider = UserDefaults.standard.string(forKey: "ai_provider") ?? "openai"
    }

    /// Returns the configured AI provider, or nil if Pro is not active
    /// or no API key is set.
    func getProvider() -> AIProvider? {
        guard ProManager.shared.isPro else { return nil }
        guard let key = AIKeyManager.shared.getKey(for: selectedProvider) else { return nil }

        switch selectedProvider {
        case "openai":
            return OpenAIProvider(apiKey: key)
        case "anthropic":
            return AnthropicProvider(apiKey: key)
        default:
            return nil
        }
    }

    /// Summarize an array of NoteItem objects using the active provider.
    func summarizeNotes(_ notes: [NoteItem]) async -> String? {
        guard let provider = getProvider() else { return nil }

        await MainActor.run { isProcessing = true }
        defer { Task { @MainActor in isProcessing = false } }

        do {
            let texts = notes.map { $0.content }
            let result = try await provider.summarizeNotes(texts)
            return result
        } catch {
            await MainActor.run { lastError = error.localizedDescription }
            return nil
        }
    }

    /// Extract todo items from an array of NoteItem objects.
    func extractTodos(from notes: [NoteItem]) async -> [String]? {
        guard let provider = getProvider() else { return nil }

        await MainActor.run { isProcessing = true }
        defer { Task { @MainActor in isProcessing = false } }

        do {
            let texts = notes.map { $0.content }
            let result = try await provider.extractTodos(from: texts)
            return result
        } catch {
            await MainActor.run { lastError = error.localizedDescription }
            return nil
        }
    }

    /// Test the connection to the currently selected provider.
    func testConnection() async -> Bool {
        guard let provider = getProvider() else { return false }

        await MainActor.run { isProcessing = true }
        defer { Task { @MainActor in isProcessing = false } }

        do {
            _ = try await provider.quickSummary("Hello, this is a test message.")
            return true
        } catch {
            await MainActor.run { lastError = error.localizedDescription }
            return false
        }
    }
}
