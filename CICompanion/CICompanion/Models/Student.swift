//
//  Student.swift
//  CICompanion
//
//  Created by Wummiez on 3/6/26.
//

import Foundation
import Combine

struct Student: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    var courses: [Int]
    var events: [Event]
    var meetings: [MeetingProposal] = []

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case courses
        case events
        case meetings
    }

    init(
        id: String,
        name: String,
        email: String,
        courses: [Int],
        events: [Event],
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
        courses = Self.decodeCourseIDs(from: container, forKey: .courses)
        events = Self.decodeArray([Event].self, from: container, forKey: .events)

        // `meetings` is stored server-side as a JSON string and may be missing, null, or empty
        // for students who have no proposals. Guard against all of those so a blank value
        // doesn't throw and break the whole Student decode (which silently empties the
        // Add Class list, student courses, etc.).
        meetings = Self.decodeArray([MeetingProposal].self, from: container, forKey: .meetings)
    }

    private static func decodeCourseIDs(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> [Int] {
        if let ids = try? container.decode([Int].self, forKey: key) {
            return ids
        }

        if let stringIDs = try? container.decode([String].self, forKey: key) {
            return stringIDs.compactMap(Int.init)
        }

        guard let jsonString = try? container.decode(String.self, forKey: key),
              let data = jsonString.data(using: .utf8),
              !data.isEmpty
        else {
            return []
        }

        if let ids = try? JSONDecoder().decode([Int].self, from: data) {
            return ids
        }

        if let stringIDs = try? JSONDecoder().decode([String].self, from: data) {
            return stringIDs.compactMap(Int.init)
        }

        return []
    }

    private static func decodeArray<T: Decodable>(
        _ type: [T].Type,
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> [T] {
        if let array = try? container.decode(type, forKey: key) {
            return array
        }

        guard let jsonString = try? container.decode(String.self, forKey: key),
              let data = jsonString.data(using: .utf8),
              !data.isEmpty,
              let decoded = try? JSONDecoder().decode(type, from: data)
        else {
            return []
        }

        return decoded
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
