//
//  ApiCourseRepository.swift
//  CICompanion
//
//  Created by Wummiez on 3/7/26.
//

import Foundation

// Eventually will be handled by APIService
class APICourseRepository: CourseRepositoryProtocol {
    
    let studentRepository: StudentRepositoryProtocol
    private let bundle: Bundle
    
    init(studentRepository: StudentRepositoryProtocol, bundle: Bundle = .main) {
        self.studentRepository = studentRepository
        self.bundle = bundle
    }

    private var courses: [Course]?
    
    func loadAllCourses() async throws -> [Course] {
        
        // Return cached courses if already loaded
        if let courses {
            return courses
        }
        
        let courses = try LocalCourseCatalog.loadCourses(bundle: bundle)
        
        self.courses = courses
            
        return courses
    }
    
    func loadStudentCourses() async throws -> [Course] {
        let courses = try await loadAllCourses()
        let student = try await studentRepository.loadStudent()
        
        return courses.filter {
            student.courses.contains($0.id)
        }
    }
}
