import XCTest
@testable import apple_calendar_cli

final class AlertHelperTests: XCTestCase {
    func testParseMinutes() {
        XCTAssertEqual(AlertHelper.parseOffset("15m"), -900)
    }

    func testParseHours() {
        XCTAssertEqual(AlertHelper.parseOffset("1h"), -3600)
    }

    func testParseDays() {
        XCTAssertEqual(AlertHelper.parseOffset("1d"), -86400)
    }

    func testParseWeeks() {
        XCTAssertEqual(AlertHelper.parseOffset("1w"), -604_800)
    }

    func testParseSeconds() {
        XCTAssertEqual(AlertHelper.parseOffset("30s"), -30)
    }

    func testParseInvalidReturnsNil() {
        XCTAssertNil(AlertHelper.parseOffset("abc"))
        XCTAssertNil(AlertHelper.parseOffset(""))
        XCTAssertNil(AlertHelper.parseOffset("15x"))
    }
}
