import Foundation

enum BundledAgentSkill {
    static func load() throws -> Data {
        guard let data = Data(base64Encoded: EmbeddedAgentSkill.base64), !data.isEmpty else {
            throw SkillInstallerError.missingSkill
        }
        guard let text = String(data: data, encoding: .utf8), text.hasPrefix("---\n") else {
            throw SkillInstallerError.missingSkill
        }
        return data
    }
}

enum SkillInstallerError: LocalizedError {
    case missingSkill
    case blocked(String)

    var errorDescription: String? {
        switch self {
        case .missingSkill:
            return "The bundled agent skill is missing or invalid. Reinstall apple-calendar-cli."
        case .blocked(let reason): return reason
        }
    }
}

struct SkillInstaller {
    let skill: Data
    let home: URL
    let currentDirectory: URL
    let environment: [String: String]
    private let fileManager = FileManager.default

    init(
        skill: Data,
        home: URL = FileManager.default.homeDirectoryForCurrentUser,
        currentDirectory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        self.skill = skill
        self.home = home
        self.currentDirectory = currentDirectory
        self.environment = environment
    }

    func target(for agent: SkillAgent, scope: SkillScope) -> SkillTarget {
        let root: URL
        if scope == .project {
            root = currentDirectory.appendingPathComponent(agent.projectSkillsPath)
        } else if agent == .codex {
            root = home.appendingPathComponent(".agents/skills")
        } else {
            root = configurationDirectory(for: agent).appendingPathComponent("skills")
        }
        let file = root.appendingPathComponent("apple-calendar-cli/SKILL.md")
        return SkillTarget(agent: agent, file: file, detected: isDetected(agent), state: state(at: file))
    }

    func install(for agent: SkillAgent, scope: SkillScope, dryRun: Bool = false) throws -> SkillInstallResult {
        let target = target(for: agent, scope: scope)
        var result = SkillInstallResult(agent: agent, path: target.file.path, action: "unchanged")
        switch target.state {
        case .current: return result
        case .blocked(let reason): throw SkillInstallerError.blocked(reason)
        case .install, .update: break
        }
        let updating = target.state == .update
        if dryRun {
            return SkillInstallResult(
                agent: agent, path: target.file.path, action: updating ? "would-update" : "would-install"
            )
        }
        try fileManager.createDirectory(at: target.file.deletingLastPathComponent(), withIntermediateDirectories: true)
        if updating {
            let backup = target.file.deletingLastPathComponent()
                .appendingPathComponent("SKILL.md.\(UUID().uuidString).bak")
            try fileManager.copyItem(at: target.file, to: backup)
            result.backup = backup.path
        }
        try skill.write(to: target.file, options: .atomic)
        return SkillInstallResult(
            agent: agent, path: target.file.path, action: updating ? "updated" : "installed", backup: result.backup
        )
    }

    private func state(at file: URL) -> SkillInstallState {
        let directory = file.deletingLastPathComponent()
        for path in [directory, file] {
            if (try? fileManager.destinationOfSymbolicLink(atPath: path.path)) != nil {
                return .blocked("\(path.path) is a symlink. Update its source rather than replacing the link.")
            }
        }
        if fileManager.fileExists(atPath: directory.path) {
            var isDirectory: ObjCBool = false
            _ = fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory)
            if !isDirectory.boolValue {
                return .blocked("\(directory.path) is not a directory.")
            }
        }
        guard fileManager.fileExists(atPath: file.path) else { return .install }
        do {
            let attributes = try fileManager.attributesOfItem(atPath: file.path)
            guard attributes[.type] as? FileAttributeType == .typeRegular else {
                return .blocked("\(file.path) is not a regular file.")
            }
            return try Data(contentsOf: file) == skill ? .current : .update
        } catch {
            return .blocked("Cannot read \(file.path): \(error.localizedDescription)")
        }
    }

    private func configurationDirectory(for agent: SkillAgent) -> URL {
        switch agent {
        case .codex: return configuredPath("CODEX_HOME", fallback: ".codex")
        case .claude: return configuredPath("CLAUDE_CONFIG_DIR", fallback: ".claude")
        case .pi: return configuredPath("PI_CODING_AGENT_DIR", fallback: ".pi/agent")
        case .antigravity: return home.appendingPathComponent(".gemini/antigravity-cli")
        case .antigravityIDE: return home.appendingPathComponent(".gemini/config")
        case .opencode:
            return configuredPath("XDG_CONFIG_HOME", fallback: ".config").appendingPathComponent("opencode")
        }
    }

    private func configuredPath(_ key: String, fallback: String) -> URL {
        guard let value = environment[key], !value.isEmpty else {
            return home.appendingPathComponent(fallback)
        }
        if value == "~" { return home }
        if value.hasPrefix("~/") { return home.appendingPathComponent(String(value.dropFirst(2))) }
        return URL(fileURLWithPath: value, relativeTo: currentDirectory).standardizedFileURL
    }

    private func isDetected(_ agent: SkillAgent) -> Bool {
        if fileManager.fileExists(atPath: configurationDirectory(for: agent).path) { return true }
        let paths = (environment["PATH"] ?? "").split(separator: ":", omittingEmptySubsequences: false)
        if paths.contains(where: { path in
            let directory = path.isEmpty ? currentDirectory : URL(fileURLWithPath: String(path))
            return fileManager.isExecutableFile(atPath: directory.appendingPathComponent(agent.executable).path)
        }) { return true }
        if agent == .antigravityIDE {
            return fileManager.fileExists(atPath: "/Applications/Antigravity.app")
                || fileManager.fileExists(atPath: home.appendingPathComponent("Applications/Antigravity.app").path)
                || fileManager.fileExists(atPath: home.appendingPathComponent(".gemini/antigravity").path)
        }
        return false
    }
}
