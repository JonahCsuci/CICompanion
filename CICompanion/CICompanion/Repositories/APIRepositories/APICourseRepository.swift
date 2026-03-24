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
    
    init(studentRepository: StudentRepositoryProtocol) {
        self.studentRepository = studentRepository
    }
    
    private var cachedCourses: [Course]?
    
    func loadAllCourses() async throws -> [Course] {
        
        // If classes were previously loaded, return
        if let cachedCourses {
            return cachedCourses
        }
        
        let baseURL = "https://ibxw69g864.execute-api.us-west-1.amazonaws.com"
        // Create URL
        guard let url = URL(string: "\(baseURL)/courses") else {
            throw URLError(.badURL)
        }
            
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Call API Gateway
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Calls API response checking
        try handleErrorResponse(data: data, response: response)
        
        // Decode JSON into Course structs
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
