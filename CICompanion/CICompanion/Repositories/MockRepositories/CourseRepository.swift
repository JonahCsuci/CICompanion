//
//  CourseRepository.swift
//  CICompanion
//
//  Created by Wummiez on 3/6/26.
//

import Foundation

// Repository = data layer.
// Its job is to load data.
// For now it reads local JSON files.
class CourseRepository: CourseRepositoryProtocol {
    
    let studentRepository: StudentRepositoryProtocol
    private let bundle: Bundle
    
    init(studentRepository: StudentRepositoryProtocol, bundle: Bundle = .main) {
        self.studentRepository = studentRepository
        self.bundle = bundle
    }
    
    func loadAllCourses() async throws -> [Course] {
        try LocalCourseCatalog.loadCourses(bundle: bundle)
    }
     
    func loadStudentCourses() async throws -> [Course] {
        let courses = try await loadAllCourses()
        let student = try await studentRepository.loadStudent()
        
        return courses.filter {
            student.courses.contains($0.id)
        }
    }
    
}
