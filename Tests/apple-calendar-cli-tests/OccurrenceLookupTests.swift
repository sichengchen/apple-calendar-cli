import XCTest
@testable import apple_calendar_cli

final class OccurrenceLookupTests: XCTestCase {
    private typealias Candidate = OccurrenceResolver.Candidate

    /// Models the two EventKit read operations. Range queries use current starts, so an occurrence
    /// moved several weeks away is absent even when its original date falls inside the range.
    private final class Store {
        var identifiers: [String: Candidate] = [:]
        var events: [Candidate] = []
        var lookups: [String] = []
        var fetchCount = 0

        func resolve(_ identifier: String, occurrence: Date? = nil, span: EventSpan = .this) throws -> Candidate {
            try OccurrenceResolver.resolve(
                identifier: identifier,
                occurrence: occurrence,
                span: span,
                lookup: { identifier in
                    self.lookups.append(identifier)
                    return self.identifiers[identifier]
                },
                fetch: { start, end, _ in
                    self.fetchCount += 1
                    return self.events.filter { $0.startDate >= start && $0.startDate < end }
                },
                describe: { $0 }
            )
        }
    }

    private func date(_ day: Int) -> Date {
        DateParser.parse(String(format: "2026-03-%02dT09:00:00Z", day))!
    }

    private func detached(original: Int, moved: Int) -> Candidate {
        Candidate(
            identifier: "SERIES/RID=\(Int(date(original).timeIntervalSinceReferenceDate))",
            occurrenceDate: date(moved),
            startDate: date(moved)
        )
    }

    private func fixture() -> Store {
        let store = Store()
        store.identifiers["SERIES"] = Candidate(
            identifier: "SERIES", occurrenceDate: date(2), startDate: date(2)
        )
        let target = detached(original: 9, moved: 30)
        let movedIn = detached(original: 2, moved: 9)
        store.events = [target, movedIn]
        store.identifiers[target.identifier] = target
        store.identifiers[movedIn.identifier] = movedIn
        return store
    }

    func testExactIdentifierFindsFarMovedOccurrenceWithoutRangeQuery() throws {
        for span in [EventSpan.this, .future] {
            let store = fixture()
            let target = detached(original: 9, moved: 30)
            let result = try store.resolve(target.identifier, span: span)
            XCTAssertEqual(result.identifier, target.identifier)
            XCTAssertEqual(result.startDate, date(30))
            XCTAssertEqual(store.lookups, [target.identifier])
            XCTAssertEqual(store.fetchCount, 0)
        }
    }

    func testOriginalDateFindsFarMovedOccurrenceBeforeCurrentStartCollision() throws {
        for span in [EventSpan.this, .future] {
            let store = fixture()
            let result = try store.resolve("SERIES", occurrence: date(9), span: span)
            XCTAssertEqual(result.identifier, detached(original: 9, moved: 30).identifier)
            XCTAssertEqual(result.startDate, date(30))
            XCTAssertEqual(store.fetchCount, 0)
        }
    }

    func testMissingExactIdentifierCannotSelectOccurrenceInItsOldSlot() {
        let store = fixture()
        let target = detached(original: 9, moved: 30)
        store.identifiers[target.identifier] = nil
        XCTAssertThrowsError(try store.resolve(target.identifier)) { error in
            guard case CalendarServiceError.eventNotFound = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertEqual(store.fetchCount, 0)
    }

    func testUnavailableDetachedLookupCannotFallBackToCurrentStart() {
        let store = fixture()
        store.identifiers[detached(original: 9, moved: 30).identifier] = nil
        XCTAssertThrowsError(try store.resolve("SERIES", occurrence: date(9))) { error in
            guard case CalendarServiceError.occurrenceNotFound = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertEqual(store.fetchCount, 1)
    }

    func testDetachedLookupReturningSeriesMasterCannotSelectWrongOccurrence() {
        let store = fixture()
        store.identifiers[detached(original: 9, moved: 30).identifier] = store.identifiers["SERIES"]
        XCTAssertThrowsError(try store.resolve("SERIES", occurrence: date(9)))
    }

    func testExactLookupReturningAnotherIdentifierIsRejected() {
        let store = fixture()
        let target = detached(original: 9, moved: 30)
        store.identifiers[target.identifier] = detached(original: 2, moved: 9)
        XCTAssertThrowsError(try store.resolve(target.identifier))
        XCTAssertEqual(store.fetchCount, 0)
    }

    func testExactIdentifierAcceptsItsOriginalOrCurrentDate() throws {
        let store = fixture()
        let target = detached(original: 9, moved: 30)
        for occurrence in [date(9), date(30)] {
            let result = try store.resolve(target.identifier, occurrence: occurrence)
            XCTAssertEqual(result.identifier, target.identifier)
        }
        XCTAssertEqual(store.fetchCount, 0)
    }

    func testExactIdentifierWithConflictingDateDoesNotRetarget() {
        let store = fixture()
        XCTAssertThrowsError(try store.resolve(detached(original: 9, moved: 30).identifier, occurrence: date(2)))
        XCTAssertEqual(store.fetchCount, 0)
    }

    func testUnmodifiedOccurrenceIsResolvedByRangeQuery() throws {
        let store = fixture()
        store.events.append(Candidate(identifier: "SERIES", occurrenceDate: date(16), startDate: date(16)))
        let result = try store.resolve("SERIES", occurrence: date(16))
        XCTAssertEqual(result.startDate, date(16))
        XCTAssertEqual(store.fetchCount, 1)
    }

    func testSeriesIdentifierDoesNotAcceptMovedCurrentStartAsOriginalDate() {
        let store = fixture()
        XCTAssertThrowsError(try store.resolve("SERIES", occurrence: date(30)))
    }

    func testRecurringMutationRequiresOccurrence() {
        for span in [EventSpan.this, .future] {
            let store = fixture()
            XCTAssertThrowsError(try store.resolve("SERIES", span: span)) { error in
                guard case CalendarServiceError.occurrenceRequired = error else {
                    return XCTFail("Unexpected error: \(error)")
                }
            }
        }
    }

    func testWholeSeriesStillResolvesMasterForAnExactIdentifier() throws {
        let store = fixture()
        let result = try store.resolve(detached(original: 9, moved: 30).identifier, span: .all)
        XCTAssertEqual(result.identifier, "SERIES")
        XCTAssertEqual(store.fetchCount, 0)
    }

    func testNonRecurringEventStillNeedsNoOccurrence() throws {
        let store = Store()
        store.identifiers["SINGLE"] = Candidate(
            identifier: "SINGLE", occurrenceDate: nil, startDate: date(9), isRecurring: false
        )
        XCTAssertEqual(try store.resolve("SINGLE").identifier, "SINGLE")
        XCTAssertEqual(store.fetchCount, 0)
    }
}
