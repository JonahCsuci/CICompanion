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
    
    let repository: CourseRepositoryProtocol
    
    // Dependency injection:
    // the repository is passed in from outside.
    init(repository: CourseRepositoryProtocol) {
        self.repository = repository
    }
    
    // Load only this student's classes
    func loadCourses() {
        do {
            courses = try repository.loadStudentCourses()
        } catch {
            print("Error loading student courses:", error)
        }
    }
}
