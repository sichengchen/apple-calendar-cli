import ArgumentParser
import Foundation

struct ListCalendarsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-calendars",
        abstract: "List all available calendars."
    )

    @OptionGroup var globalOptions: GlobalOptions

    func run() async throws {
        let service = CalendarService()
        try await service.requestAccess()

        let calendars = service.listCalendars()
        let calendarInfos = calendars.map { CalendarInfo(from: $0) }

        if globalOptions.json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(calendarInfos)
            print(String(data: data, encoding: .utf8)!)
        } else {
            if calendarInfos.isEmpty {
                print("No calendars found.")
            } else {
                for info in calendarInfos {
                    print(info.humanReadable())
                }
            }
        }
    }
}
