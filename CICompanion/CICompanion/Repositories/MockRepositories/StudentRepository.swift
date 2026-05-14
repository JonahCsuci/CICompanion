//
//  StudentRepository.swift
//  CICompanion
//
//  Created by Wummiez on 3/9/26.
//

import Foundation

class StudentRepository: StudentRepositoryProtocol {
    
    // Stored student in memory (mock data)
    private var studentSharedCourses: [StudentSharedCourses]?
    private var student: Student?
    private var contacts: [ContactStudent] = []

    private let contactDirectory = [
        StudentSharedCourses(
            id: "b9d959de-9091-70c6-dc3b-cd0519f3a0c9",
            name: "Sergio",
            email: "sergio.macias207@myci.csuci.edu",
            sharedCourseCount: 2
        ),
        StudentSharedCourses(
            id: "d9e9d9be-b021-703b-62f8-f1eef1eb72a2",
            name: "User",
            email: "wummiez805@gmail.com",
            sharedCourseCount: 1
        ),
        StudentSharedCourses(
            id: "not-shared-contact",
            name: "No Shared Class",
            email: "not.shared@myci.csuci.edu",
            sharedCourseCount: 0
        )
    ]
    private let mockStudentEmail = "student@email.com"

    // Load student from JSON the first time
    func loadStudent() async throws -> Student {
        
        // If student has previously been loaded in, return it back
        if let student {
            return student
        }
        
        let url = Bundle.main.url(forResource: "student", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let decodedStudent = try JSONDecoder().decode(Student.self, from: data)
        
        student = decodedStudent
        return decodedStudent
    }
    
    // Add a course to the student's courses array
    func addStudentCourse(courseId: Int) async throws {
        if var student = student {
            if !student.courses.contains(courseId) {
                student.courses.append(courseId)
            }
            self.student = student
        } else {
            print("Adding course unable to complete, student is nil")
        }
    }
    
    // Remove a course from the student's courses array
    func deleteStudentCourse(courseId: Int) async throws {
        
        if var student = student {
            student.courses.removeAll { $0 == courseId }
            self.student = student
        }
    }
    
    func hasStudentCourse(courseId: Int) async throws -> Bool {
        if student == nil {
            print("Student is nil for some reason")
            _ = try await loadStudent()
        }
        guard let student else { return false }
        return student.courses.contains(courseId)
    }
    
    func updateStudentEvents(events: [Event]) async throws {
            return
        }
        
        
    func addStudentEvent(event: Event) async throws {
        return
    }
    
    func hasStudentEvent(event: Event) async throws -> Bool {
        return false
    }
        
    func deleteStudentEvent(event: Event) async throws {
        return
    }
    
    func addStudentContact(email: String) async throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if normalizedEmail == mockStudentEmail {
            throw apiError(statusCode: 400, message: "Student cannot add themself as a contact")
        }

        guard let contact = contactDirectory.first(where: { $0.email.lowercased() == normalizedEmail }) else {
            throw apiError(statusCode: 404, message: "Contact student not found")
        }

        guard contact.sharedCourseCount > 0 else {
            throw apiError(statusCode: 403, message: "Contacts must share at least one course")
        }

        guard !contacts.contains(where: { $0.id == contact.id }) else {
            throw apiError(statusCode: 409, message: "Contact already exists")
        }

        contacts.append(ContactStudent(id: contact.id, name: contact.name, email: contact.email))
        contacts.sort {
            if $0.name == $1.name {
                return $0.email < $1.email
            }
            return $0.name < $1.name
        }
    }

    func loadStudentContacts() async throws -> [ContactStudent] {
        contacts
    }

    func deleteStudentContact(contactStudentId: String) async throws {
        let originalCount = contacts.count
        contacts.removeAll { $0.id == contactStudentId }

        if contacts.count == originalCount {
            throw apiError(statusCode: 404, message: "Contact not found")
        }
    }

    func hasStudentContact(contactStudentId: String) async throws -> Bool {
        contacts.contains { $0.id == contactStudentId }
    }

    func searchContactStudents(query: String) async throws -> [StudentSharedCourses] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard trimmedQuery.count >= 3 else {
            return []
        }

        return contactDirectory
            .filter { student in
                student.sharedCourseCount > 0
                && student.email.lowercased() != mockStudentEmail
                && !contacts.contains { $0.id == student.id }
                && (
                    student.name.lowercased().contains(trimmedQuery)
                    || student.email.lowercased().contains(trimmedQuery)
                )
            }
            .sorted {
                if $0.sharedCourseCount == $1.sharedCourseCount {
                    return $0.name < $1.name
                }
                return $0.sharedCourseCount > $1.sharedCourseCount
            }
    }

    func ensureStudentExists() async throws -> Student {
        //
        return student!
    }

    private func apiError(statusCode: Int, message: String) -> NSError {
        NSError(
            domain: "APIError",
            code: statusCode,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
    
    func updateScheduleTimes(meetings: [MeetingProposal]) async throws {
        return
    }
    
    func loadStudentSharedCourses() async throws -> [StudentSharedCourses] {
        if let studentSharedCourses {
            return studentSharedCourses
        }

        return contactDirectory.filter { student in
            student.sharedCourseCount > 0 && !contacts.contains { contact in contact.id == student.id }
        }
    }

    func sendContactRequest(toEmail email: String) async throws -> SendContactRequestResponse {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if normalizedEmail == mockStudentEmail {
            throw apiError(statusCode: 400, message: "Cannot add yourself as a contact")
        }

        guard let candidate = contactDirectory.first(where: { $0.email.lowercased() == normalizedEmail }) else {
            throw apiError(statusCode: 404, message: "Contact student not found")
        }

        guard candidate.sharedCourseCount > 0 else {
            throw apiError(statusCode: 403, message: "Contacts must share at least one course")
        }

        if contacts.contains(where: { $0.id == candidate.id }) {
            throw apiError(statusCode: 409, message: "Students are already contacts")
        }

        return SendContactRequestResponse(
            success: true,
            status: "pending",
            autoAccepted: nil,
            requestId: Int.random(in: 1...10_000),
            contactStudentId: candidate.id,
            conversationId: nil
        )
    }

    func loadContactRequests(status: String?, direction: String?, limit: Int?) async throws -> ContactRequestListResponse {
        ContactRequestListResponse(
            success: true,
            studentId: nil,
            statusFilter: status,
            directionFilter: direction,
            incoming: [],
            outgoing: [],
            counts: ContactRequestListResponse.Counts(
                incomingPending: 0,
                outgoingPending: 0,
                totalPending: 0
            )
        )
    }

    func acceptContactRequest(requestId: Int) async throws -> ContactRequestActionResponse {
        ContactRequestActionResponse(
            success: true,
            action: "accept",
            status: "accepted",
            requestId: requestId,
            requesterId: nil,
            recipientId: nil,
            contactStudentId: nil,
            conversationId: 1
        )
    }

    func declineContactRequest(requestId: Int) async throws -> ContactRequestActionResponse {
        ContactRequestActionResponse(
            success: true,
            action: "decline",
            status: "declined",
            requestId: requestId,
            requesterId: nil,
            recipientId: nil,
            contactStudentId: nil,
            conversationId: nil
        )
    }

    func cancelContactRequest(requestId: Int) async throws -> ContactRequestActionResponse {
        ContactRequestActionResponse(
            success: true,
            action: "cancel",
            status: "canceled",
            requestId: requestId,
            requesterId: nil,
            recipientId: nil,
            contactStudentId: nil,
            conversationId: nil
        )
    }
}
