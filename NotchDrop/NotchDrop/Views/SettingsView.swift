//
//  SettingsView.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import SwiftUI
import StoreKit

/// The Settings window content, displayed inside the macOS Settings scene.
///
/// Sections:
/// 1. General  -- Launch at login toggle (placeholder)
/// 2. Storage  -- File storage path, usage stats
/// 3. AI       -- Provider selection, API key management
/// 4. Account  -- Pro status, upgrade button, usage quotas
/// 5. About    -- App version, credits
struct SettingsView: View {
    @ObservedObject private var proManager = ProManager.shared
    @ObservedObject private var storeManager = StoreManager.shared
    @ObservedObject private var aiService = AIService.shared

    @State private var storagePath: String = UserDefaults.standard.string(forKey: "fileStoragePath") ?? defaultStoragePath()
    @State private var launchAtLogin: Bool = false

    @State private var todoCount: Int = 0
    @State private var noteCount: Int = 0
    @State private var fileCount: Int = 0
    @State private var fileStorageSize: String = "0 MB"
    @State private var fileItemCount: Int = 0

    // AI settings state
    @State private var apiKeyInput: String = ""
    @State private var keyStatus: String = ""
    @State private var testResult: String = ""
    @State private var isTesting: Bool = false

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            storageTab
                .tabItem {
                    Label("Storage", systemImage: "externaldrive")
                }

            aiTab
                .tabItem {
                    Label("AI", systemImage: "sparkles")
                }

