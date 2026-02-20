//
//  AIProviderProtocol.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import Foundation

/// Common interface for AI providers (OpenAI, Anthropic, etc.).
///
/// Each provider is responsible for making network calls to its own
/// API and parsing the response.  All methods are async/throwing so
/// callers can await the result and handle network or parsing errors.
protocol AIProvider: Sendable {
    var name: String { get }

    /// Summarize an array of note strings into organized bullet points.
    func summarizeNotes(_ notes: [String]) async throws -> String

    /// Extract actionable todo items from an array of note strings.
    func extractTodos(from notes: [String]) async throws -> [String]

    /// Return a brief summary of the given text.
    func quickSummary(_ text: String) async throws -> String
}

/// Errors that any AI provider can throw.
enum AIProviderError: LocalizedError {
    case invalidAPIKey
    case networkError(Error)
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from AI provider."
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}
