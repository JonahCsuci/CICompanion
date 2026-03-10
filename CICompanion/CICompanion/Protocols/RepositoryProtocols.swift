//
//  Protocols.swift
//  CICompanion
//
//  Created by Wummiez on 3/9/26.
//

import Foundation

protocol EventsRepositoryProtocol {
    func loadAllEvents() async throws -> [Event]
    func loadStudentEvents() async throws -> [Event]
}

protocol CourseRepositoryProtocol {
    func loadAllCourses() async throws -> [Course]
    func loadStudentCourses() async throws -> [Course]
}

protocol StudentRepositoryProtocol {
    func loadStudent() async throws -> Student
    func addStudentCourse(courseId: Int) async throws
    func deleteStudentCourse(courseId: Int) async throws
    func addStudentEvent(eventId: Int) async throws
    func deleteStudentEvent(eventId: Int) async throws
}
