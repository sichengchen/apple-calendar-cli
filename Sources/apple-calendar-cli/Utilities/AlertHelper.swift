import Foundation

enum AlertHelper {
    /// Parse an alert offset string like "15m", "1h", "1d", "30s" into a negative TimeInterval (seconds before event).
    static func parseOffset(_ string: String) -> TimeInterval? {
        let trimmed = string.trimmingCharacters(in: .whitespaces).lowercased()
        guard trimmed.count >= 2 else { return nil }

        let suffix = trimmed.last!
        let numberStr = String(trimmed.dropLast())
        guard let number = Double(numberStr), number >= 0 else { return nil }

        let seconds: TimeInterval
        switch suffix {
        case "s": seconds = number
        case "m": seconds = number * 60
        case "h": seconds = number * 3600
        case "d": seconds = number * 86400
        case "w": seconds = number * 604_800
        default: return nil
        }

        // Negative offset = before the event
        return -seconds
    }
}
