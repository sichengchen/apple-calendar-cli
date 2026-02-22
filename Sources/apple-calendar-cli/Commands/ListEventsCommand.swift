import ArgumentParser
@preconcurrency import EventKit
import Foundation

struct ListEventsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-events",
        abstract: "List events within a date range."
    )

    @OptionGroup var globalOptions: GlobalOptions

    @Option(name: .long, help: "Start date (YYYY-MM-DD or ISO 8601). Defaults to today.")
    var from: String?

    @Option(name: .long, help: "End date (YYYY-MM-DD or ISO 8601). Defaults to 7 days from now.")
    var to: String?

    @Option(name: .long, help: "Filter by calendar identifier.")
    var calendar: String?

    func run() async throws {
        let service = CalendarService()
        try await service.requestAccess()

        let now = Date()
        let startDate: Date
        let endDate: Date

        if let fromStr = from {
            guard let parsed = DateParser.parse(fromStr) else {
                throw ValidationError("Invalid --from date: '\(fromStr)'. Use YYYY-MM-DD or ISO 8601 format.")
            }
            startDate = parsed
        } else {
            startDate = Calendar.current.startOfDay(for: now)
        }

        if let toStr = to {
            guard let parsed = DateParser.parse(toStr) else {
                throw ValidationError("Invalid --to date: '\(toStr)'. Use YYYY-MM-DD or ISO 8601 format.")
            }
            endDate = parsed
        } else {
            endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        }

        var calendars: [EKCalendar]?
        if let calendarId = calendar {
            if let cal = service.calendar(withIdentifier: calendarId) {
                calendars = [cal]
            } else {
                throw ValidationError("Calendar not found with identifier: '\(calendarId)'.")
            }
        }

        let events = service.fetchEvents(from: startDate, to: endDate, in: calendars)
        let eventInfos = events.map { EventInfo(from: $0) }

        if globalOptions.json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(eventInfos)
            print(String(data: data, encoding: .utf8)!)
        } else {
            if eventInfos.isEmpty {
                print("No events found.")
            } else {
                for info in eventInfos {
                    print(info.humanReadable())
                }
            }
        }
    }
}
