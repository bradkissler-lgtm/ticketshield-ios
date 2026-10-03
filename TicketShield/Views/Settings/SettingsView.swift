import SwiftUI
import SwiftData
import UserNotifications
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(AppPreferences.self) private var preferences
    @Query private var spots: [ParkingSpot]

    @State private var showPaywall = false
    @State private var authStatus: UNAuthorizationStatus = .notDetermined
    @State private var showPrivacy = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminders") {
                    Picker("Default lead time", selection: Binding(
                        get: { preferences.defaultLeadTimeMinutes },
                        set: { preferences.defaultLeadTimeMinutes = $0 }
                    )) {
                        ForEach(LeadTimeOptions.available(isPro: entitlements.isPro), id: \.self) { minutes in
                            Text("\(minutes) minutes").tag(minutes)
                        }
                    }
                    .onChange(of: preferences.defaultLeadTimeMinutes) { _, _ in
                        Task { await replenish() }
                    }

                    if entitlements.isPro {
                        Toggle("Weekly digest", isOn: Binding(
                            get: { preferences.weeklyDigestEnabled },
                            set: { preferences.weeklyDigestEnabled = $0 }
                        ))
                        .onChange(of: preferences.weeklyDigestEnabled) { _, enabled in
                            if enabled {
                                Task { _ = await NotificationScheduler.requestAuthorization() }
                            }
                            Task { await replenish() }
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Text("Weekly digest")
                                Spacer()
                                Text("Pro")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(TSTheme.teal)
                            }
                        }
                    }
                }

                Section("Notifications") {
                    LabeledContent("Status", value: authLabel)
                    if authStatus == .denied {
                        Button("Open iOS Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    } else if authStatus == .notDetermined {
                        Button("Allow notifications") {
                            Task {
                                _ = await NotificationScheduler.requestAuthorization()
                                authStatus = await NotificationScheduler.authorizationStatus()
                            }
                        }
                    }
                }

                Section("ParkShield Pro") {
                    LabeledContent("Status", value: entitlements.isPro ? "Pro" : "Free · 1 saved spot")
                    if !entitlements.isPro {
                        Button("See Pro options") { showPaywall = true }
                    }
                    Button("Restore purchases") {
                        Task { await entitlements.restore() }
                    }
                    if let message = entitlements.lastErrorMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Privacy") {
                    Button("Privacy on this iPhone") { showPrivacy = true }
                    Link("Email privacy questions", destination: privacyMailURL)
                }

                Section {
                    LabeledContent("Version", value: versionString)
                    Text("No accounts. No city databases. No maps. Sign photos are read on device and are not uploaded.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showPrivacy) {
                PrivacyOnDeviceView()
            }
            .task {
                authStatus = await NotificationScheduler.authorizationStatus()
            }
        }
    }

    private var authLabel: String {
        switch authStatus {
        case .authorized, .provisional, .ephemeral: return "Allowed"
        case .denied: return "Off"
        case .notDetermined: return "Not asked yet"
        @unknown default: return "Unknown"
        }
    }

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var privacyMailURL: URL {
        URL(string: "mailto:bkissler@vancap.com?subject=ParkShield%20privacy")!
    }

    private func replenish() async {
        await NotificationScheduler.replenish(
            spots: spots,
            digestEnabled: entitlements.isPro && preferences.weeklyDigestEnabled,
            isPro: entitlements.isPro
        )
    }
}

struct PrivacyOnDeviceView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("ParkShield is built to keep parking-sign photos and reminder times on your iPhone.")
                    Text("The camera and photo library are used only to read a sign you choose. Optical character recognition runs on device with Apple’s Vision framework. Photos are not uploaded, and there is no ParkShield account.")
                    Text("Reminders use local notifications. In-app purchases are handled by Apple. Questions: bkissler@vancap.com.")
                }
                .padding(24)
            }
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
