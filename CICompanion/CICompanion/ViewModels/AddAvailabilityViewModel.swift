import SwiftUI
import Combine
import Foundation

@MainActor
class AddAvailabilityViewModel: ObservableObject {
    let days: [Date]
    let timeBlockSize: Int
    let startTime: Int
    let endTime: Int

    let courseRanges: Set<TimeRange>
    @Published var selectedRanges: Set<TimeRange>

    init(
        days: [Date],
        timeBlockSize: Int = 60,
        startTime: Int,
        endTime: Int,
        courses: [Course]
    ) {
        self.days = days
        self.timeBlockSize = timeBlockSize
        self.startTime = startTime
        self.endTime = endTime

        let allRanges = Self.makeAllRanges(
            days: days,
            timeBlockSize: timeBlockSize,
            startTime: startTime,
            endTime: endTime
        )

        let courseRanges = Self.makeCourseRanges(
            days: days,
            timeBlockSize: timeBlockSize,
            startTime: startTime,
            endTime: endTime,
            courses: courses
        )

        self.courseRanges = courseRanges
        self.selectedRanges = allRanges.subtracting(courseRanges)
    }

    var timeSlots: [Int] {
        Array(stride(from: startTime, to: endTime, by: timeBlockSize))
    }

    func isCourse(_ range: TimeRange) -> Bool {
        courseRanges.contains(range)
    }

    func isSelected(_ range: TimeRange) -> Bool {
        selectedRanges.contains(range)
    }

    func rangeFor(row: Int, col: Int) -> TimeRange {
        let start = timeSlots[row]
        return TimeRange(
            startTime: start,
            endTime: start + timeBlockSize,
            userID: "",
            day: days[col]
        )
    }

    func setSelected(_ range: TimeRange, isSelected: Bool) {
        if isSelected {
            selectedRanges.insert(range)
        } else {
            selectedRanges.remove(range)
        }
    }

    func toggle(_ range: TimeRange) {
        if selectedRanges.contains(range) {
            selectedRanges.remove(range)
        } else {
            selectedRanges.insert(range)
        }
    }

    func availabilityToSave() -> [TimeRange] {
        selectedRanges.sorted {
            if Calendar.current.isDate($0.day, inSameDayAs: $1.day) {
                return $0.startTime < $1.startTime
            }
            return $0.day < $1.day
        }
    }

    private static func makeAllRanges(
        days: [Date],
        timeBlockSize: Int,
        startTime: Int,
        endTime: Int
    ) -> Set<TimeRange> {
        var ranges = Set<TimeRange>()

        for day in days {
            for slotStart in stride(from: startTime, to: endTime, by: timeBlockSize) {
                ranges.insert(
                    TimeRange(
                        startTime: slotStart,
                        endTime: slotStart + timeBlockSize,
                        userID: "",
                        day: day
                    )
                )
            }
        }

        return ranges
    }

    private static func makeCourseRanges(
        days: [Date],
        timeBlockSize: Int,
        startTime: Int,
        endTime: Int,
        courses: [Course]
    ) -> Set<TimeRange> {
        var ranges = Set<TimeRange>()
        let calendar = Calendar.current

        for course in courses {
            guard
                let courseStart = DateHelper.timeStringToMinutes(course.startTime),
                let courseEnd = DateHelper.timeStringToMinutes(course.endTime)
            else {
                continue
            }

            for courseDay in course.days {
                guard let matchingDate = matchingDate(for: courseDay, in: days, calendar: calendar) else {
                    continue
                }

                for slotStart in stride(from: startTime, to: endTime, by: timeBlockSize) {
                    let slotEnd = slotStart + timeBlockSize

                    let overlapsCourse = slotStart < courseEnd && slotEnd > courseStart

                    if overlapsCourse {
                        ranges.insert(
                            TimeRange(
                                startTime: slotStart,
                                endTime: slotEnd,
                                userID: "",
                                day: matchingDate
                            )
                        )
                    }
                }
            }
        }

        return ranges
    }

    private static func matchingDate(
        for courseDay: String,
        in days: [Date],
        calendar: Calendar
    ) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        return days.first { date in
            formatter.dateFormat = "EEEE"
            let fullName = formatter.string(from: date)

            formatter.dateFormat = "EEE"
            let shortName = formatter.string(from: date)

            return courseDay.caseInsensitiveCompare(fullName) == .orderedSame ||
                   courseDay.caseInsensitiveCompare(shortName) == .orderedSame
        }
    }
}
