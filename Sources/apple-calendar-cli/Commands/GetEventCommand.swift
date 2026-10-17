import ArgumentParser
import Foundation

struct GetEventCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get-event",
        abstract: "Get details of a specific event by ID."
    )

    @OptionGroup var globalOptions: GlobalOptions

    @Argument(help: "The event identifier.")
    var id: String

    @Option(
        name: .long,
        help: "Recurring events: which occurrence, by its occurrenceDate from list-events. Default: the first."
    )
    var occurrence: String?

    func run() async throws {
        let occurrenceDate = try OccurrenceResolver.parseOccurrence(occurrence)

        let service = CalendarService()
        try await service.requestAccess()

        // Reading is harmless, so without --occurrence a recurring event resolves to its first occurrence.
        let event = try service.targetEvent(
            identifier: id,
            occurrence: occurrenceDate,
            span: occurrenceDate == nil ? .all : .this
        )

        let eventInfo = EventInfo(from: event)

        if globalOptions.json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(eventInfo)
            print(String(data: data, encoding: .utf8)!)
        } else {
            print(eventInfo.humanReadable())
        }
    }
}
