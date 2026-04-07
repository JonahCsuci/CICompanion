//
//  TimeRange.swift
//  CICompanion
//
//  Created by Emma on 4/6/26.
//

import SwiftUI

struct TimeRange : Hashable, Identifiable {
    /// In minutes since 00:00!!
    var startTime: Int
    /// In minutes since 00:00
    var endTime: Int
    
    var userID: String
    
    var id: UUID = UUID()

    var day: Date
    
    var isStudyRoomAvailable: Bool = false
    
    var peopleAvailable : Int = 0 // TODO: Make this an array of user IDs instead of an Int
    
    // Sergio don't look below. i barely understand what i was thinking when i implemeted this. google is my beloved, but this is the depths of hell. i bid thee, doth not go down
    
    // this modifies what happens when you compare thins like with ==
    static func == (lhs: TimeRange, rhs: TimeRange) -> Bool {
        lhs.startTime == rhs.startTime &&
        lhs.endTime == rhs.endTime &&
        Calendar.current.isDate(lhs.day, inSameDayAs: rhs.day)
    }

    
    // hash table stuff :)
    func hash(into hasher: inout Hasher) {
        // when i do hasher.combine thatm eans that it's going to hash based on this stuff. this is all just so that it doesn't compare stuff based on UID/UUID :skull:
        
        hasher.combine(startTime)
        hasher.combine(endTime)

        let components = Calendar.current.dateComponents([.year, .month, .day], from: day)
        hasher.combine(components.year)
        hasher.combine(components.month)
        hasher.combine(components.day)
    }
}
