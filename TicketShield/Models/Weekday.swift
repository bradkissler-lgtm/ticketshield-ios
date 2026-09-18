import Foundation

/// Matches `Calendar` weekday values: 1 = Sunday … 7 = Saturday.
enum Weekday: Int, CaseIterable, Codable, Identifiable, Hashable {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    var id: Int { rawValue }

    var bit: Int { 1 << (rawValue - 1) }

    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    var letter: String {
        switch self {
        case .sunday, .saturday: return "S"
        case .monday: return "M"
        case .tuesday, .thursday: return "T"
        case .wednesday: return "W"
        case .friday: return "F"
        }
    }

    var accessibilityName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    static func orderedForDisplay(calendar: Calendar = .current) -> [Weekday] {
        let first = calendar.firstWeekday
        return (0..<7).compactMap { Weekday(rawValue: ((first - 1 + $0) % 7) + 1) }
    }

    static func set(fromMask mask: Int) -> Set<Weekday> {
        Set(allCases.filter { mask & $0.bit != 0 })
    }

    static func mask(from set: Set<Weekday>) -> Int {
        set.reduce(0) { $0 | $1.bit }
    }
}
