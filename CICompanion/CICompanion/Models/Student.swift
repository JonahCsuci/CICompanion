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
    var events: [Int]
    var meetings: [MeetingProposal] = []
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        courses = try container.decode([Int].self, forKey: .courses)
        events = try container.decode([Int].self, forKey: .events)

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
