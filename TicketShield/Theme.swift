import SwiftUI

enum TSTheme {
    static let navy = Color(red: 0.043, green: 0.122, blue: 0.200)
    static let teal = Color(red: 0.122, green: 0.478, blue: 0.420)
    static let cream = Color(red: 0.965, green: 0.957, blue: 0.937)
    static let amber = Color(red: 0.910, green: 0.659, blue: 0.220)
    static let ink = Color(red: 0.10, green: 0.14, blue: 0.18)

    static var background: Color { Color(.systemBackground) }
    static var groupedBackground: Color { Color(.systemGroupedBackground) }
}

enum LeadTimeOptions {
    static let free = [15, 30, 60]
    static let pro = [5, 10, 15, 20, 30, 45, 60, 90, 120]
    static let defaultMinutes = 30

    static func available(isPro: Bool) -> [Int] {
        isPro ? pro : free
    }

    /// Free reminders only fire at 15 / 30 / 60 minutes. Pro values are used as saved.
    static func effective(stored: Int, isPro: Bool) -> Int {
        if isPro { return stored }
        return free.min(by: { abs($0 - stored) < abs($1 - stored) }) ?? defaultMinutes
    }
}

enum SpotLimit {
    static let freeMax = 1

    static func canAdd(existingCount: Int, isPro: Bool) -> Bool {
        isPro || existingCount < freeMax
    }
}

enum TimeWindowFormatting {
    static func time(hour: Int, minute: Int, calendar: Calendar = .current) -> String {
        let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    static func window(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) -> String {
        "\(time(hour: startHour, minute: startMinute))–\(time(hour: endHour, minute: endMinute))"
    }

    static func dateWith(hour: Int, minute: Int, calendar: Calendar = .current) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    static func weekdayList(_ days: [Weekday]) -> String {
        let ordered = Weekday.orderedForDisplay()
        let selected = ordered.filter { days.contains($0) }
        return selected.map(\.shortName).joined(separator: ", ")
    }
}
