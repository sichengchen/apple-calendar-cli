import XCTest
@testable import apple_calendar_cli

final class InitCommandTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: directory)
    }

    func testHelpListsCommandsAndInitOptions() throws {
        let help = try runCLI(["help"])
        XCTAssertEqual(help.status, 0)
        let commands = ["init", "list-calendars", "list-events", "get-event", "create-event", "update-event", "delete-event"]
        for command in commands {
            XCTAssertTrue(help.output.contains(command))
        }
        let initHelp = try runCLI(["help", "init"])
        XCTAssertEqual(initHelp.status, 0)
        for flag in ["--agent", "--scope", "--dry-run", "--json"] {
            XCTAssertTrue(initHelp.output.contains(flag))
        }
        XCTAssertEqual(try runCLI(["help", "create-event"]).status, 0)
    }

    func testNonInteractiveInitRequiresExplicitAgent() throws {
        let result = try runCLI(["init", "--scope", "project"])
        XCTAssertNotEqual(result.status, 0)
        XCTAssertTrue(result.error.contains("--agent"))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), [])
    }

    func testCLIInstallsCanonicalEmbeddedSkillAndDoesNotDuplicateUpdates() throws {
        let arguments = ["init", "--scope", "project", "--agent", "codex", "--agent", "claude-code", "--json"]
        let first = try runCLI(arguments)
        XCTAssertEqual(first.status, 0, first.error)
        let results = try decodeResults(first.output)
        XCTAssertEqual(results.map { $0["action"] as? String }, ["installed", "installed"])
        let skill = directory.appendingPathComponent(".agents/skills/apple-calendar-cli/SKILL.md")
        let source = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("skills/apple-calendar-cli/SKILL.md")
        XCTAssertEqual(try Data(contentsOf: skill), try Data(contentsOf: source))
        let retry = try runCLI(arguments)
        XCTAssertEqual(retry.status, 0)
        XCTAssertEqual(try decodeResults(retry.output).map { $0["action"] as? String }, ["unchanged", "unchanged"])
    }

    func testDryRunJSONAndPartialFailure() throws {
        let arguments = ["init", "--scope", "project", "--agent", "codex", "--agent", "pi", "--json"]
        let preview = try runCLI(arguments + ["--dry-run"])
        XCTAssertEqual(preview.status, 0)
        let previewActions = try decodeResults(preview.output).map { $0["action"] as? String }
        XCTAssertEqual(previewActions, ["would-install", "would-install"])
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), [])

        let blocked = directory.appendingPathComponent(".pi/skills/apple-calendar-cli/SKILL.md")
        try FileManager.default.createDirectory(at: blocked, withIntermediateDirectories: true)
        let install = try runCLI(arguments)
        XCTAssertNotEqual(install.status, 0)
        let results = try decodeResults(install.output)
        XCTAssertEqual(results.map { $0["action"] as? String }, ["installed", "failed"])
        XCTAssertNotNil(results[1]["error"])
        let installed = directory.appendingPathComponent(".agents/skills/apple-calendar-cli/SKILL.md")
        XCTAssertTrue(FileManager.default.fileExists(atPath: installed.path))
    }

    private func runCLI(_ arguments: [String]) throws -> (status: Int32, output: String, error: String) {
        let executable = Bundle(for: Self.self).bundleURL.deletingLastPathComponent()
            .appendingPathComponent("apple-calendar-cli")
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.currentDirectoryURL = directory
        process.standardInput = FileHandle.nullDevice
        let output = Pipe()
        let error = Pipe()
        process.standardOutput = output
        process.standardError = error
        try process.run()
        process.waitUntilExit()
        return (
            process.terminationStatus,
            String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self),
            String(decoding: error.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        )
    }

    private func decodeResults(_ output: String) throws -> [[String: Any]] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: Data(output.utf8)) as? [[String: Any]])
    }
}
