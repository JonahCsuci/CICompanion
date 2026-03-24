//
//  APIStudentRepository.swift
//  CICompanion
//
//  Created by Wummiez on 3/9/26.
//

import Foundation


class APIStudentRepository: StudentRepositoryProtocol {
    
    let baseURL = "https://ibxw69g864.execute-api.us-west-1.amazonaws.com"
    
    // Load student from JSON the first time
    func loadStudent() async throws -> Student {
        
        let studentId = 1
        
        // Create URL
        guard let url = URL(string: "\(baseURL)/student/\(studentId)") else {
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

        // Decode JSON into Student structs
        let student = try JSONDecoder().decode(Student.self, from: data)
            
        return student
    }
    
    // Add a course to the student's courses array
    func addStudentCourse(courseId: Int) async throws {

        let studentId = 1

        guard let url = URL(string: "\(baseURL)/student/\(studentId)/courses/\(courseId)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Calls API response checking
        try handleErrorResponse(data: data, response: response)
    }
    
    // Remove a course from the student's courses array
    func deleteStudentCourse(courseId: Int) async throws {
        
        let studentId = 1
        
        guard let url = URL(string: "\(baseURL)/student/\(studentId)/courses/\(courseId)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let(data, response) = try await URLSession.shared.data(for: request)
        
        // Calls API response checking
        try handleErrorResponse(data: data, response: response)
    }
    
    // Add event to the student's event array
    func addStudentEvent(eventId: Int) async throws {
        
        let studentId = 1
        
        guard let url = URL(string: "\(baseURL)/student/\(studentId)/events/\(eventId)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let(data, response) = try await URLSession.shared.data(for: request)
        
        // Calls API response checking
        try handleErrorResponse(data: data, response: response)
    }

    // Remove event from the student's event array
    func deleteStudentEvent(eventId: Int) async throws {
        
        let studentId = 1
        
        guard let url = URL(string: "\(baseURL)/student/\(studentId)/events/\(eventId)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let(data, response) = try await URLSession.shared.data(for: request)
        
        // Calls API response checking
        try handleErrorResponse(data: data, response: response)
    }
}
