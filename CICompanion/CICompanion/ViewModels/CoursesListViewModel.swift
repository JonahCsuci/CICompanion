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
class CoursesListViewModel: ObservableObject {
    
    @Published var courses: [Course] = []
    @Published var shownCourses: [Course] = [];
    @Published var searchQuery : String = ""
    
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
    func loadAllCourses() {
        print("Loading courses...")
        Task {
            do {
                courses = try await courseRepository.loadAllCourses()
                shownCourses = courses
                print(courses)
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
    
    
    func addClass(course: Course) {
        // TODO
    }
    
    func hasCourse(course: Course) -> Bool {
        Task {
            do {
                return try await studentRepository.hasStudentCourse(courseId: course.id)
            }
            catch {
                print("Error checking if student has course")
                return false;
            }
        }
        
        return false;
    }
}
