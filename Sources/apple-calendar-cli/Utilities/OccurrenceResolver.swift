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
        var isRecurring = true
    }

    /// Range for finding unmodified occurrences; detached occurrences are looked up by identifier.
    static let searchWindow: TimeInterval = 7 * 24 * 60 * 60

    /// Splits an occurrence-specific identifier. A moved or edited occurrence gets its own identifier,
    /// `<series identifier>/RID=<n>`, where `n` is its original start in seconds since 2001-01-01 UTC
    /// (EventKit's reference date). Any other identifier is returned unchanged with no date.
    static func split(_ identifier: String) -> (series: String, originalDate: Date?) {
        guard let range = identifier.range(of: "/RID=", options: .backwards),
              let seconds = Double(identifier[range.upperBound...]) else {
            return (identifier, nil)
        }
        return (String(identifier[..<range.lowerBound]), Date(timeIntervalSinceReferenceDate: seconds))
    }

    /// The original start of an occurrence. For a moved occurrence EventKit reports the new start as
    /// `occurrenceDate`, so the date encoded in its identifier wins.
    static func originalDate(identifier: String, occurrenceDate: Date?) -> Date? {
        split(identifier).originalDate ?? occurrenceDate
    }

    /// Index of the occurrence whose original start is `date`. Current starts can name a different
    /// occurrence after moves, so they must never be used as a fallback for a series identifier.
    static func match(_ candidates: [Candidate], identifier: String, date: Date) -> Int? {
        let series = split(identifier).series
        let members = candidates.indices.filter { split(candidates[$0].identifier).series == series }
        return members.first(where: {
            let candidate = candidates[$0]
            return same(originalDate(identifier: candidate.identifier, occurrenceDate: candidate.occurrenceDate), date)
        })
    }

    /// Resolve through the same lookup and date-range operations used by CalendarService. Keeping
    /// these operations injectable lets tests model a moved occurrence outside the fetched range.
    static func resolve<Event>(
        identifier: String,
        occurrence: Date?,
        span: EventSpan,
        lookup: (String) -> Event?,
        fetch: (Date, Date, Event) -> [Event],
        describe: (Event) -> Candidate
    ) throws -> Event {
        let (series, encodedDate) = split(identifier)
        if span != .all, encodedDate != nil {
            // An exact identifier is authoritative. Never replace a missing detached event with
            // another member of its series, even if that member occupies the same time slot.
            guard let event = lookup(identifier), describe(event).identifier == identifier else {
                throw CalendarServiceError.eventNotFound(identifier)
            }
            let candidate = describe(event)
            if let occurrence,
               !same(originalDate(identifier: identifier, occurrenceDate: candidate.occurrenceDate), occurrence),
               !same(candidate.startDate, occurrence) {
                throw notFound(identifier: identifier, date: occurrence)
            }
            return event
        }

        guard let event = lookup(series) else {
            throw CalendarServiceError.eventNotFound(identifier)
        }
        let candidate = describe(event)
        if requiresOccurrence(isRecurring: candidate.isRecurring, span: span, occurrenceGiven: occurrence != nil) {
            throw CalendarServiceError.occurrenceRequired(identifier)
        }
        guard candidate.isRecurring, span != .all, let occurrence else {
            return event
        }

        // A detached occurrence may be arbitrarily far from its original slot. Probe its RID
        // directly, and validate the returned event because providers can interpret IDs differently.
        let seconds = occurrence.timeIntervalSinceReferenceDate
        let rid = seconds.rounded() == seconds ? String(format: "%.0f", seconds) : String(seconds)
        if let detached = lookup("\(series)/RID=\(rid)"),
           match([describe(detached)], identifier: series, date: occurrence) != nil {
            return detached
        }

        let events = fetch(
            occurrence.addingTimeInterval(-searchWindow),
            occurrence.addingTimeInterval(searchWindow),
            event
        )
        guard let index = match(events.map(describe), identifier: series, date: occurrence) else {
            throw notFound(identifier: identifier, date: occurrence)
        }
        return events[index]
    }

    private static func same(_ lhs: Date?, _ rhs: Date) -> Bool {
        guard let lhs else { return false }
        return abs(lhs.timeIntervalSince(rhs)) < 1
    }

    private static func notFound(identifier: String, date: Date) -> CalendarServiceError {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = .current
        return .occurrenceNotFound(identifier, formatter.string(from: date))
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