            accountTab
                .tabItem {
                    Label("Account", systemImage: "person.crop.circle")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 320)
        .onAppear {
            loadUsageStats()
            updateKeyStatus()
        }
    }

    // MARK: - General

    private var generalTab: some View {
        Form {
            Toggle("Launch at login", isOn: $launchAtLogin)
                .disabled(true)
            Text("Launch at login will be available in a future update.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    // MARK: - Storage

    private var storageTab: some View {
        Form {
            LabeledContent("Storage path") {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(storagePath)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Button("Change...") {
                        chooseStoragePath()
                    }
                }
            }

            LabeledContent("Usage") {
                Text("\(fileItemCount) files, \(fileStorageSize)")
            }
        }
        .padding()
    }

    // MARK: - AI

    private var aiTab: some View {
        Form {
            if !proManager.isPro {
                VStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("AI features require a Pro subscription.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Button("Upgrade to Pro") {
                        Task { try? await storeManager.purchase() }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Provider selection
                Picker("Provider", selection: $aiService.selectedProvider) {
                    Text("OpenAI").tag("openai")
                    Text("Anthropic").tag("anthropic")
                }
                .pickerStyle(.segmented)
                .onChange(of: aiService.selectedProvider) {
                    updateKeyStatus()
                    apiKeyInput = ""
                    testResult = ""
                }

                // API key input
                LabeledContent("API Key") {
                    VStack(alignment: .trailing, spacing: 4) {
                        SecureField("Enter API key...", text: $apiKeyInput)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 250)

                        HStack(spacing: 8) {
                            Text(keyStatus)
                                .font(.caption)
                                .foregroundStyle(
                                    AIKeyManager.shared.hasKey(for: aiService.selectedProvider) ? .green : .secondary
                                )

                            if !apiKeyInput.isEmpty {
                                Button("Save Key") {
                                    saveApiKey()
                                }
                                .controlSize(.small)
                            }

                            if AIKeyManager.shared.hasKey(for: aiService.selectedProvider) {
                                Button("Remove") {
                                    removeApiKey()
                                }
                                .controlSize(.small)
                                .foregroundStyle(.red)
                            }
                        }
                    }
                }

                // Test connection
                LabeledContent("Connection") {
                    HStack(spacing: 8) {
                        Button {
                            Task { await testConnection() }
                        } label: {
                            HStack(spacing: 4) {
                                if isTesting {
                                    ProgressView()
                                        .controlSize(.mini)
                                        .scaleEffect(0.8)
                                }
                                Text("Test Connection")
                            }
                        }
                        .controlSize(.small)
                        .disabled(
                            !AIKeyManager.shared.hasKey(for: aiService.selectedProvider)
                                || isTesting
                        )

                        if !testResult.isEmpty {
                            Text(testResult)
                                .font(.caption)
                                .foregroundStyle(testResult.contains("Success") ? .green : .red)
                        }
                    }
                }

                // Provider info
                Section {
                    providerInfoView
                }
            }
        }
        .padding()
    }

    private var providerInfoView: some View {
        Group {
            switch aiService.selectedProvider {
            case "openai":
                VStack(alignment: .leading, spacing: 2) {
                    Text("Model: gpt-4o-mini")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Get your API key at platform.openai.com")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case "anthropic":
                VStack(alignment: .leading, spacing: 2) {
                    Text("Model: claude-3-5-haiku-latest")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Get your API key at console.anthropic.com")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            default:
                EmptyView()
            }
        }
    }

    // MARK: - AI Helpers

    private func saveApiKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        AIKeyManager.shared.saveKey(trimmed, for: aiService.selectedProvider)
        apiKeyInput = ""
        updateKeyStatus()
        testResult = ""
    }

    private func removeApiKey() {
        AIKeyManager.shared.deleteKey(for: aiService.selectedProvider)
        updateKeyStatus()
        testResult = ""
    }

    private func updateKeyStatus() {
        if AIKeyManager.shared.hasKey(for: aiService.selectedProvider) {
            keyStatus = "Key saved"
        } else {
            keyStatus = "No key configured"
        }
    }

    private func testConnection() async {
        isTesting = true
        testResult = ""

        let success = await aiService.testConnection()
        isTesting = false

        if success {
            testResult = "Success"
        } else {
            testResult = aiService.lastError ?? "Failed"
        }
    }

    // MARK: - Account

    private var accountTab: some View {
        Form {
            LabeledContent("Current plan") {
                if proManager.isPro {
                    Label("Pro", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .font(.headline)
                } else {
                    Text("Free")
                        .font(.headline)
                }
            }

            if !proManager.isPro {
                Section("Usage") {
                    HStack {
                        usagePill(
                            label: "Todos",
                            current: todoCount,
                            limit: proManager.freeTodoLimit
                        )
                        usagePill(
                            label: "Notes",
                            current: noteCount,
                            limit: proManager.freeNoteLimit
                        )
                        usagePill(
                            label: "Files",
                            current: fileCount,
                            limit: proManager.freeFileLimit
                        )
                    }
                }

                Section {
                    Button {
                        Task { try? await storeManager.purchase() }
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                            if let product = storeManager.proProduct {
                                Text("Upgrade to Pro -- \(product.displayPrice)")
                            } else {
                                Text("Upgrade to Pro -- $4.99")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(storeManager.isLoading)

                    Button("Restore Purchases") {
                        Task { await storeManager.restorePurchases() }
                    }
                    .buttonStyle(.link)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .onAppear { loadUsageStats() }
    }

    // MARK: - About

    private var aboutTab: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "tray.and.arrow.down.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("NotchDrop")
                .font(.title.bold())

            Text("Version \(appVersion)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text("Made with \u{2764}\u{FE0F} by Kelvin Tan")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - Helpers

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func usagePill(label: String, current: Int, limit: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(current)/\(limit)")
                .font(.headline)
                .foregroundStyle(current >= limit ? .red : .primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func loadUsageStats() {
        todoCount = (try? DatabaseManager.shared.activeTodoCount()) ?? 0
        noteCount = (try? DatabaseManager.shared.noteCount()) ?? 0
        fileCount = (try? DatabaseManager.shared.fileCount()) ?? 0

        // Calculate storage size
        let storageURL: URL
        if let custom = UserDefaults.standard.string(forKey: "fileStoragePath") {
            storageURL = URL(fileURLWithPath: custom)
        } else {
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!
            storageURL = appSupport.appendingPathComponent("NotchDrop/files", isDirectory: true)
        }

        var totalSize: Int64 = 0
        var count = 0
        if let enumerator = FileManager.default.enumerator(at: storageURL, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let attrs = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                   let size = attrs.fileSize {
                    totalSize += Int64(size)
                    count += 1
                }
            }
        }

        fileItemCount = count
        fileStorageSize = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    private func chooseStoragePath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.message = "Select a folder for NotchDrop file storage"

        if panel.runModal() == .OK, let url = panel.url {
            storagePath = url.path
            UserDefaults.standard.set(url.path, forKey: "fileStoragePath")
        }
    }

    private static func defaultStoragePath() -> String {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return appSupport
            .appendingPathComponent("NotchDrop/files", isDirectory: true)
            .path
    }
}
