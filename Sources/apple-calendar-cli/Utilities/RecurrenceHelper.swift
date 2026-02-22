import ArgumentParser
@preconcurrency import EventKit
import Foundation

enum RecurrenceHelper {
    static func parseFrequency(_ string: String) -> EKRecurrenceFrequency? {
        switch string.lowercased() {
        case "daily": return .daily
        case "weekly": return .weekly
        case "monthly": return .monthly
        case "yearly": return .yearly
        default: return nil
        }
    }

    static func parseEnd(endDate: String?, count: Int?) throws -> EKRecurrenceEnd? {
        if let endDate {
            guard let date = DateParser.parse(endDate) else {
                throw ValidationError(
                    "Invalid --recurrence-end date: '\(endDate)'. Use YYYY-MM-DD or ISO 8601 format."
                )
            }
            return EKRecurrenceEnd(end: date)
        }
        if let count {
            return EKRecurrenceEnd(occurrenceCount: count)
        }
        return nil
    }
}
