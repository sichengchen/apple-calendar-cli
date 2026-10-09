import ArgumentParser
import Darwin
import Foundation

enum AgentSelectionUI {
    static func select(targets: [SkillTarget], scope: SkillScope, dryRun: Bool) throws -> [SkillAgent]? {
        print("Apple Calendar agent setup")
        print(scope == .user ? "Install for this user across projects." : "Install in the current project.")
        print("Updates save a backup of your existing SKILL.md.\n")
        fflush(stdout)
        if ProcessInfo.processInfo.environment["TERM"] == "dumb" {
            return selectByNumber(targets: targets)
        }
        var original = termios()
        guard tcgetattr(STDIN_FILENO, &original) == 0 else {
            return selectByNumber(targets: targets)
        }
        var raw = original
        raw.c_lflag &= ~tcflag_t(ICANON | ECHO | ISIG)
        withUnsafeMutableBytes(of: &raw.c_cc) { bytes in
            bytes[Int(VMIN)] = 1
            bytes[Int(VTIME)] = 0
        }
        guard tcsetattr(STDIN_FILENO, TCSANOW, &raw) == 0 else {
            throw ValidationError("Cannot read terminal input. Use --agent to select an agent.")
        }
        defer { tcsetattr(STDIN_FILENO, TCSANOW, &original) }

        var selected = Set(targets.indices.filter { targets[$0].detected && targets[$0].state.selectable })
        var cursor = 0
        var rendered = false
        var message = "Detected agents are selected. You can select others too."
        while true {
            if rendered { output("\u{1b}[\(targets.count + 3)A\u{1b}[0J") }
            render(targets: targets, selected: selected, cursor: cursor, message: message, dryRun: dryRun)
            rendered = true
            switch readKey() {
            case .up: cursor = (cursor + targets.count - 1) % targets.count
            case .down: cursor = (cursor + 1) % targets.count
            case .toggle:
                if targets[cursor].state.selectable {
                    if !selected.insert(cursor).inserted { selected.remove(cursor) }
                } else if case .blocked(let reason) = targets[cursor].state {
                    message = reason
                }
            case .all:
                let available = Set(targets.indices.filter { targets[$0].state.selectable })
                selected = selected == available ? [] : available
            case .confirm:
                if !selected.isEmpty { return selected.sorted().map { targets[$0].agent } }
                message = "Select at least one agent with Space, or press Q to cancel."
            case .cancel: return nil
            case .other: break
            }
        }
    }

    private static func render(
        targets: [SkillTarget], selected: Set<Int>, cursor: Int, message: String, dryRun: Bool
    ) {
        var size = winsize()
        _ = ioctl(STDOUT_FILENO, TIOCGWINSZ, &size)
        let columns = size.ws_col > 0 ? Int(size.ws_col) : 80
        for (index, target) in targets.enumerated() {
            let mark = selected.contains(index) ? "x" : " "
            let detected = target.detected ? "detected" : "not detected"
            let line = "\(index == cursor ? ">" : " ") [\(mark)] \(target.agent.displayName)"
                + " — \(detected) — \(target.state.label)"
            output(String(line.prefix(max(1, columns - 1))) + "\n")
        }
        output("\n")
        let action = dryRun ? "preview" : "install"
        let controls = "Up/Down move  Space select  A all  Enter \(action)  Q cancel"
        output(String(controls.prefix(max(1, columns - 1))) + "\n")
        output(String(message.prefix(max(1, columns - 1))) + "\n")
    }

    private static func selectByNumber(targets: [SkillTarget]) -> [SkillAgent]? {
        for (index, target) in targets.enumerated() {
            print("\(index + 1). \(target.agent.displayName) — \(target.state.label) — \(target.file.path)")
        }
        while true {
            print("Select numbers separated by commas, 'all', or 'q' to cancel: ", terminator: "")
            fflush(stdout)
            guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
            if input.lowercased() == "q" { return nil }
            let choices: [Int]
            if input.lowercased() == "all" {
                choices = targets.indices.filter { targets[$0].state.selectable }
            } else {
                let parts = input.split(whereSeparator: { $0 == "," || $0.isWhitespace })
                let numbers = parts.compactMap { Int($0) }
                guard !numbers.isEmpty, numbers.count == parts.count,
                      numbers.allSatisfy({
                          $0 > 0 && $0 <= targets.count && targets[$0 - 1].state.selectable
                      }) else {
                    print("Choose one or more available agent numbers.")
                    continue
                }
                choices = numbers.map { $0 - 1 }
            }
            if !choices.isEmpty { return Set(choices).sorted().map { targets[$0].agent } }
            print("No agents are available. Press q to cancel.")
        }
    }

    private enum Key { case up, down, toggle, all, confirm, cancel, other }

    private static func readKey() -> Key {
        guard let byte = readByte() else { return .cancel }
        switch byte {
        case 3, 4, 113, 81: return .cancel
        case 10, 13: return .confirm
        case 32: return .toggle
        case 97, 65: return .all
        case 107: return .up
        case 106: return .down
        case 27:
            guard hasInput(), let prefix = readByte(), prefix == 91 || prefix == 79,
                  hasInput(), let direction = readByte() else { return .cancel }
            switch direction {
            case 65: return .up
            case 66: return .down
            default: return .other
            }
        default: return .other
        }
    }

    private static func readByte() -> UInt8? {
        var byte: UInt8 = 0
        while true {
            let count = Darwin.read(STDIN_FILENO, &byte, 1)
            if count == 1 { return byte }
            if count < 0 && errno == EINTR { continue }
            return nil
        }
    }

    private static func hasInput() -> Bool {
        var descriptor = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN), revents: 0)
        return poll(&descriptor, 1, 100) > 0
    }

    private static func output(_ text: String) {
        FileHandle.standardOutput.write(Data(text.utf8))
    }
}
