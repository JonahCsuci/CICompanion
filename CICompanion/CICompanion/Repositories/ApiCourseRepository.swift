//
//  ApiCourseRepository.swift
//  CICompanion
//
//  Created by Wummiez on 3/7/26.
//

import Foundation

// API implementation of CourseRepositoryProtocol
// Later this will load data from the backend instead of local JSON files

class APICourseRepository: CourseRepositoryProtocol {
    
    func loadAllCourses() throws -> [Course] {
        // Call API to fetch courses
        return []
    }
    
    func loadStudent() throws -> Student {
        // Call API to fetch student
        fatalError("Not implemented yet")
    }
    
    func loadStudentCourses() throws -> [Course] {
        // Call API to fetch student courses
        return []
    }
}
