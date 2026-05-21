//
//  CourseViewModel.swift
//  CICompanion
//
//  Created by Wummiez on 3/6/26.
//

import Foundation
import Combine
import SwiftUI

// ViewModel for the "all classes" screen.
// It stores the array of all courses for the view.
@MainActor
class CoursesListViewModel: ObservableObject {

    @Published var courses: [Course] = []
    @Published var shownCourses: [Course] = [];
    @Published var searchQuery : String = ""
    @Published var hasCourses: [Int: Bool] = [:]
    @Published var studentCourses: [Course] = [];
    @Published var isLoading = false
    @Published var errorMessage: String?
    private var activeStudentId: String?

    // courseRepository methods fetch all courses or student courses
    let courseRepository: CourseRepositoryProtocol

    // studentRepository methods let you update student enrolled courses
    let studentRepository: StudentRepositoryProtocol

    // NOTE: if you update a student's courses, call a load method after
    // to receive the newly updated student data

    init(
        courseRepository: CourseRepositoryProtocol,
        studentRepository: StudentRepositoryProtocol
    ) {
        self.courseRepository = courseRepository
        self.studentRepository = studentRepository
    }

    // Load all classes
    func loadAllCourses(for studentId: String? = nil) {
        activeStudentId = studentId

        Task {
            do {
                isLoading = true
                errorMessage = nil
                courses = try await courseRepository.loadAllCourses()
                shownCourses = courses

                guard let studentId else {
                    studentCourses = []
                    isLoading = false
                    return
                }

                do {
                    let _ = try await studentRepository.loadStudent()
                    let loadedStudentCourses = try await courseRepository.loadStudentCourses()
                    if activeStudentId == studentId {
                        studentCourses = loadedStudentCourses
                    }
                } catch {
                    if activeStudentId == studentId {
                        studentCourses = []
                        print("Error loading student courses:", error)
                    }
                }
            } catch {
                print("Error loading all courses:", error)
                errorMessage = "Could not load courses"
            }
            if activeStudentId == studentId {
                isLoading = false
            }
        }
    }

    func handleSessionChanged(to studentId: String?) {
        activeStudentId = studentId
        studentCourses = []
        hasCourses = [:]
        errorMessage = nil

        if studentId != nil || courses.isEmpty {
            loadAllCourses(for: studentId)
        }
    }

    func search() {
        var searched : [Course] = []
        for course in courses {
            if course.courseName.lowercased().contains(searchQuery.lowercased()) || course.courseCode.lowercased().contains(searchQuery.lowercased()) || course.instructor.lowercased().contains(searchQuery.lowercased()) {
                searched.append(course)
            }
        }

        shownCourses = searched
    }


    func addCourse(course: Course, for studentId: String? = nil) {
        let targetStudentId = studentId ?? activeStudentId

        Task {
            do {
                guard activeStudentId == targetStudentId else { return }
                guard !isEnrolled(course) else { return }
                try await studentRepository.addStudentCourse(courseId: course.id)
                guard activeStudentId == targetStudentId else { return }
                if !isEnrolled(course) {
                    studentCourses.append(course)
                }
            } catch {
                print("Error adding class: ", error)
                errorMessage = "Could not add course"
            }
        }
    }

    func removeCourse(course: Course, for studentId: String? = nil) {
        let targetStudentId = studentId ?? activeStudentId

        Task {
            do {
                guard activeStudentId == targetStudentId else { return }
                try await studentRepository.deleteStudentCourse(courseId: course.id)
                guard activeStudentId == targetStudentId else { return }
                studentCourses = studentCourses.filter{ $0.id != course.id }
            } catch {
                print("Error removing class: ", error)
                errorMessage = "Could not remove course"
            }
        }
    }

    func isEnrolled(_ course: Course) -> Bool {
        studentCourses.contains { $0.id == course.id }
    }
}
