import Foundation
import UserNotifications

enum NotificationScheduler {
    private static let prefix = "ticketshield."
    private static let digestPrefix = "ticketshield.digest."
    /// iOS allows 64 pending requests. Keep a cushion for the weekly digest.
    private static let maxSpotRequests = 50

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func replenish(
        spots: [ParkingSpot],
        digestEnabled: Bool,
        isPro: Bool,
        now: Date = .now,
        calendar: Calendar = .current
    ) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ours = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        if !ours.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: ours)
        }

        var requests: [UNNotificationRequest] = []
        var fires: [(date: Date, spot: ParkingSpot, lead: Int)] = []

        for spot in spots {
            let lead = LeadTimeOptions.effective(stored: spot.leadTimeMinutes, isPro: isPro)
            for date in upcomingRestrictionStarts(for: spot, from: now, calendar: calendar, limit: 16) {
                let fire = date.addingTimeInterval(TimeInterval(-lead * 60))
                if fire > now {
                    fires.append((fire, spot, lead))
                }
            }
        }

        fires.sort { $0.date < $1.date }
        for item in fires.prefix(maxSpotRequests) {
            let content = UNMutableNotificationContent()
            content.title = "Time to move your car"
            content.body = "\(item.spot.label) — restriction \(item.spot.windowText)."
            content.sound = .default
            content.threadIdentifier = item.spot.spotID.uuidString
            content.userInfo = ["spotID": item.spot.spotID.uuidString]

            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: item.date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let day = calendar.dateComponents([.year, .month, .day], from: item.date)
            let identifier = "\(prefix)spot.\(item.spot.spotID.uuidString).\(day.year ?? 0)-\(day.month ?? 0)-\(day.day ?? 0)"
            requests.append(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
        }

        if digestEnabled {
            requests.append(contentsOf: digestRequests(spots: spots, from: now, calendar: calendar))
        }

        for request in requests {
            do {
                try await center.add(request)
            } catch {
                continue
            }
        }
    }

    static func upcomingRestrictionStarts(
        for spot: ParkingSpot,
        from now: Date,
        calendar: Calendar,
        limit: Int
    ) -> [Date] {
        var dates: [Date] = []
        let days = Set(spot.selectedWeekdays)
        guard !days.isEmpty else { return [] }

        for offset in 0..<80 {
            guard dates.count < limit else { break }
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now)) else {
                continue
            }
            let weekdayValue = calendar.component(.weekday, from: day)
            guard let weekday = Weekday(rawValue: weekdayValue), days.contains(weekday) else { continue }
            guard let start = calendar.date(
                bySettingHour: spot.startHour,
                minute: spot.startMinute,
                second: 0,
                of: day
            ) else { continue }
            if start <= now { continue }
            if let skipped = spot.skippedAlertDay, calendar.isDate(day, inSameDayAs: skipped) {
                continue
            }
            dates.append(start)
        }
        return dates
    }

    private static func digestRequests(
        spots: [ParkingSpot],
        from now: Date,
        calendar: Calendar
    ) -> [UNNotificationRequest] {
        let upcoming = spots.compactMap { spot -> String? in
            guard let next = spot.nextRestrictionStart(from: now, calendar: calendar) else { return nil }
            let day = Weekday(rawValue: calendar.component(.weekday, from: next))?.shortName ?? ""
            return "\(spot.label) \(day) \(spot.windowText)"
        }

        let body: String
        if upcoming.isEmpty {
            body = "No restriction windows are saved yet."
        } else {
            body = upcoming.prefix(4).joined(separator: " · ")
        }

        var requests: [UNNotificationRequest] = []
        var cursor = now
        for _ in 0..<2 {
            guard let sunday = nextSundayEvening(after: cursor, calendar: calendar) else { break }
            let content = UNMutableNotificationContent()
            content.title = "This week’s parking windows"
            content.body = body
            content.sound = .default
            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: sunday)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let day = calendar.dateComponents([.year, .month, .day], from: sunday)
            let identifier = "\(digestPrefix)\(day.year ?? 0)-\(day.month ?? 0)-\(day.day ?? 0)"
            requests.append(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
            cursor = sunday.addingTimeInterval(60)
        }
        return requests
    }

    private static func nextSundayEvening(after now: Date, calendar: Calendar) -> Date? {
        let hour = 18
        for offset in 0..<14 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now)) else {
                continue
            }
            if calendar.component(.weekday, from: day) == Weekday.sunday.rawValue {
                guard let fire = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) else {
                    continue
                }
                if fire > now { return fire }
            }
        }
        return nil
    }
}
