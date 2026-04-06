//
//  Date+Helpers.swift
//  CICompanion
//
//  Reusable date-formatting and week-calculation helpers.
//  Extracted from individual views so every screen shares the same logic.
//

import Foundation

extension Date {

    // MARK: - Week Calculations

    /// Returns the Monday–Friday dates for the week that contains this date.
    ///
    /// Sunday is treated as belonging to the *previous* week so the result
    /// always reflects a business-week row starting on Monday.
    func weekdayDates() -> [Date] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: self)
        // `.weekday` 1 = Sunday, 2 = Monday.  We want offset to Monday.
        let mondayOffset = (weekday == 1) ? -6 : (2 - weekday)
        guard let monday = calendar.date(byAdding: .day, value: mondayOffset, to: self) else {
            return []
        }
        return (0..<5).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    // MARK: - Month Calculations

    /// Returns a grid of dates for the month that contains this date,
    /// padded with leading/trailing days so each row starts on Sunday.
    ///
    /// The result is always a multiple of 7, suitable for a 7-column grid.
    func monthGridDates() -> [Date] {
        let calendar = Calendar.current

        guard let range = calendar.range(of: .day, in: .month, for: self),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: self))
        else { return [] }

        // Weekday of the 1st (1 = Sunday … 7 = Saturday)
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingBlanks = firstWeekday - 1          // days from previous month

        // Build leading dates from previous month
        var dates: [Date] = (0..<leadingBlanks).compactMap {
            calendar.date(byAdding: .day, value: $0 - leadingBlanks, to: firstOfMonth)
        }

        // Days of the actual month
        dates += range.compactMap {
            calendar.date(byAdding: .day, value: $0 - 1, to: firstOfMonth)
        }

        // Trailing dates to fill the last row
        let trailingCount = (7 - dates.count % 7) % 7
        if let lastDate = dates.last {
            dates += (1...max(trailingCount, 0)).compactMap {
                calendar.date(byAdding: .day, value: $0, to: lastDate)
            }
        }

        return dates
    }

    /// The first day of this date's month.
    var startOfMonth: Date {
        Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: self)
        ) ?? self
    }

    /// Whether this date falls in the same month and year as `other`.
    func isSameMonth(as other: Date) -> Bool {
        let cal = Calendar.current
        return cal.component(.month, from: self) == cal.component(.month, from: other)
            && cal.component(.year, from: self)  == cal.component(.year, from: other)
    }

    /// "April 2026" — used in the month view header.
    var monthYearLabel: String {
        Self.monthYearFormatter.string(from: self)
    }

    // MARK: - Short / Full Day Names

    /// Three-letter day abbreviation (e.g. "Mon", "Tue").
    var shortDayName: String {
        Self.shortDayFormatter.string(from: self)
    }

    /// Full weekday name (e.g. "Monday", "Tuesday").
    var fullDayName: String {
        Self.fullDayFormatter.string(from: self)
    }

    // MARK: - Display Formatting

    /// Formats the date as "March 18th, 2026" with an ordinal day suffix.
    var formattedWithOrdinal: String {
        let month = Self.monthFormatter.string(from: self)
        let day = Calendar.current.component(.day, from: self)
        let year = Self.yearFormatter.string(from: self)
        return "\(month) \(day)\(day.ordinalSuffix), \(year)"
    }

    /// Formats as "Tuesday, 18th Mar" — used in the new-assignment sheet.
    var shortOrdinalDisplay: String {
        let base = Self.weekdayDayFormatter.string(from: self)
        let day = Calendar.current.component(.day, from: self)
        let month = Self.shortMonthFormatter.string(from: self)
        return "\(base)\(day.ordinalSuffix) \(month)"
    }

    // MARK: - Cached DateFormatters (avoid re-creating on every call)

    private static let shortDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    private static let fullDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }()

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f
    }()

    private static let yearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy"
        return f
    }()

    private static let weekdayDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d"
        return f
    }()

    private static let shortMonthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f
    }()

    private static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()
}

// MARK: - Int Ordinal Suffix

extension Int {
    /// Returns the English ordinal suffix for the integer ("st", "nd", "rd", "th").
    var ordinalSuffix: String {
        switch self {
        case 1, 21, 31: return "st"
        case 2, 22:     return "nd"
        case 3, 23:     return "rd"
        default:        return "th"
        }
    }
}
