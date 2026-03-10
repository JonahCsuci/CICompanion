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
    
    init(studentRepository: StudentRepositoryProtocol) {
        self.studentRepository = studentRepository
    }
    
    func loadAllCourses() async throws -> [Course] {
        let url = Bundle.main.url(forResource: "courses", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let courses = try JSONDecoder().decode([Course].self, from: data)
        
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
