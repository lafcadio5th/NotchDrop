//
//  AnthropicProvider.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import Foundation

/// AI provider that uses Anthropic's Messages API.
///
/// Model: `claude-3-5-haiku-latest` -- fast and affordable,
/// ideal for summarization and extraction tasks.
struct AnthropicProvider: AIProvider, Sendable {
    let name = "Anthropic"
    private let apiKey: String
    private let model = "claude-3-5-haiku-latest"
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // MARK: - AIProvider

    func summarizeNotes(_ notes: [String]) async throws -> String {
        let joined = notes.joined(separator: "\n---\n")
        let prompt = "Summarize these notes into organized bullet points:\n\n\(joined)"
        return try await sendMessage(prompt)
    }

    func extractTodos(from notes: [String]) async throws -> [String] {
        let joined = notes.joined(separator: "\n---\n")
        let prompt = "Extract actionable todo items from these notes. Return one todo per line, without numbering or bullet points:\n\n\(joined)"
        let response = try await sendMessage(prompt)
        return response
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    func quickSummary(_ text: String) async throws -> String {
        let prompt = "Provide a brief summary of this text:\n\n\(text)"
        return try await sendMessage(prompt)
    }

    // MARK: - Private

    private func sendMessage(_ userMessage: String) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "messages": [
                ["role": "user", "content": userMessage],
            ],
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AIProviderError.networkError(error)
        }

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
            throw AIProviderError.invalidAPIKey
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIProviderError.invalidResponse
        }

        // Check for API-level errors
        if let errorInfo = json["error"] as? [String: Any],
           let message = errorInfo["message"] as? String {
            throw AIProviderError.apiError(message)
        }

        guard let content = json["content"] as? [[String: Any]],
              let first = content.first,
              let text = first["text"] as? String else {
            throw AIProviderError.invalidResponse
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
