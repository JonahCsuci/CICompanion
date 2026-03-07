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
    
    let repository: CourseRepository
    
    // Dependency injection:
    // the repository is passed in from outside instead of being created here.
    init(repository: CourseRepository) {
        self.repository = repository
    }
    
    // Load all classes into the courses array
    func loadCourses() {
        do {
            courses = try repository.loadAllCourses()
        } catch {
            print("Error loading all courses:", error)
        }
    }
}
