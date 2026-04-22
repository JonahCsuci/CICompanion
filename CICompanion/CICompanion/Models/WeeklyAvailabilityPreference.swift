//
//  StudentAvailability.swift
//  CICompanion
//
//  Created by Wummiez on 4/17/26.
//

import Foundation

struct FreeSlot: Codable, Equatable {
    var startHour: Int
    var endHour: Int
}

struct DailyAvailability: Codable {
    var day: String
    var freeSlots: [FreeSlot]
}

struct WeeklyAvailability: Codable {
    var days: [DailyAvailability]
}

struct AvailabilitySummary: Codable {
    var weekdayFreeSlots: [FreeSlot]
    var weekendFreeSlots: [FreeSlot]
}
