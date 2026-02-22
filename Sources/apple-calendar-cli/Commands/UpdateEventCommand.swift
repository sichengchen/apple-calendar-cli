import ArgumentParser
@preconcurrency import EventKit
import Foundation

struct UpdateEventCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update-event",
        abstract: "Update an existing calendar event."
    )

    @OptionGroup var globalOptions: GlobalOptions

    @Argument(help: "The event identifier.")
    var id: String

    @Option(name: .long, help: "New event title.")
    var title: String?

    @Option(name: .long, help: "New start date/time (YYYY-MM-DD or ISO 8601).")
    var start: String?

    @Option(name: .long, help: "New end date/time (YYYY-MM-DD or ISO 8601).")
    var end: String?

    @Option(name: .long, help: "Move event to a different calendar (by identifier).")
    var calendar: String?

    @Option(name: .long, help: "New event notes.")
    var notes: String?

    @Option(name: .long, help: "New event location.")
    var location: String?

    @Option(name: .long, help: "New event URL.")
    var url: String?

    @Option(name: .long, help: "Span for recurring events: 'this' (this occurrence) or 'all' (all future). Default: this.")
    var span: String?

    @Option(name: .long, help: "Set recurrence: daily, weekly, monthly, yearly. Use 'none' to remove.")
    var recurrence: String?

    @Option(name: .long, help: "Recurrence interval (default: 1).")
    var interval: Int?

    @Option(name: .long, help: "End date for recurrence (YYYY-MM-DD or ISO 8601).")
    var recurrenceEnd: String?

    @Option(name: .long, help: "Number of occurrences for recurrence.")
    var recurrenceCount: Int?

    func run() async throws {
        let service = CalendarService()
        try await service.requestAccess()

        guard let event = service.event(withIdentifier: id) else {
            throw CalendarServiceError.eventNotFound(id)
        }

        if let title {
            event.title = title
        }

        if let startStr = start {
            guard let startDate = DateParser.parse(startStr) else {
                throw ValidationError("Invalid --start date: '\(startStr)'. Use YYYY-MM-DD or ISO 8601 format.")
            }
            event.startDate = startDate
        }

        if let endStr = end {
            guard let endDate = DateParser.parse(endStr) else {
                throw ValidationError("Invalid --end date: '\(endStr)'. Use YYYY-MM-DD or ISO 8601 format.")
            }
            event.endDate = endDate
        }

        if let calendarId = calendar {
            guard let cal = service.calendar(withIdentifier: calendarId) else {
                throw ValidationError("Calendar not found with identifier: '\(calendarId)'.")
            }
            event.calendar = cal
        }

        if let notes {
            event.notes = notes
        }

        if let location {
            event.location = location
        }

        if let urlStr = url {
            event.url = URL(string: urlStr)
        }

        if let recurrence {
            // Remove existing rules
            if let existingRules = event.recurrenceRules {
                for rule in existingRules {
                    event.removeRecurrenceRule(rule)
                }
            }
            if recurrence.lowercased() != "none" {
                guard let frequency = RecurrenceHelper.parseFrequency(recurrence) else {
                    throw ValidationError(
                        "Invalid --recurrence value: '\(recurrence)'. Use daily, weekly, monthly, yearly, or none."
                    )
                }
                let recurrenceEndValue = try RecurrenceHelper.parseEnd(
                    endDate: recurrenceEnd, count: recurrenceCount
                )
                let rule = EKRecurrenceRule(
                    recurrenceWith: frequency,
                    interval: interval ?? 1,
                    end: recurrenceEndValue
                )
                event.addRecurrenceRule(rule)
            }
        }

        if event.endDate <= event.startDate {
            throw ValidationError("End date must be after start date.")
        }

        let ekSpan: EKSpan
        if let span {
            switch span.lowercased() {
            case "this": ekSpan = .thisEvent
            case "all": ekSpan = .futureEvents
            default: throw ValidationError("Invalid --span value: '\(span)'. Use 'this' or 'all'.")
            }
        } else {
            ekSpan = .thisEvent
        }

        try service.save(event, span: ekSpan)

        let eventInfo = EventInfo(from: event)
        if globalOptions.json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(eventInfo)
            print(String(data: data, encoding: .utf8)!)
        } else {
            print("Event updated: \(eventInfo.humanReadable())")
        }
    }
}
