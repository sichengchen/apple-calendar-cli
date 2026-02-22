import ArgumentParser
@preconcurrency import EventKit
import Foundation

struct CreateEventCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create-event",
        abstract: "Create a new calendar event."
    )

    @OptionGroup var globalOptions: GlobalOptions

    @Option(name: .long, help: "Event title.")
    var title: String

    @Option(name: .long, help: "Start date/time (YYYY-MM-DD or ISO 8601).")
    var start: String

    @Option(name: .long, help: "End date/time (YYYY-MM-DD or ISO 8601).")
    var end: String

    @Option(name: .long, help: "Calendar identifier. Defaults to the default calendar.")
    var calendar: String?

    @Option(name: .long, help: "Event notes.")
    var notes: String?

    @Option(name: .long, help: "Event location.")
    var location: String?

    @Flag(name: .long, help: "Mark as an all-day event.")
    var allDay = false

    @Option(name: .long, help: "Event URL.")
    var url: String?

    @Option(name: .long, help: "Recurrence frequency: daily, weekly, monthly, yearly.")
    var recurrence: String?

    @Option(name: .long, help: "Recurrence interval (default: 1). E.g., 2 for every 2 weeks.")
    var interval: Int?

    @Option(name: .long, help: "End date for recurrence (YYYY-MM-DD or ISO 8601).")
    var recurrenceEnd: String?

    @Option(name: .long, help: "Number of occurrences for recurrence.")
    var recurrenceCount: Int?

    func run() async throws {
        let service = CalendarService()
        try await service.requestAccess()

        guard let startDate = DateParser.parse(start) else {
            throw ValidationError("Invalid --start date: '\(start)'. Use YYYY-MM-DD or ISO 8601 format.")
        }

        guard let endDate = DateParser.parse(end) else {
            throw ValidationError("Invalid --end date: '\(end)'. Use YYYY-MM-DD or ISO 8601 format.")
        }

        guard endDate > startDate else {
            throw ValidationError("End date must be after start date.")
        }

        let targetCalendar: EKCalendar
        if let calendarId = calendar {
            guard let cal = service.calendar(withIdentifier: calendarId) else {
                throw ValidationError("Calendar not found with identifier: '\(calendarId)'.")
            }
            targetCalendar = cal
        } else {
            guard let cal = service.defaultCalendar() else {
                throw ValidationError("No default calendar available.")
            }
            targetCalendar = cal
        }

        let event = service.newEvent()
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = targetCalendar
        event.isAllDay = allDay
        event.notes = notes
        event.location = location
        if let urlStr = url, let eventURL = URL(string: urlStr) {
            event.url = eventURL
        }

        if let recurrence {
            guard let frequency = RecurrenceHelper.parseFrequency(recurrence) else {
                throw ValidationError(
                    "Invalid --recurrence value: '\(recurrence)'. Use daily, weekly, monthly, or yearly."
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

        try service.save(event)

        let eventInfo = EventInfo(from: event)
        if globalOptions.json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(eventInfo)
            print(String(data: data, encoding: .utf8)!)
        } else {
            print("Event created: \(eventInfo.humanReadable())")
        }
    }
}
