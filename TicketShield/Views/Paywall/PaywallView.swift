import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(EntitlementStore.self) private var entitlements

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    comparison
                    products
                    if let message = entitlements.lastErrorMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    restore
                    finePrint
                }
                .padding(24)
            }
            .background(TSTheme.groupedBackground)
            .navigationTitle("ParkShield Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                guard !ScreenshotMode.isActive else { return }
                if entitlements.products.isEmpty {
                    await entitlements.loadProducts()
                }
            }
            .onChange(of: entitlements.isPro) { _, isPro in
                if isPro { dismiss() }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("One avoided ticket often covers Pro.")
                .font(.title2.weight(.semibold))
            Text("Free includes one saved spot and 15, 30, or 60 minute reminders. Pro unlocks unlimited spots, more lead times, and an optional weekly digest. Everything still stays on this iPhone.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var comparison: some View {
        VStack(alignment: .leading, spacing: 10) {
            row("Saved spots", free: "1", pro: "Unlimited")
            row("Lead time", free: "15 / 30 / 60 min", pro: "5–120 min")
            row("Weekly digest", free: "—", pro: "Optional")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func row(_ title: String, free: String, pro: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(free)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(pro)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TSTheme.teal)
                .frame(minWidth: 88, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
    }

    private var products: some View {
        VStack(spacing: 12) {
            productCard(
                title: "Lifetime",
                subtitle: "Pay once",
                price: entitlements.lifetimeProduct?.displayPrice ?? "$4.99",
                detail: "Keep Pro on this Apple ID. Highlighted because it’s the simple option.",
                highlighted: true,
                product: entitlements.lifetimeProduct
            )
            productCard(
                title: "Annual",
                subtitle: "Billed once a year",
                price: entitlements.annualProduct?.displayPrice ?? "$19.99",
                detail: "Same Pro features, billed yearly. Cancel anytime in Settings › Apple ID › Subscriptions.",
                highlighted: false,
                product: entitlements.annualProduct
            )
        }
    }

    private func productCard(
        title: String,
        subtitle: String,
        price: String,
        detail: String,
        highlighted: Bool,
        product: Product?
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(price)
                    .font(.title3.weight(.semibold))
            }
            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button {
                if let product {
                    Task { await entitlements.purchase(product) }
                }
            } label: {
                if entitlements.purchaseInProgress {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                } else {
                    Text(highlighted ? "Continue with Lifetime" : "Continue with Annual")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(highlighted ? TSTheme.teal : Color.secondary)
            .disabled((product == nil && !ScreenshotMode.isActive) || entitlements.purchaseInProgress)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(highlighted ? TSTheme.teal : Color.clear, lineWidth: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var restore: some View {
        Button("Restore purchases") {
            Task { await entitlements.restore() }
        }
        .frame(maxWidth: .infinity)
        .disabled(entitlements.purchaseInProgress)
    }

    private var finePrint: some View {
        Text("Purchases are billed by Apple. Lifetime is a one-time In-App Purchase. Annual renews until you cancel. Photos and sign text are not uploaded. No account is created.")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

#Preview {
    PaywallView()
        .environment(EntitlementStore())
}
