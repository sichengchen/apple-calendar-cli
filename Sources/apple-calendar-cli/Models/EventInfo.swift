@preconcurrency import EventKit
import Foundation

struct EventInfo: Codable {
    let identifier: String
    let title: String
    let startDate: String
    let endDate: String
    let isAllDay: Bool
    let location: String?
    let notes: String?
    let calendarTitle: String
    let calendarIdentifier: String
    let url: String?
    let hasRecurrenceRules: Bool

    init(from event: EKEvent) {
        self.identifier = event.eventIdentifier
        self.title = event.title ?? "(No title)"
        self.startDate = Self.formatter.string(from: event.startDate)
        self.endDate = Self.formatter.string(from: event.endDate)
        self.isAllDay = event.isAllDay
        self.location = event.location
        self.notes = event.notes
        self.calendarTitle = event.calendar?.title ?? "Unknown"
        self.calendarIdentifier = event.calendar?.calendarIdentifier ?? ""
        self.url = event.url?.absoluteString
        self.hasRecurrenceRules = event.hasRecurrenceRules
    }

    private static nonisolated(unsafe) let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    func humanReadable() -> String {
        let dateDisplay: String
        if isAllDay {
            let start = String(startDate.prefix(10))
            let end = String(endDate.prefix(10))
            dateDisplay = start == end ? "\(start) (all day)" : "\(start) – \(end) (all day)"
        } else {
            dateDisplay = "\(startDate) – \(endDate)"
        }
        var line = "\(title)  \(dateDisplay)  [\(calendarTitle)]"
        if let location, !location.isEmpty {
            line += "  📍 \(location)"
        }
        line += "  (\(identifier))"
        return line
    }
}
