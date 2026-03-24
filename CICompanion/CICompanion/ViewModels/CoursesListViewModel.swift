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
    
    func checkHasAllCourses() {
        for course in shownCourses {
            checkHasCourse(course: course)
        }
    }
    
    // Load all classes
    func loadAllCourses() {
        Task {
            do {
                courses = try await courseRepository.loadAllCourses()
                try await studentRepository.loadStudent()
                shownCourses = courses
                
                checkHasAllCourses()
            } catch {
                print("Error loading all courses:", error)
            }
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
    
    
    func addCourse(course: Course) {
        Task {
            do {
                try await studentRepository.addStudentCourse(courseId: course.id)
                checkHasAllCourses()
            } catch {
                print("Error adding class: ", error)
            }
        }
    }
    
    func removeCourse(course: Course) {
        Task {
            do {
                try await studentRepository.deleteStudentCourse(courseId: course.id)
                checkHasAllCourses()
            } catch {
                print("Error removing class: ", error)
            }
        }
    }
    
    func checkHasCourse(course: Course) {
        Task {
            do {
                let result = try await studentRepository.hasStudentCourse(courseId: course.id)
                hasCourses[course.id] = result
            }
            catch {
                print("Error checking if student has course: ", error)
                hasCourses[course.id] = false
            }
        }
    }
}
