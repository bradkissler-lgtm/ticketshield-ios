import Foundation
import SwiftData
import SwiftUI

/// Debug-only launch mode used by the GitHub macOS workflow to capture App Store screenshots.
/// Release archives ignore `--screenshot` and never seed sample data.
enum ScreenshotMode {
    static var screen: String? {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "--screenshot"), index + 1 < args.count else {
            return nil
        }
        let name = args[index + 1]
        let allowed = ["empty", "confirm", "saved", "detail", "paywall"]
        return allowed.contains(name) ? name : nil
        #else
        return nil
        #endif
    }

    static var isActive: Bool { screen != nil }

    static func makeContainer() -> ModelContainer {
        if isActive {
            do {
                let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
                return try ModelContainer(for: ParkingSpot.self, configurations: configuration)
            } catch {
                fatalError("Screenshot store failed: \(error.localizedDescription)")
            }
        }
        do {
            return try ModelContainer(for: ParkingSpot.self)
        } catch {
            fatalError("Could not open the on-device store: \(error.localizedDescription)")
        }
    }

    static func markReady() {
        #if DEBUG
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        let url = documents.appendingPathComponent("screenshot-ready")
        try? Data((screen ?? "ready").utf8).write(to: url)
        #endif
    }

    static func sampleSpot() -> ParkingSpot {
        ParkingSpot(
            spotID: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE") ?? UUID(),
            label: "Home street cleaning",
            weekdayMask: Weekday.monday.bit,
            startHour: 8,
            startMinute: 0,
            endHour: 11,
            endMinute: 0,
            leadTimeMinutes: 30,
            ocrSnippet: "NO PARKING\nSTREET CLEANING\nMONDAY\n8:00 AM — 11:00 AM"
        )
    }
}

struct ScreenshotHost: View {
    let screen: String

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ParkingSpot.createdAt) private var spots: [ParkingSpot]

    var body: some View {
        content
            .preferredColorScheme(.light)
            .task(id: readyToken) {
                if (screen == "saved" || screen == "detail"), spots.isEmpty {
                    modelContext.insert(ScreenshotMode.sampleSpot())
                    try? modelContext.save()
                    return
                }
                guard isReady else { return }
                try? await Task.sleep(for: .milliseconds(900))
                ScreenshotMode.markReady()
            }
    }

    private var readyToken: String {
        "\(screen)-\(spots.count)"
    }

    private var isReady: Bool {
        switch screen {
        case "saved", "detail":
            return !spots.isEmpty
        default:
            return true
        }
    }

    @ViewBuilder
    private var content: some View {
        switch screen {
        case "confirm":
            NavigationStack {
                ConfirmScheduleView(
                    title: "Confirm schedule",
                    draft: SpotDraft(
                        label: "Street cleaning",
                        weekdays: [.monday],
                        start: TimeWindowFormatting.dateWith(hour: 8, minute: 0),
                        end: TimeWindowFormatting.dateWith(hour: 11, minute: 0),
                        leadTimeMinutes: 30,
                        ocrSnippet: "NO PARKING STREET CLEANING MONDAY 8:00 AM — 11:00 AM TOW-AWAY ZONE"
                    ),
                    foundDays: true,
                    foundTime: true,
                    onSave: { _ in }
                )
            }
        case "saved":
            SpotListView()
        case "detail":
            NavigationStack {
                if let spot = spots.first {
                    SpotDetailView(spot: spot)
                }
            }
        case "paywall":
            PaywallView()
        default:
            SpotListView()
        }
    }
}
