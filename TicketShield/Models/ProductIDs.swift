import Foundation

struct SuggestedSchedule: Equatable {
    var weekdays: Set<Weekday>
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var label: String
    var foundDays: Bool
    var foundTime: Bool
    var ocrSnippet: String

    static let empty = SuggestedSchedule(
        weekdays: [],
        startHour: 8,
        startMinute: 0,
        endHour: 11,
        endMinute: 0,
        label: "Parking sign",
        foundDays: false,
        foundTime: false,
        ocrSnippet: ""
    )
}

enum ProductIDs {
    static let lifetime = "ticketshield.pro.lifetime"
    static let annual = "ticketshield.pro.annual"

    static let all: Set<String> = [lifetime, annual]

    static func unlocksPro(_ productID: String) -> Bool {
        all.contains(productID)
    }
}
