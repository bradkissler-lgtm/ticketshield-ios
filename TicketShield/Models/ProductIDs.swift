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

/// Public web pages for App Store Connect and the paywall.
/// GitHub Pages must serve `docs/` from `main` before these URLs return 200.
enum LegalURLs {
    static let site = "https://bradkissler-lgtm.github.io/ticketshield-ios"
    static let privacy = URL(string: "\(site)/privacy.html")!
    static let terms = URL(string: "\(site)/terms.html")!
    static let support = URL(string: "\(site)/support.html")!
    static let appleStandardEULA = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    static let annualDisplayName = "Pro Annual"
    static let annualLength = "1 year"
    static let annualPriceFallback = "$19.99"
    static let lifetimePriceFallback = "$4.99"
}
