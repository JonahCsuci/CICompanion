//
//  MeetingProposal.swift
//  CICompanion
//
//  Created by Emma on 4/17/26.
//

import Foundation

struct MeetingProposal: Codable, Hashable {
    // stuff that needs to save and get loaded in database
    var timeRange : TimeRange
    var conversationID: Int
    var title: String
    var respondees: Set<String> = Set()
    var studyRoomID: Int?
    
    static var studyRoomNumbers: [Int: String] = [
        61319: "1732",
        61320: "1733",
        61317: "1753",
        61318: "1754",
        128341: "2346",
        127833: "2348",
        128746: "2350",
        127829: "2352",
        127832: "2354",
        127827: "2356",
        127825: "2358",
        111071: "2362",
        111070: "2364"
    ]
    
    func studyRoom() -> String {
        if (studyRoomID == nil) {
            return "Error: no study room attached"
        }
        
        return "Broome " + (MeetingProposal.studyRoomNumbers[studyRoomID!] ?? "N/A")
    }
}
