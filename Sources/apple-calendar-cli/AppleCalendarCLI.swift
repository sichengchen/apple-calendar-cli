import ArgumentParser

struct GlobalOptions: ParsableArguments {
    @Flag(name: .long, help: "Output results as JSON.")
    var json = false
}

@main
struct AppleCalendarCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "apple-calendar-cli",
        abstract: "A command-line tool for Apple Calendar operations via EventKit.",
        version: "0.1.0",
        subcommands: [
            ListCalendarsCommand.self,
            ListEventsCommand.self,
            GetEventCommand.self,
            CreateEventCommand.self,
            UpdateEventCommand.self,
            DeleteEventCommand.self,
        ]
    )
}
