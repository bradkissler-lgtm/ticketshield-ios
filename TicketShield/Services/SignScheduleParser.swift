import Foundation

enum SignScheduleParser {
    private struct ClockTime {
        var hour24: Int
        var minute: Int
    }

    static func parse(_ raw: String) -> SuggestedSchedule {
        let normalized = normalize(raw)
        let days = detectDays(in: normalized)
        let time = detectTimeRange(in: normalized)
        let label = detectLabel(in: normalized)
        return SuggestedSchedule(
            weekdays: days,
            startHour: time?.start.hour24 ?? 8,
            startMinute: time?.start.minute ?? 0,
            endHour: time?.end.hour24 ?? 11,
            endMinute: time?.end.minute ?? 0,
            label: label,
            foundDays: !days.isEmpty,
            foundTime: time != nil,
            ocrSnippet: raw.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private static func normalize(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{2013}", with: "-")
            .replacingOccurrences(of: "\u{2014}", with: "-")
            .replacingOccurrences(of: "\u{2212}", with: "-")
            .uppercased()
    }

    // MARK: Days

    private static func detectDays(in text: String) -> Set<Weekday> {
        var working = maskClockTokens(in: text)
        var days = Set<Weekday>()

        days.formUnion(detectRanges(in: working))
        working = stripNamedDays(from: working)
        days.formUnion(detectNamedDays(in: text))
        days.formUnion(detectLetterPattern(in: working))
        return days
    }

    private static let namedDayTokens: [(Weekday, [String])] = [
        (.sunday, ["SUNDAYS", "SUNDAY", "SUNS", "SUN"]),
        (.monday, ["MONDAYS", "MONDAY", "MONS", "MON"]),
        (.tuesday, ["TUESDAYS", "TUESDAY", "TUES", "TUE"]),
        (.wednesday, ["WEDNESDAYS", "WEDNESDAY", "WEDS", "WED"]),
        (.thursday, ["THURSDAYS", "THURSDAY", "THURS", "THUR", "THU"]),
        (.friday, ["FRIDAYS", "FRIDAY", "FRIS", "FRI"]),
        (.saturday, ["SATURDAYS", "SATURDAY", "SATS", "SAT"])
    ]

    private static func detectNamedDays(in text: String) -> Set<Weekday> {
        var found = Set<Weekday>()
        for (day, tokens) in namedDayTokens {
            for token in tokens {
                if hasWord(token, in: text) {
                    found.insert(day)
                    break
                }
            }
        }
        return found
    }

    private static func detectRanges(in text: String) -> Set<Weekday> {
        var found = Set<Weekday>()
        let pattern = #"\b(SUNDAYS|SUNDAY|SUN|MONDAYS|MONDAY|MON|TUESDAYS|TUESDAY|TUES|TUE|WEDNESDAYS|WEDNESDAY|WEDS|WED|THURSDAYS|THURSDAY|THURS|THUR|THU|FRIDAYS|FRIDAY|FRIS|FRI|SATURDAYS|SATURDAY|SAT)\s*(?:-|TO|THROUGH|THRU)\s*(SUNDAYS|SUNDAY|SUN|MONDAYS|MONDAY|MON|TUESDAYS|TUESDAY|TUES|TUE|WEDNESDAYS|WEDNESDAY|WEDS|WED|THURSDAYS|THURSDAY|THURS|THUR|THU|FRIDAYS|FRIDAY|FRIS|FRI|SATURDAYS|SATURDAY|SAT)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return found }
        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        for match in matches where match.numberOfRanges >= 3 {
            let startToken = ns.substring(with: match.range(at: 1))
            let endToken = ns.substring(with: match.range(at: 2))
            if let start = weekday(forToken: startToken), let end = weekday(forToken: endToken) {
                found.formUnion(daysInclusive(from: start, to: end))
            }
        }
        return found
    }

    private static func daysInclusive(from start: Weekday, to end: Weekday) -> Set<Weekday> {
        var result = Set<Weekday>()
        var current = start.rawValue
        for _ in 0..<7 {
            if let day = Weekday(rawValue: current) {
                result.insert(day)
            }
            if current == end.rawValue { break }
            current = current == 7 ? 1 : current + 1
        }
        return result
    }

    private static func weekday(forToken token: String) -> Weekday? {
        for (day, tokens) in namedDayTokens where tokens.contains(token) {
            return day
        }
        return nil
    }

    private static func stripNamedDays(from text: String) -> String {
        var working = text
        let allTokens = namedDayTokens.flatMap(\.1).sorted { $0.count > $1.count }
        for token in allTokens {
            working = working.replacingOccurrences(of: token, with: " ")
        }
        return working
    }

    /// Matches M/W/F or T/TH after day names and clock tokens are stripped.
    private static func detectLetterPattern(in text: String) -> Set<Weekday> {
        let compact = text
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: "&", with: "")
        var days = Set<Weekday>()
        if compact.contains("MWF") {
            days.formUnion([.monday, .wednesday, .friday])
        }
        if compact.contains("TTH") || compact.contains("TUTH") {
            days.formUnion([.tuesday, .thursday])
        }
        return days
    }

    private static func hasWord(_ word: String, in text: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: "\\b\(NSRegularExpression.escapedPattern(for: word))\\b") else {
            return false
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.firstMatch(in: text, range: range) != nil
    }

    private static func maskClockTokens(in text: String) -> String {
        var working = text
        let patterns = [
            #"\b\d{1,2}(?::\d{2})?\s*(?:A\.?M\.?|P\.?M\.?|NOON|MIDNIGHT)?\b"#,
            #"\b(?:A\.?M\.?|P\.?M\.?)\b"#
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            working = regex.stringByReplacingMatches(
                in: working,
                range: NSRange(location: 0, length: (working as NSString).length),
                withTemplate: " "
            )
        }
        return working
    }

    // MARK: Times

    private static func detectTimeRange(in text: String) -> (start: ClockTime, end: ClockTime)? {
        let pattern = #"\b(\d{1,2})(?::(\d{2}))?\s*(A\.?M\.?|P\.?M\.?|NOON|MIDNIGHT)?\s*(?:-|TO)\s*(\d{1,2})(?::(\d{2}))?\s*(A\.?M\.?|P\.?M\.?|NOON|MIDNIGHT)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let ns = text as NSString
        guard let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)),
              match.numberOfRanges >= 7
        else { return nil }

