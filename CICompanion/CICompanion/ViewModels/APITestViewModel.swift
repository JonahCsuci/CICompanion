//
//  TestViewModel.swift
//  CICompanion
//
//  Created by Wummiez on 3/18/26.
//

import Foundation
import Combine

@MainActor
class APITestViewModel: ObservableObject {
    
    @Published var statusMessage: String = "Ready to test"
    @Published var courses: [Course] = []
    @Published var studentCourses: [Course] = []
    @Published var contactEmail: String = ""
    @Published var contacts: [ContactStudent] = []
    
    let courseRepository: CourseRepositoryProtocol
    let studentRepository: StudentRepositoryProtocol
    
    init(
        courseRepository: CourseRepositoryProtocol,
        studentRepository: StudentRepositoryProtocol
    ) {
        self.courseRepository = courseRepository
        self.studentRepository = studentRepository
    }
    
    func testLoadCourses() {
        Task {
            do {
                let loadedCourses = try await courseRepository.loadAllCourses()
                courses = loadedCourses
                statusMessage = "Loaded \(loadedCourses.count) courses"
            } catch {
                statusMessage = "Load courses failed: \(error.localizedDescription)"
            }
        }
    }
    
    func testLoadStudentCourses() {
        Task {
            do {
                let loadedStudentCourses = try await courseRepository.loadStudentCourses()
                studentCourses = loadedStudentCourses
                statusMessage = "Loaded \(loadedStudentCourses.count) student courses"
            } catch {
                statusMessage = "Load courses failed: \(error.localizedDescription)"
            }
        }
    }
    
    func testAddCourse(courseId: Int) {
        Task {
            do {
                try await studentRepository.addStudentCourse(courseId: courseId)
                statusMessage = "Added course \(courseId)"
            } catch {
                statusMessage = "Add course failed: \(error.localizedDescription)"
            }
        }
    }
    
    func testDeleteCourse(courseId: Int) {
        Task {
            do {
                try await studentRepository.deleteStudentCourse(courseId: courseId)
                statusMessage = "Deleted course \(courseId)"
            } catch {
                statusMessage = "Delete course failed: \(error.localizedDescription)"
            }
        }
    }

    func testAddContact() {
        let email = contactEmail.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !email.isEmpty else {
            statusMessage = "Enter a contact email"
            return
        }

        Task {
            do {
                try await studentRepository.addStudentContact(email: email)
                statusMessage = "Added contact \(email)"
            } catch {
                statusMessage = "Add contact failed: \(error.localizedDescription)"
            }
        }
    }

    func testLoadContacts() {
        Task {
            do {
                contacts = try await studentRepository.loadStudentContacts()
                statusMessage = "Loaded \(contacts.count) contacts"
            } catch {
                statusMessage = "Load contacts failed: \(error.localizedDescription)"
            }
        }
    }

    func testDeleteContact(contactStudentId: String) {
        Task {
            do {
                try await studentRepository.deleteStudentContact(contactStudentId: contactStudentId)
                contacts.removeAll { $0.id == contactStudentId }
                statusMessage = "Removed contact"
            } catch {
                statusMessage = "Remove contact failed: \(error.localizedDescription)"
            }
        }
    }
}
