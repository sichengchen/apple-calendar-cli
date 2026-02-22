import XCTest
@testable import apple_calendar_cli

final class DateParserTests: XCTestCase {
    func testParseDateOnly() {
        let date = DateParser.parse("2026-02-22")
        XCTAssertNotNil(date)

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date!)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 2)
        XCTAssertEqual(components.day, 22)
    }

    func testParseDateTimeLocal() {
        let date = DateParser.parse("2026-02-22T14:30:00")
        XCTAssertNotNil(date)

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date!)
        XCTAssertEqual(components.hour, 14)
        XCTAssertEqual(components.minute, 30)
    }

    func testParseDateTimeShort() {
        let date = DateParser.parse("2026-02-22T14:30")
        XCTAssertNotNil(date)
    }

    func testParseISO8601WithZ() {
        let date = DateParser.parse("2026-02-22T14:30:00Z")
        XCTAssertNotNil(date)
    }

    func testParseInvalidReturnsNil() {
        XCTAssertNil(DateParser.parse("not-a-date"))
        XCTAssertNil(DateParser.parse(""))
        XCTAssertNil(DateParser.parse("2026-13-01"))
    }
}
