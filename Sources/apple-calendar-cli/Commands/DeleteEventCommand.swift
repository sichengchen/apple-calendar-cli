import ArgumentParser
@preconcurrency import EventKit
import Foundation

struct DeleteEventCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete-event",
        abstract: "Delete a calendar event by ID."
    )

    @OptionGroup var globalOptions: GlobalOptions

    @Argument(help: "The event identifier.")
    var id: String

    @Option(name: .long, help: "Span for recurring events: 'this' (this occurrence) or 'all' (all future). Default: this.")
    var span: String?

    func run() async throws {
        let service = CalendarService()
        try await service.requestAccess()

        guard let event = service.event(withIdentifier: id) else {
            throw CalendarServiceError.eventNotFound(id)
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

        let eventInfo = EventInfo(from: event)
        try service.delete(event, span: ekSpan)

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
