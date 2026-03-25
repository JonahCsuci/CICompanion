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
    
    let baseURL = "https://ibxw69g864.execute-api.us-west-1.amazonaws.com"
    
    private var courses: [Course]?
    
    func loadAllCourses() async throws -> [Course] {
        
        // Return cached courses if already loaded
        if let courses {
            return courses
        }
        
        // Build API endpoint for fetching all courses
        guard let url = URL(string: "\(baseURL)/courses") else {
            throw URLError(.badURL)
        }
            
        var request = URLRequest(url: url)
        
        // Use GET to retrieve courses from backend
        request.httpMethod = "GET"
        
        // Send request to backend (API Gateway -> Lambda -> database)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Validate HTTP response and throw error if request failed
        try handleErrorResponse(data: data, response: response)
        
        // Decode JSON into Course struct array
        let courses = try JSONDecoder().decode([Course].self, from: data)
        
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
