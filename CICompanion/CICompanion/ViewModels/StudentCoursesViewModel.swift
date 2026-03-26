//
//  StudentCoursesViewModel.swift
//  CICompanion
//
//  Created by Wummiez on 3/6/26.
//

import Foundation
import SwiftUI
import Combine

// ViewModel for the student's homepage / student schedule screen.
// It stores only the courses that belong to the student.
class StudentCoursesViewModel: ObservableObject {
    
    @Published var courses: [Course] = []
    
    // courseRepository methods fetch all courses or student enrolled courses
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
    
    // Load student enrolled courses
    func loadStudentCourses() {
        Task {
            do {
                courses = try await courseRepository.loadStudentCourses()
            } catch {
                print("Error loading student courses:", error)
            }
        }
    }
}
