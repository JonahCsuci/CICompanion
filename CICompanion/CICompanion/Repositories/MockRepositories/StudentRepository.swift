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
        ContactStudent(
            id: "b9d959de-9091-70c6-dc3b-cd0519f3a0c9",
            name: "Sergio",
            email: "sergio.macias207@myci.csuci.edu"
        ),
        ContactStudent(
            id: "d9e9d9be-b021-703b-62f8-f1eef1eb72a2",
            name: "User",
            email: "wummiez805@gmail.com"
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
    
    // Add event to the student's event array
    func addStudentEvent(eventId: Int) async throws {
        
        if var student = student {
            if !student.events.contains(eventId) {
                student.events.append(eventId)
            }
            self.student = student
        }
    }

    // Remove event from the student's event array
    func deleteStudentEvent(eventId: Int) async throws {
        
        if var student = student {
            student.events.removeAll { $0 == eventId }
            self.student = student
        }
    }
    
    func addStudentContact(email: String) async throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if normalizedEmail == mockStudentEmail {
            throw apiError(statusCode: 400, message: "Student cannot add themself as a contact")
        }

        guard let contact = contactDirectory.first(where: { $0.email.lowercased() == normalizedEmail }) else {
            throw apiError(statusCode: 404, message: "Contact student not found")
        }

        guard !contacts.contains(where: { $0.id == contact.id }) else {
            throw apiError(statusCode: 409, message: "Contact already exists")
        }

        contacts.append(contact)
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
        return studentSharedCourses!
    }
}
