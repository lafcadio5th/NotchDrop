//
//  StoreManager.swift
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

import StoreKit
import Combine

/// Manages StoreKit 2 in-app purchase for the Pro upgrade.
///
/// Provides a singleton that:
/// - Loads the Pro product from the App Store
/// - Handles purchase flow
/// - Monitors transaction updates (renewals, refunds, family sharing)
/// - Syncs purchase state with `ProManager`
class StoreManager: ObservableObject {
    static let shared = StoreManager()

    static let proProductID = "com.kelvintan.NotchDrop.pro"

    @Published var proProduct: Product?
    @Published var isPurchased = false
    @Published var isLoading = false

    private var updateListenerTask: Task<Void, Error>?

    init() {
        updateListenerTask = listenForTransactions()
        Task { await loadProducts() }
        Task { await checkPurchaseStatus() }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Product Loading

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [StoreManager.proProductID])
            await MainActor.run {
                proProduct = products.first
            }
        } catch {
            NSLog("StoreKit product load error: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase() async throws -> Bool {
        guard let product = proProduct else { return false }

        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await MainActor.run {
                isPurchased = true
                ProManager.shared.isPro = true
            }
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Entitlement Check

    func checkPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == StoreManager.proProductID {
                await MainActor.run {
                    isPurchased = true
                    ProManager.shared.isPro = true
                }
                return
            }
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        try? await AppStore.sync()
        await checkPurchaseStatus()
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    if transaction.productID == StoreManager.proProductID {
                        await MainActor.run {
                            self.isPurchased = true
                            ProManager.shared.isPro = true
                        }
                    }
                }
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    enum StoreError: Error {
        case failedVerification
    }
}
