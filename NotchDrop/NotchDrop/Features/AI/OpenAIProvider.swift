//
//  OpenAIProvider.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import Foundation

/// AI provider that uses OpenAI's Chat Completion API.
///
/// Model: `gpt-4o-mini` -- good balance of cost and quality for
/// note summarization and todo extraction tasks.
struct OpenAIProvider: AIProvider, Sendable {
    let name = "OpenAI"
    private let apiKey: String
    private let model = "gpt-4o-mini"
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // MARK: - AIProvider

    func summarizeNotes(_ notes: [String]) async throws -> String {
        let joined = notes.joined(separator: "\n---\n")
        let systemPrompt = "You are a helpful assistant that summarizes notes concisely."
        let userPrompt = "Summarize these notes into organized bullet points:\n\n\(joined)"
        return try await chatCompletion(system: systemPrompt, user: userPrompt)
    }

    func extractTodos(from notes: [String]) async throws -> [String] {
        let joined = notes.joined(separator: "\n---\n")
        let systemPrompt = "You are a helpful assistant that extracts actionable todo items."
        let userPrompt = "Extract actionable todo items from these notes. Return one todo per line, without numbering or bullet points:\n\n\(joined)"
        let response = try await chatCompletion(system: systemPrompt, user: userPrompt)
        return response
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    func quickSummary(_ text: String) async throws -> String {
        let systemPrompt = "You are a helpful assistant that provides brief summaries."
        let userPrompt = "Provide a brief summary of this text:\n\n\(text)"
        return try await chatCompletion(system: systemPrompt, user: userPrompt)
    }

    // MARK: - Private

    private func chatCompletion(system: String, user: String) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user],
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
        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            throw AIProviderError.apiError(message)
        }

        guard let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIProviderError.invalidResponse
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
