import ArgumentParser
@preconcurrency import EventKit
import Foundation

/// How far a change to a recurring event reaches.
enum EventSpan: String, CaseIterable {
    /// Only the addressed occurrence.
    case this
    /// The addressed occurrence and every later one.
    case future
    /// The whole series, including past occurrences.
    case all

    static func parse(_ value: String?) throws -> EventSpan {
        guard let value else { return .this }
        guard let span = EventSpan(rawValue: value.lowercased()) else {
            throw ValidationError("Invalid --span value: '\(value)'. Use 'this', 'future', or 'all'.")
        }
        return span
    }

    /// `.all` is applied as `.futureEvents` from the series' first occurrence.
    var ekSpan: EKSpan {
        self == .this ? .thisEvent : .futureEvents
    }
}

/// Picks one occurrence of a recurring event.
///
/// EventKit's `event(withIdentifier:)` returns the *first* occurrence of a recurring event, so an
/// identifier alone cannot address a later one. Occurrences share the identifier and differ by
/// `occurrenceDate` (their original start), which callers pass back as `--occurrence`.
enum OccurrenceResolver {
    struct Candidate {
        let identifier: String
        let occurrenceDate: Date?
        let startDate: Date
    }

    /// How far either side of `--occurrence` to search; wide enough to find an occurrence that was moved.
    static let searchWindow: TimeInterval = 7 * 24 * 60 * 60

    /// Index of the occurrence of `identifier` whose original start is `date`, or failing that, the
    /// one that now starts at `date` (a moved occurrence addressed by its new start).
    static func match(_ candidates: [Candidate], identifier: String, date: Date) -> Int? {
        func same(_ lhs: Date?, _ rhs: Date) -> Bool {
            guard let lhs else { return false }
            return abs(lhs.timeIntervalSince(rhs)) < 1
        }
        if let index = candidates.firstIndex(where: { $0.identifier == identifier && same($0.occurrenceDate, date) }) {
            return index
        }
        return candidates.firstIndex(where: { $0.identifier == identifier && same($0.startDate, date) })
    }

    /// Parses `--occurrence`; nil when it was not given.
    static func parseOccurrence(_ value: String?) throws -> Date? {
        guard let value else { return nil }
        guard let date = DateParser.parse(value) else {
            throw ValidationError("Invalid --occurrence date: '\(value)'. Use YYYY-MM-DD or ISO 8601 format.")
        }
        return date
    }

    /// `--span all` always means the whole series, so naming one occurrence alongside it is a mistake.
    static func validate(span: EventSpan, occurrenceGiven: Bool) throws {
        if span == .all && occurrenceGiven {
            throw ValidationError("--occurrence can't be combined with --span all, which changes the whole series.")
        }
    }

    /// A recurring event can only be changed without `--occurrence` when the whole series is meant.
    static func requiresOccurrence(isRecurring: Bool, span: EventSpan, occurrenceGiven: Bool) -> Bool {
        isRecurring && span != .all && !occurrenceGiven
    }
}
