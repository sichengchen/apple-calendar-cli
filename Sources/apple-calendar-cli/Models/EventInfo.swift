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
    let recurrenceRules: [RecurrenceRuleInfo]?

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
        if event.hasRecurrenceRules, let rules = event.recurrenceRules {
            self.recurrenceRules = rules.map { RecurrenceRuleInfo(from: $0) }
        } else {
            self.recurrenceRules = nil
        }
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
        if hasRecurrenceRules, let rules = recurrenceRules, let first = rules.first {
            line += "  [recurring: \(first.frequency)"
            if first.interval > 1 {
                line += " every \(first.interval)"
            }
            line += "]"
        }
        line += "  (\(identifier))"
        return line
    }
}

struct RecurrenceRuleInfo: Codable {
    let frequency: String
    let interval: Int
    let endDate: String?
    let occurrenceCount: Int?

    init(from rule: EKRecurrenceRule) {
        self.frequency = Self.frequencyName(for: rule.frequency)
        self.interval = rule.interval
        if let end = rule.recurrenceEnd {
            if let date = end.endDate {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime]
                self.endDate = formatter.string(from: date)
                self.occurrenceCount = nil
            } else {
                self.endDate = nil
                self.occurrenceCount = end.occurrenceCount
            }
        } else {
            self.endDate = nil
            self.occurrenceCount = nil
        }
    }

    private static func frequencyName(for freq: EKRecurrenceFrequency) -> String {
        switch freq {
        case .daily: return "daily"
        case .weekly: return "weekly"
        case .monthly: return "monthly"
        case .yearly: return "yearly"
        @unknown default: return "unknown"
        }
    }
}
