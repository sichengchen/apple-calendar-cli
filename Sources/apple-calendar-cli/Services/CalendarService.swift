@preconcurrency import EventKit
import Foundation

enum CalendarServiceError: LocalizedError {
    case accessDenied
    case accessRestricted
    case eventNotFound(String)

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
