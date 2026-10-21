import SwiftUI
import SwiftData
import UserNotifications

@main
struct TicketShieldApp: App {
    @State private var entitlements = EntitlementStore()
    @State private var preferences = AppPreferences()

    private let modelContainer: ModelContainer

    init() {
        if !ScreenshotMode.isActive {
            NotificationBootstrap.install()
        }
        modelContainer = ScreenshotMode.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let screen = ScreenshotMode.screen {
                    ScreenshotHost(screen: screen)
                } else {
                    AppRootView()
                        .task {
                            await entitlements.start()
                        }
                }
            }
            .environment(entitlements)
            .environment(preferences)
            .tint(TSTheme.teal)
        }
        .modelContainer(modelContainer)
    }
}

enum NotificationBootstrap {
    static let delegate = NotificationDelegate()

    static func install() {
        UNUserNotificationCenter.current().delegate = delegate
        Task {
            try? await UNUserNotificationCenter.current().setBadgeCount(0)
        }
    }
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(AppPreferences.self) private var preferences
    @Query(sort: \ParkingSpot.createdAt) private var spots: [ParkingSpot]

    var body: some View {
        SpotListView()
            .task { await refreshNotifications() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task {
                        try? await UNUserNotificationCenter.current().setBadgeCount(0)
                        await refreshNotifications()
                    }
                }
            }
            .onChange(of: entitlements.isPro) { _, _ in
                Task { await refreshNotifications() }
            }
            .onChange(of: preferences.weeklyDigestEnabled) { _, _ in
                Task { await refreshNotifications() }
            }
            .onChange(of: preferences.defaultLeadTimeMinutes) { _, _ in
                Task { await refreshNotifications() }
            }
    }

    private func refreshNotifications() async {
        await NotificationScheduler.replenish(
            spots: spots,
            digestEnabled: entitlements.isPro && preferences.weeklyDigestEnabled,
            isPro: entitlements.isPro
        )
    }
}
