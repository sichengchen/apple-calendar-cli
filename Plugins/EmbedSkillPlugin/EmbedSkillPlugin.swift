import Foundation
import PackagePlugin

@main
struct EmbedSkillPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        let skill = context.package.directoryURL.appendingPathComponent("skills/apple-calendar-cli/SKILL.md")
        let plist = context.package.directoryURL.appendingPathComponent("Info.plist")
        let output = context.pluginWorkDirectoryURL.appendingPathComponent("EmbeddedAgentSkill.swift")
        return [
            .buildCommand(
                displayName: "Embed Apple Calendar agent skill",
                executable: try context.tool(named: "EmbedSkill").url,
                arguments: [skill.path, plist.path, output.path],
                inputFiles: [skill, plist],
                outputFiles: [output]
            ),
        ]
    }
}
