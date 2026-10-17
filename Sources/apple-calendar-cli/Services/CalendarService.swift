@preconcurrency import EventKit
import Foundation

enum CalendarServiceError: LocalizedError {
    case accessDenied
    case accessRestricted
    case eventNotFound(String)
    case occurrenceRequired(String)
    case occurrenceNotFound(String, String)

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return """
                Calendar access denied. \
                Grant access in System Settings > Privacy & Security > Calendars.
                """
        case .accessRestricted:
            return "Calendar access is restricted on this device."
        case .eventNotFound(let identifier):
            return "Event not found with identifier: \(identifier)"
        case .occurrenceRequired(let identifier):
            return """
                Event \(identifier) repeats. Pass --occurrence with the occurrence's occurrenceDate \
                (from list-events --json) to choose one, or --span all to change the whole series.
                """
        case .occurrenceNotFound(let identifier, let date):
            return """
                No occurrence of event \(identifier) at \(date). \
                Use the occurrenceDate or startDate shown by list-events.
                """
        }
    }
}

struct CalendarService: @unchecked Sendable {
    private let store: EKEventStore

    init(store: EKEventStore = EKEventStore()) {
        self.store = store
    }

    func requestAccess() async throws {
        let granted = try await store.requestFullAccessToEvents()
        if !granted {
            throw CalendarServiceError.accessDenied
        }
    }

    func listCalendars() -> [EKCalendar] {
        store.calendars(for: .event)
    }

    func calendar(withIdentifier identifier: String) -> EKCalendar? {
        store.calendar(withIdentifier: identifier)
    }

    func defaultCalendar() -> EKCalendar? {
        store.defaultCalendarForNewEvents
    }

    func fetchEvents(from startDate: Date, to endDate: Date, in calendars: [EKCalendar]? = nil) -> [EKEvent] {
        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        return store.events(matching: predicate)
    }

    func event(withIdentifier identifier: String) -> EKEvent? {
        store.event(withIdentifier: identifier)
    }

    /// The event a command should act on. A non-recurring event, or a recurring one with `span: .all`,
    /// resolves to the event itself (for a series, its first occurrence). Otherwise `occurrence` must
    /// name one occurrence, so a later occurrence is never silently replaced by the first.
    func targetEvent(identifier: String, occurrence: Date?, span: EventSpan) throws -> EKEvent {
        guard let event = store.event(withIdentifier: identifier) else {
            throw CalendarServiceError.eventNotFound(identifier)
        }
        let isRecurring = event.hasRecurrenceRules || event.isDetached
        let needsOccurrence = OccurrenceResolver.requiresOccurrence(
            isRecurring: isRecurring, span: span, occurrenceGiven: occurrence != nil
        )
        if needsOccurrence {
            throw CalendarServiceError.occurrenceRequired(identifier)
        }
        guard isRecurring, span != .all, let occurrence else {
            return event
        }
        let window = OccurrenceResolver.searchWindow
        let events = fetchEvents(
            from: occurrence.addingTimeInterval(-window),
            to: occurrence.addingTimeInterval(window),
            in: event.calendar.map { [$0] }
        )
        let candidates = events.map {
            OccurrenceResolver.Candidate(
                identifier: $0.eventIdentifier ?? "",
                occurrenceDate: $0.occurrenceDate,
                startDate: $0.startDate
            )
        }
        guard let index = OccurrenceResolver.match(candidates, identifier: identifier, date: occurrence) else {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            formatter.timeZone = .current
            throw CalendarServiceError.occurrenceNotFound(identifier, formatter.string(from: occurrence))
        }
        return events[index]
    }

    func save(_ event: EKEvent, span: EKSpan = .thisEvent) throws {
        try store.save(event, span: span, commit: true)
    }

    func delete(_ event: EKEvent, span: EKSpan = .thisEvent) throws {
        try store.remove(event, span: span, commit: true)
    }

    func newEvent() -> EKEvent {
        EKEvent(eventStore: store)
    }
}
