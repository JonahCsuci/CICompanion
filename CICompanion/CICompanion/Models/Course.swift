//
//  Course.swift
//  CICompanion
//
//  Created by Wummiez on 3/6/26.
//

import Foundation

struct Course: Codable, Identifiable, Equatable {
    let springCourse: SpringCourse

    var id: Int { springCourse.id }
    var courseName: String { springCourse.title }
    var courseCode: String { "\(springCourse.subject) \(springCourse.courseNumber)-\(springCourse.section)" }
    var instructor: String { springCourse.instructor ?? "Instructor TBD" }
    var location: String { springCourse.room ?? springCourse.location }
    var startTime: String { firstScheduledOccurrence?.startTime ?? "N/A" }
    var endTime: String { firstScheduledOccurrence?.endTime ?? "N/A" }
    var days: [String] { Array(Set(scheduledOccurrences.flatMap(\.days))).sorted(by: weekdaySort) }
    var isAsynchronous: Bool { scheduledOccurrences.isEmpty }
    var courseDescription: String { springCourse.description }
    var instructionMode: String { springCourse.instructionMode }
    var units: String { springCourse.units }
    var enrollmentRequirements: String? { springCourse.enrollmentRequirements }
    var classNotes: String? { springCourse.classNotes }
    var scheduledOccurrences: [CourseScheduleOccurrence] {
        springCourse.meetingTimes.enumerated().compactMap { index, meetingTime in
            guard
                meetingTime.isScheduled,
                let days = meetingTime.days,
                !days.isEmpty,
                let startTime = meetingTime.startTime,
                let endTime = meetingTime.endTime
            else {
                return nil
            }

            return CourseScheduleOccurrence(
                id: "\(id)-\(index)",
                courseId: id,
                courseName: courseName,
                courseCode: courseCode,
                days: days,
                startTime: startTime,
                endTime: endTime,
                location: meetingTime.room ?? location
            )
        }
    }
    var firstScheduledOccurrence: CourseScheduleOccurrence? { scheduledOccurrences.first }
    var scheduleSummary: String {
        let occurrences = scheduledOccurrences
        guard !occurrences.isEmpty else {
            return "Arranged"
        }

        return occurrences
            .map { "\($0.days.joined(separator: ", ")) \($0.startTime)-\($0.endTime)" }
            .joined(separator: "; ")
    }

    init(springCourse: SpringCourse) {
        self.springCourse = springCourse
    }

    init(from decoder: Decoder) throws {
        springCourse = try SpringCourse(from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        try springCourse.encode(to: encoder)
    }

    private func weekdaySort(_ lhs: String, _ rhs: String) -> Bool {
        Self.weekdayOrder[lhs.lowercased(), default: Int.max] < Self.weekdayOrder[rhs.lowercased(), default: Int.max]
    }

    private static let weekdayOrder: [String: Int] = [
        "sunday": 0,
        "monday": 1,
        "tuesday": 2,
        "wednesday": 3,
        "thursday": 4,
        "friday": 5,
        "saturday": 6
    ]
}

struct SpringCourse: Codable, Identifiable, Equatable {
    let classNumber: Int
    let subject: String
    let courseNumber: String
    let section: String
    let component: String
    let title: String
    let units: String
    let instructor: String?
    let instructionMode: String
    let room: String?
    let campus: String
    let location: String
    let description: String
    let enrollmentRequirements: String?
    let classNotes: String?
    let meetingTimes: [SpringCourseMeetingTime]

    var id: Int { classNumber }

    enum CodingKeys: String, CodingKey {
        case classNumber = "class_number"
        case subject
        case courseNumber = "course_number"
        case section
        case component
        case title
        case units
        case instructor
        case instructionMode = "instruction_mode"
        case room
        case campus
        case location
        case description
        case enrollmentRequirements = "enrollment_requirements"
        case classNotes = "class_notes"
        case meetingTimes = "meeting_times"
    }
}

struct SpringCourseMeetingTime: Codable, Equatable {
    let type: String
    let days: [String]?
    let startTime: String?
    let endTime: String?
    let room: String?

    var isScheduled: Bool {
        type.lowercased() == "scheduled" && days != nil && startTime != nil && endTime != nil
    }

    enum CodingKeys: String, CodingKey {
        case type
        case days
        case startTime = "start_time"
        case endTime = "end_time"
        case room
    }
}

struct CourseScheduleOccurrence: Identifiable, Equatable {
    let id: String
    let courseId: Int
    let courseName: String
    let courseCode: String
    let days: [String]
    let startTime: String
    let endTime: String
    let location: String
}
