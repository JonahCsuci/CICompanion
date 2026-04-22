//
//  Protocols.swift
//  CICompanion
//
//  Created by Wummiez on 3/9/26.
//

import Foundation

protocol CourseRepositoryProtocol {
    func loadAllCourses() async throws -> [Course]
    func loadStudentCourses() async throws -> [Course]
}

protocol EventsRepositoryProtocol {
    func loadAllEvents() async throws -> [Event]
    func loadStudentEvents() async throws -> [Event]
}

protocol StudentRepositoryProtocol {
    func loadStudent() async throws -> Student
    func addStudentCourse(courseId: Int) async throws
    func deleteStudentCourse(courseId: Int) async throws
    func ensureStudentExists() async throws -> Student
    func addStudentEvent(eventId: Int) async throws
    func deleteStudentEvent(eventId: Int) async throws
    func addStudentContact(email: String) async throws
    func loadStudentContacts() async throws -> [ContactStudent]
    func deleteStudentContact(contactStudentId: String) async throws
    func hasStudentContact(contactStudentId: String) async throws -> Bool
    func updateScheduleTimes(meetings: [MeetingProposal]) async throws
}
