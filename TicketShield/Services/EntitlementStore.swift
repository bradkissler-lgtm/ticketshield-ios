import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class EntitlementStore {
    var isPro = false
    var products: [Product] = []
    var purchaseInProgress = false
    var lastErrorMessage: String?
    var isLoadingProducts = false

    var lifetimeProduct: Product? {
        products.first { $0.id == ProductIDs.lifetime }
    }

    var annualProduct: Product? {
        products.first { $0.id == ProductIDs.annual }
    }

    @ObservationIgnored
    private var updatesTask: Task<Void, Never>?

    func start() async {
        listenForUpdates()
        await loadProducts()
        await refreshEntitlements()
    }

    func loadProducts() async {
        isLoadingProducts = true
        lastErrorMessage = nil
        defer { isLoadingProducts = false }
        do {
            let loaded = try await Product.products(for: ProductIDs.all)
            products = loaded.sorted { lhs, rhs in
                if lhs.id == ProductIDs.lifetime { return true }
                if rhs.id == ProductIDs.lifetime { return false }
                return lhs.id < rhs.id
            }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func purchase(_ product: Product) async {
        purchaseInProgress = true
        lastErrorMessage = nil
        defer { purchaseInProgress = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .userCancelled:
                break
            case .pending:
                lastErrorMessage = "Purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func restore() async {
        purchaseInProgress = true
        lastErrorMessage = nil
        defer { purchaseInProgress = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !isPro {
                lastErrorMessage = "No Pro purchase was found for this Apple ID."
            }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               ProductIDs.unlocksPro(transaction.productID),
               transaction.revocationDate == nil {
                unlocked = true
            }
        }
        isPro = unlocked
    }

    private func listenForUpdates() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(update: result)
            }
        }
    }

    private func handle(update result: VerificationResult<Transaction>) async {
        if let transaction = try? checkVerified(result) {
            await transaction.finish()
        }
        await refreshEntitlements()
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
