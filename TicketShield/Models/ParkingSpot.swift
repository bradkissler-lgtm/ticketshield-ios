import Foundation
import SwiftData

@Model
final class ParkingSpot {
    @Attribute(.unique) var spotID: UUID
    var label: String
    var createdAt: Date
    var updatedAt: Date
    /// Bitmask: bit 0 = Sunday … bit 6 = Saturday (`Weekday.bit`).
    var weekdayMask: Int
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var leadTimeMinutes: Int
    /// On-device OCR text the user confirmed against. Never uploaded.
    var ocrSnippet: String
    /// Local start-of-day for which today’s reminder was cleared (“moved car”).
    var skippedAlertDay: Date?

    init(
        spotID: UUID = UUID(),
        label: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        weekdayMask: Int,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        leadTimeMinutes: Int,
        ocrSnippet: String = "",
        skippedAlertDay: Date? = nil
    ) {
        self.spotID = spotID
        self.label = label
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.weekdayMask = weekdayMask
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.leadTimeMinutes = leadTimeMinutes
        self.ocrSnippet = ocrSnippet
        self.skippedAlertDay = skippedAlertDay
    }

    var selectedWeekdays: [Weekday] {
        Weekday.orderedForDisplay().filter { weekdayMask & $0.bit != 0 }
    }

    var windowText: String {
        TimeWindowFormatting.window(
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute
        )
    }

    var daysText: String {
        TimeWindowFormatting.weekdayList(selectedWeekdays)
    }

    func apply(draft: SpotDraft) {
        label = draft.label.trimmingCharacters(in: .whitespacesAndNewlines)
        weekdayMask = Weekday.mask(from: draft.weekdays)
        let start = Calendar.current.dateComponents([.hour, .minute], from: draft.start)
        let end = Calendar.current.dateComponents([.hour, .minute], from: draft.end)
        startHour = start.hour ?? 8
        startMinute = start.minute ?? 0
        endHour = end.hour ?? 11
        endMinute = end.minute ?? 0
        leadTimeMinutes = draft.leadTimeMinutes
        if !draft.ocrSnippet.isEmpty {
            ocrSnippet = draft.ocrSnippet
        }
        updatedAt = .now
    }

    func clearTodaysAlert(now: Date = .now, calendar: Calendar = .current) {
        skippedAlertDay = calendar.startOfDay(for: now)
        updatedAt = now
    }

    func isTodaysAlertCleared(now: Date = .now, calendar: Calendar = .current) -> Bool {
        guard let skippedAlertDay else { return false }
        return calendar.isDate(skippedAlertDay, inSameDayAs: now)
    }

    func nextRestrictionStart(from now: Date = .now, calendar: Calendar = .current) -> Date? {
        let days = Set(selectedWeekdays)
        guard !days.isEmpty else { return nil }

        for offset in 0..<21 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now)) else {
                continue
            }
            let weekdayValue = calendar.component(.weekday, from: day)
            guard let weekday = Weekday(rawValue: weekdayValue), days.contains(weekday) else { continue }
            guard let start = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: day) else {
                continue
            }
            if start <= now { continue }
            if let skipped = skippedAlertDay, calendar.isDate(day, inSameDayAs: skipped) {
                continue
            }
            return start
        }
        return nil
    }
}

struct SpotDraft: Equatable {
    var label: String
    var weekdays: Set<Weekday>
    var start: Date
    var end: Date
    var leadTimeMinutes: Int
    var ocrSnippet: String

    var isValid: Bool {
        !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !weekdays.isEmpty
    }

    static func from(suggestion: SuggestedSchedule, defaultLead: Int) -> SpotDraft {
        SpotDraft(
            label: suggestion.label,
            weekdays: suggestion.weekdays,
            start: TimeWindowFormatting.dateWith(hour: suggestion.startHour, minute: suggestion.startMinute),
            end: TimeWindowFormatting.dateWith(hour: suggestion.endHour, minute: suggestion.endMinute),
            leadTimeMinutes: defaultLead,
            ocrSnippet: suggestion.ocrSnippet
        )
    }

    static func from(spot: ParkingSpot) -> SpotDraft {
        SpotDraft(
            label: spot.label,
            weekdays: Weekday.set(fromMask: spot.weekdayMask),
            start: TimeWindowFormatting.dateWith(hour: spot.startHour, minute: spot.startMinute),
            end: TimeWindowFormatting.dateWith(hour: spot.endHour, minute: spot.endMinute),
            leadTimeMinutes: spot.leadTimeMinutes,
            ocrSnippet: spot.ocrSnippet
        )
    }
}
