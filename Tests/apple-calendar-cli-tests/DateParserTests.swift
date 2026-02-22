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

    func testRoundTripPreservesLocalTime() {
        // Parse a local datetime string
        let input = "2026-02-22T14:30:00"
        let date = DateParser.parse(input)
        XCTAssertNotNil(date)

        // Format it back using the same ISO8601 config as EventInfo (local timezone)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = .current
        let output = formatter.string(from: date!)

        // The output should start with the same date and time (local), not be shifted to UTC
        XCTAssertTrue(output.hasPrefix("2026-02-22T14:30:00"), "Expected local time 14:30, got: \(output)")
        // Should have a timezone offset, not Z (unless the local timezone happens to be UTC)
        if TimeZone.current.secondsFromGMT() != 0 {
            XCTAssertFalse(output.hasSuffix("Z"), "Expected local timezone offset, not Z: \(output)")
        }
    }

    func testParseInvalidReturnsNil() {
        XCTAssertNil(DateParser.parse("not-a-date"))
        XCTAssertNil(DateParser.parse(""))
        XCTAssertNil(DateParser.parse("2026-13-01"))
    }
}
