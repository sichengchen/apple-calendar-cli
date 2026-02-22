import ArgumentParser

struct GlobalOptions: ParsableArguments {
    @Flag(name: .long, help: "Output results as JSON.")
    var json = false
}

@main
struct AppleCalendarCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "apple-calendar-cli",
        abstract: "A command-line tool for Apple Calendar operations via EventKit.",
        version: "0.1.0",
        subcommands: []
    )
}
