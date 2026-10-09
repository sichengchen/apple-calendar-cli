import ArgumentParser
import Darwin
import Foundation

struct InitCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Install or update the Apple Calendar skill for your agents."
    )

    @OptionGroup var globalOptions: GlobalOptions

    @Option(name: .customLong("agent"), help: "Agent to install for. Repeat to select multiple agents.")
    var agents: [SkillAgent] = []

    @Option(name: .long, help: "Install for this user or the current project.")
    var scope: SkillScope = .user

    @Flag(name: .long, help: "Preview installation without writing files.")
    var dryRun = false

    func run() throws {
        let installer = SkillInstaller(skill: try BundledAgentSkill.load())
        let selected: [SkillAgent]
        if agents.isEmpty {
            guard !globalOptions.json, isatty(STDIN_FILENO) == 1, isatty(STDOUT_FILENO) == 1 else {
                throw ValidationError("Select an agent with --agent, or run init in an interactive terminal.")
            }
            let targets = SkillAgent.allCases.map { installer.target(for: $0, scope: scope) }
            guard let choices = try AgentSelectionUI.select(targets: targets, scope: scope, dryRun: dryRun) else {
                print("Cancelled. No skills changed.")
                return
            }
            selected = choices
        } else {
            selected = SkillAgent.allCases.filter { agents.contains($0) }
        }

        let results = selected.map { agent in
            do {
                return try installer.install(for: agent, scope: scope, dryRun: dryRun)
            } catch {
                return SkillInstallResult(
                    agent: agent, path: installer.target(for: agent, scope: scope).file.path,
                    action: "failed", error: error.localizedDescription
                )
            }
        }
        if globalOptions.json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            print(String(decoding: try encoder.encode(results), as: UTF8.self))
        } else {
            for result in results {
                let action: String
                switch result.action {
                case "installed": action = "Installed"
                case "updated": action = "Updated"
                case "unchanged": action = "Up to date"
                case "would-install": action = "Would install"
                case "would-update": action = "Would update"
                default: action = "Failed"
                }
                print("\(action): \(result.agent.displayName) — \(result.path)")
                if let backup = result.backup { print("  Previous skill saved to \(backup)") }
                if let error = result.error { print("  \(error)") }
            }
            if !dryRun, results.contains(where: { $0.action == "installed" || $0.action == "updated" }) {
                print("Reload skills or start a new session in your selected agents.")
            }
        }
        if results.contains(where: { $0.action == "failed" }) { throw ExitCode.failure }
    }
}
