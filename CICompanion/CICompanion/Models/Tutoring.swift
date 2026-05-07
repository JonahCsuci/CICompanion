//
//  Tutoring.swift
//  CICompanion
//
//  Created by Wummiez on 4/26/26.
//

import Foundation

struct DaySchedule: Codable {
    var day: String
    var time: String
}
struct Tutor: Codable {
    var name: String
    var subject: String
    var schedule: [DaySchedule]
    var supportedCourses: [String]
}
