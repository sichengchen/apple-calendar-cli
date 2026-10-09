import ArgumentParser
import Foundation

enum SkillAgent: String, CaseIterable, ExpressibleByArgument, Codable {
    case codex
    case claude
    case pi
    case antigravity
    case antigravityIDE = "antigravity-ide"
    case opencode

    init?(argument: String) {
        self.init(rawValue: argument == "claude-code" ? "claude" : argument)
    }

    var displayName: String {
        switch self {
        case .codex: return "Codex"
        case .claude: return "Claude Code"
        case .pi: return "Pi"
        case .antigravity: return "Antigravity CLI"
        case .antigravityIDE: return "Antigravity IDE"
        case .opencode: return "OpenCode"
        }
    }

    var executable: String {
        switch self {
        case .antigravity: return "agy"
        case .antigravityIDE: return "antigravity"
        default: return rawValue
        }
    }

    var projectSkillsPath: String {
        switch self {
        case .codex, .antigravity, .antigravityIDE: return ".agents/skills"
        case .claude: return ".claude/skills"
        case .pi: return ".pi/skills"
        case .opencode: return ".opencode/skills"
        }
    }
}

enum SkillScope: String, ExpressibleByArgument {
    case user
    case project
}

enum SkillInstallState: Equatable {
    case install
    case update
    case current
    case blocked(String)

    var label: String {
        switch self {
        case .install: return "Install"
        case .update: return "Update"
        case .current: return "Up to date"
        case .blocked: return "Unavailable"
        }
    }

    var selectable: Bool {
        if case .blocked = self { return false }
        return true
    }
}

struct SkillTarget {
    let agent: SkillAgent
    let file: URL
    let detected: Bool
    let state: SkillInstallState
}

struct SkillInstallResult: Encodable {
    let agent: SkillAgent
    let path: String
    let action: String
    var backup: String?
    var error: String?
}
