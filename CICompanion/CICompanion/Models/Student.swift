//
//  Student.swift
//  CICompanion
//
//  Created by Wummiez on 3/6/26.
//

import Foundation

struct Student: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    var courses: [Int]
    var events: [String]
    var meetings: [MeetingProposal] = []

    init(
        id: String,
        name: String,
        email: String,
        courses: [Int],
        events: [String],
        meetings: [MeetingProposal] = []
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.courses = courses
        self.events = events
        self.meetings = meetings
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        courses = try container.decode([Int].self, forKey: .courses)
        events = try container.decode([String].self, forKey: .events)

        // `meetings` is stored server-side as a JSON string and may be missing, null, or empty
        // for students who have no proposals. Guard against all of those so a blank value
        // doesn't throw and break the whole Student decode (which silently empties the
        // Add Class list, student courses, etc.).
        if let meetingsString = try? container.decode(String.self, forKey: .meetings),
           let data = meetingsString.data(using: .utf8),
           !data.isEmpty,
           let decoded = try? JSONDecoder().decode([MeetingProposal].self, from: data) {
            meetings = decoded
        } else {
            meetings = []
        }
    }
}

struct StudentSharedCourses: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let sharedCourseCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case sharedCourseCount = "shared_course_count"
    }
}

struct ContactStudentSearchResponse: Codable {
    let students: [StudentSharedCourses]
}
