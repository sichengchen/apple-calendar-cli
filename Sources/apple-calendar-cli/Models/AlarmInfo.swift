@preconcurrency import EventKit
import Foundation

struct AlarmInfo: Codable {
    let relativeOffset: Double
    let offsetDescription: String

    init(from alarm: EKAlarm) {
        self.relativeOffset = alarm.relativeOffset
        self.offsetDescription = Self.formatOffset(alarm.relativeOffset)
    }

    private static func formatOffset(_ offset: TimeInterval) -> String {
        let absOffset = abs(offset)
        let minutes = Int(absOffset / 60)
        let prefix = offset < 0 ? "" : "+"

        if minutes == 0 { return "at time of event" }
        if minutes < 60 { return "\(prefix)\(minutes)m before" }

        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if remainingMinutes == 0 {
            return "\(hours)h before"
        }
        return "\(hours)h \(remainingMinutes)m before"
    }

    func humanReadable() -> String {
        offsetDescription
    }
}
