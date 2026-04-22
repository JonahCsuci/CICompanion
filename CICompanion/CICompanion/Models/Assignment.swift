//
//  Assignment.swift
//  CICompanion
//

import Foundation

struct Assignment: Identifiable, Codable {
    let id: String
    let courseId: String
    var title: String
    var details: String
    var isCompleted: Bool
    var isPriority: Bool
    var alertTime: String
    /// The calendar day this assignment is due. Time-of-day is only meaningful when `isAllDay == false`.
    var dueDate: Date
    /// When true, the UI should display the day without a specific time.
    var isAllDay: Bool
    
    init(id: String = UUID().uuidString,
         courseId: String,
         title: String,
         details: String = "",
         isCompleted: Bool = false,
         isPriority: Bool = false,
         alertTime: String = "1 day before class",
         dueDate: Date = Date(),
         isAllDay: Bool = true) {
        self.id = id
        self.courseId = courseId
        self.title = title
        self.details = details
        self.isCompleted = isCompleted
        self.isPriority = isPriority
        self.alertTime = alertTime
        self.dueDate = dueDate
        self.isAllDay = isAllDay
    }
}
