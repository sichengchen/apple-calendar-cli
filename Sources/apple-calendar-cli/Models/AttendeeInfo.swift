@preconcurrency import EventKit
import Foundation

struct AttendeeInfo: Codable {
    let name: String?
    let email: String?
    let status: String
    let role: String

    init(from participant: EKParticipant) {
        self.name = participant.name
        self.email = participant.url.absoluteString
            .replacingOccurrences(of: "mailto:", with: "")
        self.status = Self.statusName(for: participant.participantStatus)
        self.role = Self.roleName(for: participant.participantRole)
    }

    private static func statusName(for status: EKParticipantStatus) -> String {
        switch status {
        case .unknown: return "unknown"
        case .pending: return "pending"
        case .accepted: return "accepted"
        case .declined: return "declined"
        case .tentative: return "tentative"
        case .delegated: return "delegated"
        case .completed: return "completed"
        case .inProcess: return "in-process"
        @unknown default: return "unknown"
        }
    }

    private static func roleName(for role: EKParticipantRole) -> String {
        switch role {
        case .unknown: return "unknown"
        case .required: return "required"
        case .optional: return "optional"
        case .chair: return "chair"
        case .nonParticipant: return "non-participant"
        @unknown default: return "unknown"
        }
    }

    func humanReadable() -> String {
        let displayName = name ?? email ?? "Unknown"
        return "\(displayName) (\(status), \(role))"
    }
}
