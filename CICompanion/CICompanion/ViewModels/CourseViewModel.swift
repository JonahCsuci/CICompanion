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
    @Published var shownCourses: [Course] = [];
    @Published var searchQuery : String = ""
    
    let repository: CourseRepositoryProtocol
    
    // Dependency injection:
    // the repository is passed in from outside instead of being created here.
    init(repository: CourseRepositoryProtocol) {
        self.repository = repository
    }
    
    // Load all classes into the courses array
    func loadCourses() {
        do {
            courses = try repository.loadAllCourses()
            shownCourses = courses
        } catch {
            print("Error loading all courses:", error)
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
}
