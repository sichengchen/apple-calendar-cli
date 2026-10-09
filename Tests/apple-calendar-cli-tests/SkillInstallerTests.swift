import XCTest
@testable import apple_calendar_cli

final class SkillInstallerTests: XCTestCase {
    private let skill = Data("---\nname: apple-calendar-cli\ndescription: Calendar operations.\n---\n".utf8)
    private var temporaryDirectory: URL!
    private var installer: SkillInstaller!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        installer = SkillInstaller(
            skill: skill,
            home: temporaryDirectory.appendingPathComponent("home"),
            currentDirectory: temporaryDirectory.appendingPathComponent("project"),
            environment: ["PATH": ""]
        )
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: temporaryDirectory)
    }

    func testInstallsOnlySelectedAgentAndIsIdempotent() throws {
        let result = try installer.install(for: .claude, scope: .user)
        XCTAssertEqual(result.action, "installed")
        XCTAssertEqual(try Data(contentsOf: URL(fileURLWithPath: result.path)), skill)
        XCTAssertFalse(FileManager.default.fileExists(atPath: installer.target(for: .pi, scope: .user).file.path))
        let retry = try installer.install(for: .claude, scope: .user)
        XCTAssertEqual(retry.action, "unchanged")
        XCTAssertNil(retry.backup)
        let files = try FileManager.default.contentsOfDirectory(
            atPath: URL(fileURLWithPath: result.path).deletingLastPathComponent().path
        )
        XCTAssertEqual(files, ["SKILL.md"])
    }

    func testUpdateKeepsBackupAndOtherFiles() throws {
        let target = installer.target(for: .pi, scope: .user)
        let directory = target.file.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let previous = Data("Locally customized skill".utf8)
        try previous.write(to: target.file)
        let support = directory.appendingPathComponent("notes.txt")
        try Data("Keep this file".utf8).write(to: support)

        let result = try installer.install(for: .pi, scope: .user)
        XCTAssertEqual(result.action, "updated")
        let backup = try XCTUnwrap(result.backup)
        XCTAssertEqual(try Data(contentsOf: URL(fileURLWithPath: backup)), previous)
        XCTAssertEqual(try Data(contentsOf: target.file), skill)
        XCTAssertEqual(try String(contentsOf: support, encoding: .utf8), "Keep this file")
    }

    func testDryRunDoesNotCreateDirectoriesOrBackups() throws {
        let result = try installer.install(for: .codex, scope: .project, dryRun: true)
        XCTAssertEqual(result.action, "would-install")
        XCTAssertFalse(FileManager.default.fileExists(atPath: result.path))
        let project = temporaryDirectory.appendingPathComponent("project")
        XCTAssertFalse(FileManager.default.fileExists(atPath: project.path))

        let file = installer.target(for: .claude, scope: .user).file
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("older skill".utf8).write(to: file)
        XCTAssertEqual(try installer.install(for: .claude, scope: .user, dryRun: true).action, "would-update")
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "older skill")
        let files = try FileManager.default.contentsOfDirectory(atPath: file.deletingLastPathComponent().path)
        XCTAssertEqual(files, ["SKILL.md"])
    }

    func testProjectScopeAndSharedTargets() throws {
        let result = try installer.install(for: .codex, scope: .project)
        XCTAssertTrue(result.path.hasSuffix("project/.agents/skills/apple-calendar-cli/SKILL.md"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: temporaryDirectory.appendingPathComponent("home").path))
        XCTAssertEqual(try installer.install(for: .antigravity, scope: .project).action, "unchanged")
        XCTAssertEqual(try installer.install(for: .antigravityIDE, scope: .project).action, "unchanged")
    }

    func testConfiguredAgentDirectories() {
        let configured = SkillInstaller(
            skill: skill, home: temporaryDirectory, currentDirectory: temporaryDirectory,
            environment: [
                "CLAUDE_CONFIG_DIR": "~/custom-claude",
                "PI_CODING_AGENT_DIR": temporaryDirectory.appendingPathComponent("custom-pi").path,
                "XDG_CONFIG_HOME": temporaryDirectory.appendingPathComponent("custom-config").path,
            ]
        )
        let claude = configured.target(for: .claude, scope: .user).file.path
        let pi = configured.target(for: .pi, scope: .user).file.path
        let opencode = configured.target(for: .opencode, scope: .user).file.path
        XCTAssertTrue(claude.hasSuffix("custom-claude/skills/apple-calendar-cli/SKILL.md"))
        XCTAssertTrue(pi.hasSuffix("custom-pi/skills/apple-calendar-cli/SKILL.md"))
        XCTAssertTrue(opencode.hasSuffix("custom-config/opencode/skills/apple-calendar-cli/SKILL.md"))
    }

    func testDetectsAgentExecutableOrConfigurationWithoutRunningIt() throws {
        let bin = temporaryDirectory.appendingPathComponent("bin")
        try FileManager.default.createDirectory(at: bin, withIntermediateDirectories: true)
        let executable = bin.appendingPathComponent("pi")
        try Data("#!/bin/sh\nexit 1\n".utf8).write(to: executable)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)
        let configured = SkillInstaller(
            skill: skill, home: temporaryDirectory,
            currentDirectory: temporaryDirectory, environment: ["PATH": bin.path]
        )
        XCTAssertTrue(configured.target(for: .pi, scope: .user).detected)
        XCTAssertFalse(configured.target(for: .codex, scope: .user).detected)
        let config = temporaryDirectory.appendingPathComponent(".codex")
        try FileManager.default.createDirectory(at: config, withIntermediateDirectories: true)
        XCTAssertTrue(configured.target(for: .codex, scope: .user).detected)
    }

    func testAntigravityCLIAndIDEUseDifferentGlobalDirectories() {
        let cli = installer.target(for: .antigravity, scope: .user)
        let ide = installer.target(for: .antigravityIDE, scope: .user)
        XCTAssertTrue(cli.file.path.hasSuffix(".gemini/antigravity-cli/skills/apple-calendar-cli/SKILL.md"))
        XCTAssertTrue(ide.file.path.hasSuffix(".gemini/config/skills/apple-calendar-cli/SKILL.md"))
        XCTAssertNotEqual(cli.file, ide.file)
    }

    func testDoesNotReplaceLinkedSkillFolder() throws {
        let file = installer.target(for: .claude, scope: .user).file
        let source = temporaryDirectory.appendingPathComponent("linked-source")
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        let original = source.appendingPathComponent("SKILL.md")
        try Data("shared skill".utf8).write(to: original)
        let root = file.deletingLastPathComponent().deletingLastPathComponent()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: file.deletingLastPathComponent(), withDestinationURL: source)
        XCTAssertThrowsError(try installer.install(for: .claude, scope: .user))
        XCTAssertEqual(try String(contentsOf: original, encoding: .utf8), "shared skill")
    }

    func testDoesNotReplaceLinkedSkillFileOrDirectoryInPlaceOfFile() throws {
        let file = installer.target(for: .pi, scope: .user).file
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        let source = temporaryDirectory.appendingPathComponent("shared.md")
        try Data("shared skill".utf8).write(to: source)
        try FileManager.default.createSymbolicLink(at: file, withDestinationURL: source)
        XCTAssertThrowsError(try installer.install(for: .pi, scope: .user))
        XCTAssertEqual(try String(contentsOf: source, encoding: .utf8), "shared skill")
        try FileManager.default.removeItem(at: file)
        try FileManager.default.createDirectory(at: file, withIntermediateDirectories: false)
        XCTAssertThrowsError(try installer.install(for: .pi, scope: .user))
    }

    func testRejectsNonDirectorySkillDestination() throws {
        let directory = installer.target(for: .opencode, scope: .user).file.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try Data("Not a folder".utf8).write(to: directory)
        XCTAssertThrowsError(try installer.install(for: .opencode, scope: .user))
        XCTAssertEqual(try String(contentsOf: directory, encoding: .utf8), "Not a folder")
    }
}
