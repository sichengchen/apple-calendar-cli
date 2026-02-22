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

    func run() async throws {
        let service = CalendarService()
        try await service.requestAccess()

        guard let event = service.event(withIdentifier: id) else {
            throw CalendarServiceError.eventNotFound(id)
        }

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
