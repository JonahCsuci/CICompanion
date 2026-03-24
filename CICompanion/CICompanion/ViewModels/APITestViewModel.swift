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
    @Published var events: [Event] = []
    @Published var studentCourses: [Course] = []
    @Published var studentEvents: [Event] = []
    
    let courseRepository: CourseRepositoryProtocol
    let eventsRepository: EventsRepositoryProtocol
    let studentRepository: StudentRepositoryProtocol
    
    init(
        courseRepository: CourseRepositoryProtocol,
        eventsRepository: EventsRepositoryProtocol,
        studentRepository: StudentRepositoryProtocol
    ) {
        self.courseRepository = courseRepository
        self.eventsRepository = eventsRepository
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
    
    func testLoadStudentEvents() {
        Task {
            do {
                let loadedStudentEvents = try await eventsRepository.loadStudentEvents()
                studentEvents = loadedStudentEvents
                statusMessage = "Loaded \(loadedStudentEvents.count) student events"
            } catch {
                statusMessage = "Load events failed: \(error.localizedDescription)"
            }
        }
    }
    
    func testLoadEvents() {
        Task {
            do {
                let loadedEvents = try await eventsRepository.loadAllEvents()
                events = loadedEvents
                statusMessage = "Loaded \(loadedEvents.count) events"
            } catch {
                statusMessage = "Load events failed: \(error.localizedDescription)"
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
    
    func testAddEvent(eventId: Int) {
        Task {
            do {
                try await studentRepository.addStudentEvent(eventId: eventId)
                statusMessage = "Added event \(eventId)"
            } catch {
                statusMessage = "Add event failed: \(error.localizedDescription)"
            }
        }
    }
    
    func testDeleteEvent(eventId: Int) {
        Task {
            do {
                try await studentRepository.deleteStudentEvent(eventId: eventId)
                statusMessage = "Deleted event \(eventId)"
            } catch {
                statusMessage = "Delete event failed: \(error.localizedDescription)"
            }
        }
    }
}
