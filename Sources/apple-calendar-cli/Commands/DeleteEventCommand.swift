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

    @Option(
        name: .long,
        help: "Recurring events: 'this' occurrence, 'future' (this and later) or 'all' (whole series). Default: this."
    )
    var span: String?

    @Option(
        name: .long,
        help: "Recurring events: which occurrence, by its occurrenceDate from list-events (YYYY-MM-DD or ISO 8601)."
    )
    var occurrence: String?

    func run() async throws {
        let eventSpan = try EventSpan.parse(span)
        let occurrenceDate = try OccurrenceResolver.parseOccurrence(occurrence)
        try OccurrenceResolver.validate(span: eventSpan, occurrenceGiven: occurrenceDate != nil)

        let service = CalendarService()
        try await service.requestAccess()

        let event = try service.targetEvent(identifier: id, occurrence: occurrenceDate, span: eventSpan)

        let eventInfo = EventInfo(from: event)
        try service.delete(event, span: eventSpan.ekSpan)

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
