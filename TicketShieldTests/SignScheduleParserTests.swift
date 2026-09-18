import XCTest
@testable import TicketShield

final class SignScheduleParserTests: XCTestCase {
    func testSampleStreetCleaningSign() {
        let text = """
        NO PARKING
        STREET CLEANING
        MONDAY
        8:00 AM — 11:00 AM
        TOW-AWAY ZONE
        """
        let result = SignScheduleParser.parse(text)
        XCTAssertEqual(result.weekdays, [.monday])
        XCTAssertEqual(result.startHour, 8)
        XCTAssertEqual(result.startMinute, 0)
        XCTAssertEqual(result.endHour, 11)
        XCTAssertEqual(result.endMinute, 0)
        XCTAssertEqual(result.label, "Street cleaning")
        XCTAssertTrue(result.foundDays)
        XCTAssertTrue(result.foundTime)
    }

    func testTuesdayFridayMorningWindow() {
        let result = SignScheduleParser.parse("NO PARKING Tue & Fri 9:00 AM to 12:00 PM")
        XCTAssertEqual(result.weekdays, [.tuesday, .friday])
        XCTAssertEqual(result.startHour, 9)
        XCTAssertEqual(result.endHour, 12)
        XCTAssertTrue(result.foundTime)
    }

    func testMondayThroughFridayRange() {
        let result = SignScheduleParser.parse("STREET CLEANING MON-FRI 7:30AM-9AM")
        XCTAssertEqual(
            result.weekdays,
            [.monday, .tuesday, .wednesday, .thursday, .friday]
        )
        XCTAssertEqual(result.startHour, 7)
        XCTAssertEqual(result.startMinute, 30)
        XCTAssertEqual(result.endHour, 9)
        XCTAssertEqual(result.endMinute, 0)
    }

    func testThursdayAndSaturdayNames() {
        let result = SignScheduleParser.parse("ALTERNATE SIDE PARKING THURSDAY AND SATURDAY")
        XCTAssertEqual(result.weekdays, [.thursday, .saturday])
        XCTAssertEqual(result.label, "Alternate side")
        XCTAssertFalse(result.foundTime)
        XCTAssertEqual(result.startHour, 8)
        XCTAssertEqual(result.endHour, 11)
    }

    func testEmptyFallsBackToManualConfirm() {
        let result = SignScheduleParser.parse(" ")
        XCTAssertTrue(result.weekdays.isEmpty)
        XCTAssertFalse(result.foundDays)
        XCTAssertFalse(result.foundTime)
        XCTAssertEqual(result.label, "Parking sign")
    }

    func testNoParkingLabelWhenNoStreetCleaning() {
        let result = SignScheduleParser.parse("NO PARKING 11:00AM TO 12:30PM WEDNESDAY")
        XCTAssertEqual(result.weekdays, [.wednesday])
        XCTAssertEqual(result.startHour, 11)
        XCTAssertEqual(result.endHour, 12)
        XCTAssertEqual(result.endMinute, 30)
        XCTAssertEqual(result.label, "No parking")
    }

    func testMWFLetterPattern() {
        let result = SignScheduleParser.parse("NO PARKING MWF 8AM-10AM")
        XCTAssertEqual(result.weekdays, [.monday, .wednesday, .friday])
        XCTAssertEqual(result.startHour, 8)
        XCTAssertEqual(result.endHour, 10)
    }

    func testLeadTimeFreeClamp() {
        XCTAssertEqual(LeadTimeOptions.effective(stored: 10, isPro: false), 15)
        XCTAssertEqual(LeadTimeOptions.effective(stored: 30, isPro: false), 30)
        XCTAssertEqual(LeadTimeOptions.effective(stored: 10, isPro: true), 10)
    }

    func testSpotLimit() {
        XCTAssertTrue(SpotLimit.canAdd(existingCount: 0, isPro: false))
        XCTAssertFalse(SpotLimit.canAdd(existingCount: 1, isPro: false))
        XCTAssertTrue(SpotLimit.canAdd(existingCount: 8, isPro: true))
    }

    func testProductIDs() {
        XCTAssertTrue(ProductIDs.unlocksPro("ticketshield.pro.lifetime"))
        XCTAssertTrue(ProductIDs.unlocksPro("ticketshield.pro.annual"))
        XCTAssertFalse(ProductIDs.unlocksPro("ticketshield.pro.monthly"))
    }
}
