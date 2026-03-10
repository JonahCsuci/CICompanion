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
class CourseViewModel: ObservableObject {
    
    @Published var courses: [Course] = []
    
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
        Task {
            do {
                courses = try await courseRepository.loadAllCourses()
            } catch {
                print("Error loading all courses:", error)
            }
        }
    }
}
