import XCTest
@testable import apple_calendar_cli

final class OccurrenceResolverTests: XCTestCase {
    private typealias Candidate = OccurrenceResolver.Candidate

    private func date(_ string: String) -> Date {
        DateParser.parse(string)!
    }

    /// A weekly series: every occurrence shares the identifier and differs by occurrenceDate.
    private func weeklySeries(id: String = "SERIES") -> [Candidate] {
        ["2026-03-02T09:00:00", "2026-03-09T09:00:00", "2026-03-16T09:00:00"].map {
            Candidate(identifier: id, occurrenceDate: date($0), startDate: date($0))
        }
    }

    func testMatchPicksTheAddressedOccurrenceNotTheFirst() {
        let index = OccurrenceResolver.match(weeklySeries(), identifier: "SERIES", date: date("2026-03-09T09:00:00"))
        XCTAssertEqual(index, 1)
    }

    func testMatchAcceptsISO8601WithOffset() {
        let local = date("2026-03-16T09:00:00")
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        let utcString = formatter.string(from: local)
        let index = OccurrenceResolver.match(weeklySeries(), identifier: "SERIES", date: date(utcString))
        XCTAssertEqual(index, 2)
    }

    func testMatchIgnoresOtherEventsAtTheSameTime() {
        var candidates = [Candidate(
            identifier: "OTHER", occurrenceDate: nil, startDate: date("2026-03-09T09:00:00")
        )]
        candidates += weeklySeries()
        let index = OccurrenceResolver.match(candidates, identifier: "SERIES", date: date("2026-03-09T09:00:00"))
        XCTAssertEqual(index, 2)
    }

    func testMatchFindsMovedOccurrenceByOriginalDate() {
        var candidates = weeklySeries()
        candidates[1] = Candidate(
            identifier: "SERIES",
            occurrenceDate: date("2026-03-09T09:00:00"),
            startDate: date("2026-03-10T14:00:00")
        )
        XCTAssertEqual(
            OccurrenceResolver.match(candidates, identifier: "SERIES", date: date("2026-03-09T09:00:00")), 1
        )
    }

    func testMatchFindsMovedOccurrenceByNewStart() {
        var candidates = weeklySeries()
        candidates[1] = Candidate(
            identifier: "SERIES",
            occurrenceDate: date("2026-03-09T09:00:00"),
            startDate: date("2026-03-10T14:00:00")
        )
        XCTAssertEqual(
            OccurrenceResolver.match(candidates, identifier: "SERIES", date: date("2026-03-10T14:00:00")), 1
        )
    }

    func testMatchPrefersOriginalDateOverAnotherOccurrencesNewStart() {
        // Occurrence 0 was moved onto occurrence 1's original slot; the original date wins.
        var candidates = weeklySeries()
        candidates[0] = Candidate(
            identifier: "SERIES",
            occurrenceDate: date("2026-03-02T09:00:00"),
            startDate: date("2026-03-09T09:00:00")
        )
        XCTAssertEqual(
            OccurrenceResolver.match(candidates, identifier: "SERIES", date: date("2026-03-09T09:00:00")), 1
        )
    }

    func testMatchAllDayOccurrenceByDateOnly() {
        let candidates = ["2026-03-02", "2026-03-09"].map {
            Candidate(identifier: "ALLDAY", occurrenceDate: date($0), startDate: date($0))
        }
        XCTAssertEqual(OccurrenceResolver.match(candidates, identifier: "ALLDAY", date: date("2026-03-09")), 1)
    }

    func testMatchReturnsNilWhenNoOccurrenceAtThatTime() {
        XCTAssertNil(OccurrenceResolver.match(weeklySeries(), identifier: "SERIES", date: date("2026-03-09T10:00:00")))
        XCTAssertNil(OccurrenceResolver.match(weeklySeries(), identifier: "OTHER", date: date("2026-03-09T09:00:00")))
    }

    func testRecurringChangeNeedsAnOccurrenceUnlessWholeSeries() {
        XCTAssertTrue(OccurrenceResolver.requiresOccurrence(isRecurring: true, span: .this, occurrenceGiven: false))
        XCTAssertTrue(OccurrenceResolver.requiresOccurrence(isRecurring: true, span: .future, occurrenceGiven: false))
        XCTAssertFalse(OccurrenceResolver.requiresOccurrence(isRecurring: true, span: .all, occurrenceGiven: false))
        XCTAssertFalse(OccurrenceResolver.requiresOccurrence(isRecurring: true, span: .this, occurrenceGiven: true))
        XCTAssertFalse(OccurrenceResolver.requiresOccurrence(isRecurring: false, span: .this, occurrenceGiven: false))
    }

    func testWholeSeriesSpanRejectsAnOccurrence() {
        XCTAssertThrowsError(try OccurrenceResolver.validate(span: .all, occurrenceGiven: true))
        XCTAssertNoThrow(try OccurrenceResolver.validate(span: .all, occurrenceGiven: false))
        XCTAssertNoThrow(try OccurrenceResolver.validate(span: .future, occurrenceGiven: true))
    }

    func testParseOccurrence() throws {
        XCTAssertNil(try OccurrenceResolver.parseOccurrence(nil))
        XCTAssertEqual(try OccurrenceResolver.parseOccurrence("2026-03-09T09:00:00"), date("2026-03-09T09:00:00"))
        XCTAssertThrowsError(try OccurrenceResolver.parseOccurrence("next tuesday"))
    }
}

final class EventSpanTests: XCTestCase {
    func testParseDefaultsToThis() throws {
        XCTAssertEqual(try EventSpan.parse(nil), .this)
    }

    func testParseIsCaseInsensitive() throws {
        XCTAssertEqual(try EventSpan.parse("FUTURE"), .future)
        XCTAssertEqual(try EventSpan.parse("All"), .all)
    }

    func testParseRejectsUnknownSpan() {
        XCTAssertThrowsError(try EventSpan.parse("series"))
    }

    func testEventKitSpans() {
        XCTAssertEqual(EventSpan.this.ekSpan, .thisEvent)
        XCTAssertEqual(EventSpan.future.ekSpan, .futureEvents)
        // The whole series is reached by applying .futureEvents to its first occurrence.
        XCTAssertEqual(EventSpan.all.ekSpan, .futureEvents)
    }
}
