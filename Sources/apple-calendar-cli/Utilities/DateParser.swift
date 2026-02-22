import Foundation

enum DateParser {
    /// Parse a date string in ISO 8601 format.
    /// Supports: "YYYY-MM-DD", "YYYY-MM-DDTHH:MM:SS", "YYYY-MM-DDTHH:MM:SSZ", full ISO 8601
    static func parse(_ string: String) -> Date? {
        // Try full ISO 8601 first
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: string) {
            return date
        }

        // Try ISO 8601 with seconds but no timezone (assume local)
        isoFormatter.formatOptions = [.withFullDate, .withFullTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        if let date = isoFormatter.date(from: string) {
            return date
        }

        // Try date-only format "YYYY-MM-DD" (assume start of day in local timezone)
        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
        dateOnlyFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateOnlyFormatter.timeZone = TimeZone.current
        if let date = dateOnlyFormatter.date(from: string) {
            return date
        }

        // Try "YYYY-MM-DDTHH:mm:ss" without timezone
        let localDateTimeFormatter = DateFormatter()
        localDateTimeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        localDateTimeFormatter.locale = Locale(identifier: "en_US_POSIX")
        localDateTimeFormatter.timeZone = TimeZone.current
        if let date = localDateTimeFormatter.date(from: string) {
            return date
        }

        // Try "YYYY-MM-DDTHH:mm"
        let shortFormatter = DateFormatter()
        shortFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        shortFormatter.locale = Locale(identifier: "en_US_POSIX")
        shortFormatter.timeZone = TimeZone.current
        if let date = shortFormatter.date(from: string) {
            return date
        }

        return nil
    }
}
