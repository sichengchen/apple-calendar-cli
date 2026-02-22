import ArgumentParser
import Foundation

struct DeleteEventCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete-event",
        abstract: "Delete a calendar event by ID."
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
        try service.delete(event)

        if globalOptions.json {
            let result = DeleteResult(deleted: true, event: eventInfo)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(result)
            print(String(data: data, encoding: .utf8)!)
        } else {
            print("Deleted event: \(eventInfo.title) (\(eventInfo.identifier))")
        }
    }
}

private struct DeleteResult: Codable {
    let deleted: Bool
    let event: EventInfo
}
