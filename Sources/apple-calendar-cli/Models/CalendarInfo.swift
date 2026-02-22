import EventKit
import Foundation

struct CalendarInfo: Codable {
    let identifier: String
    let title: String
    let type: String
    let source: String
    let color: String
    let isImmutable: Bool

    init(from calendar: EKCalendar) {
        self.identifier = calendar.calendarIdentifier
        self.title = calendar.title
        self.type = Self.typeName(for: calendar.type)
        self.source = calendar.source?.title ?? "Unknown"
        self.color = calendar.cgColor.flatMap { Self.hexString(from: $0) } ?? "#000000"
        self.isImmutable = calendar.isImmutable
    }

    private static func typeName(for type: EKCalendarType) -> String {
        switch type {
        case .local: return "local"
        case .calDAV: return "calDAV"
        case .exchange: return "exchange"
        case .subscription: return "subscription"
        case .birthday: return "birthday"
        @unknown default: return "unknown"
        }
    }

    private static func hexString(from cgColor: CGColor) -> String? {
        guard let components = cgColor.components, components.count >= 3 else {
            return nil
        }
        let red = Int(components[0] * 255)
        let green = Int(components[1] * 255)
        let blue = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", red, green, blue)
    }

    func humanReadable() -> String {
        "\(title) [\(type)] (\(identifier))"
    }
}
