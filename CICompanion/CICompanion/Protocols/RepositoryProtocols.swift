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


protocol StudentRepositoryProtocol {
    func loadStudent() async throws -> Student
    func addStudentCourse(courseId: Int) async throws
    func deleteStudentCourse(courseId: Int) async throws
    func ensureStudentExists() async throws -> Student
    func updateStudentEvents(events: [Event]) async throws
    func addStudentEvent(event: Event) async throws
    func hasStudentEvent(event: Event) async throws -> Bool
    func deleteStudentEvent(event: Event) async throws
    func addStudentContact(email: String) async throws
    func loadStudentContacts() async throws -> [ContactStudent]
    func deleteStudentContact(contactStudentId: String) async throws
    func hasStudentContact(contactStudentId: String) async throws -> Bool
    func searchContactStudents(query: String) async throws -> [StudentSharedCourses]
    func updateScheduleTimes(meetings: [MeetingProposal]) async throws
    func loadStudentSharedCourses() async throws -> [StudentSharedCourses]
    func sendContactRequest(toEmail email: String) async throws -> SendContactRequestResponse
    func loadContactRequests(status: String?, direction: String?, limit: Int?) async throws -> ContactRequestListResponse
    func acceptContactRequest(requestId: Int) async throws -> ContactRequestActionResponse
    func declineContactRequest(requestId: Int) async throws -> ContactRequestActionResponse
    func cancelContactRequest(requestId: Int) async throws -> ContactRequestActionResponse
}
