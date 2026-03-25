//
//  AddClassViewModel.swift
//  CICompanion
//
//

import Foundation
import Combine

// ViewModel for the add-class screen.
// It loads the course catalog and adds a selected course to the student's schedule.
class AddClassViewModel: ObservableObject {
    
    @Published var courses: [Course] = []
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    let courseRepository: CourseRepositoryProtocol
    let studentRepository: StudentRepositoryProtocol
    
    init(
        courseRepository: CourseRepositoryProtocol,
        studentRepository: StudentRepositoryProtocol
    ) {
        self.courseRepository = courseRepository
        self.studentRepository = studentRepository
    }
    
    // Load all available courses from the course catalog.
    func loadAvailableCourses() {
        Task {
            do {
                errorMessage = nil
                successMessage = nil
                courses = try await courseRepository.loadAllCourses()
            } catch {
                successMessage = nil
                errorMessage = "Unable to load courses right now."
                print("Error loading available courses:", error)
            }
        }
    }
    
    // Add a course to the student's schedule if it is not already there.
    func addCourse(_ course: Course) {
        Task {
            do {
                let student = try await studentRepository.loadStudent()
                
                if student.courses.contains(course.id) {
                    successMessage = nil
                    errorMessage = "This class is already in your schedule."
                    return
                }
                
                try await studentRepository.addStudentCourse(courseId: course.id)
                errorMessage = nil
                successMessage = "\(course.courseCode) was added to your schedule."
                
                // TODO: Schedule a class reminder notification after a successful add.
                scheduleCourseNotification(for: course)
            } catch {
                successMessage = nil
                errorMessage = "Unable to add this class right now."
                print("Error adding course:", error)
            }
        }
    }
    
    private func scheduleCourseNotification(for course: Course) {
        // Placeholder hook for a future notification feature.
    }
}
