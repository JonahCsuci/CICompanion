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
    
    init(id: String = UUID().uuidString, courseId: String, title: String, details: String = "", isCompleted: Bool = false, isPriority: Bool = false, alertTime: String = "1 day before class") {
        self.id = id
        self.courseId = courseId
        self.title = title
        self.details = details
        self.isCompleted = isCompleted
        self.isPriority = isPriority
        self.alertTime = alertTime
    }
}
