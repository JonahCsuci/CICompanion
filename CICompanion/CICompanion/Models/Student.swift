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
        let meetingsString = (try? container.decode(String.self, forKey: .meetings)) ?? ""
        
        meetings = try JSONDecoder().decode([MeetingProposal].self, from: meetingsString.data(using: .utf8) ?? Data())
    }
}