        func group(_ index: Int) -> String? {
            let range = match.range(at: index)
            guard range.location != NSNotFound else { return nil }
            let value = ns.substring(with: range)
            return value.isEmpty ? nil : value
        }

        guard let startHourRaw = group(1), let startHour = Int(startHourRaw) else { return nil }
        let startMinute = group(2).flatMap(Int.init) ?? 0
        let startMer = group(3)
        guard let endHourRaw = group(4), let endHour = Int(endHourRaw) else { return nil }
        let endMinute = group(5).flatMap(Int.init) ?? 0
        let endMer = group(6)

        let (resolvedStartMer, resolvedEndMer) = inferMeridiems(
            startHour: startHour,
            startMer: startMer,
            endHour: endHour,
            endMer: endMer
        )
        guard let start = clock(hour: startHour, minute: startMinute, meridiem: resolvedStartMer),
              let end = clock(hour: endHour, minute: endMinute, meridiem: resolvedEndMer)
        else { return nil }
        return (start, end)
    }

    private static func inferMeridiems(
        startHour: Int,
        startMer: String?,
        endHour: Int,
        endMer: String?
    ) -> (String?, String?) {
        if startMer != nil || endMer != nil {
            if startMer == nil { return (endMer, endMer) }
            if endMer == nil { return (startMer, startMer) }
            return (startMer, endMer)
        }
        // Street-cleaning windows are almost always morning.
        if startHour >= 1 && startHour <= 11 && endHour >= 1 && endHour <= 12 {
            return ("AM", endHour == 12 ? "PM" : "AM")
        }
        return ("AM", "AM")
    }

    private static func clock(hour: Int, minute: Int, meridiem: String?) -> ClockTime? {
        guard (0...12).contains(hour) || (0...23).contains(hour), (0...59).contains(minute) else {
            return nil
        }
        var hour24 = hour
        let mer = meridiem?.replacingOccurrences(of: ".", with: "") ?? ""
        if mer == "NOON" {
            hour24 = 12
        } else if mer == "MIDNIGHT" {
            hour24 = 0
        } else if mer.hasPrefix("P") {
            if hour != 12 { hour24 = hour + 12 }
        } else if mer.hasPrefix("A") {
            if hour == 12 { hour24 = 0 }
        } else if hour == 24 {
            hour24 = 0
        }
        guard (0...23).contains(hour24) else { return nil }
        return ClockTime(hour24: hour24, minute: minute)
    }

    // MARK: Label

    private static func detectLabel(in text: String) -> String {
        if hasPhrase("STREET CLEANING", in: text) || hasPhrase("STREET SWEEPING", in: text) {
            return "Street cleaning"
        }
        if hasPhrase("ALTERNATE SIDE", in: text) || hasPhrase("ALTERNATE-SIDE", in: text) {
            return "Alternate side"
        }
        if hasPhrase("TOW-AWAY", in: text) || hasPhrase("TOW AWAY", in: text) {
            return "Tow-away"
        }
        if hasPhrase("NO PARKING", in: text) {
            return "No parking"
        }
        return "Parking sign"
    }

    private static func hasPhrase(_ phrase: String, in text: String) -> Bool {
        text.contains(phrase)
    }
}
