//
//  APIStudentRepository.swift
//  CICompanion
//
//  Created by Wummiez on 3/9/26.
//

import Foundation


class APIStudentRepository: StudentRepositoryProtocol {
    
    // Stored student in memory
    private var student: Student?
    private let sessionManager: SessionManager
    
    let baseURL = "https://ibxw69g864.execute-api.us-west-1.amazonaws.com"
    
    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }
    
    func loadStudent() async throws -> Student {
        
        // If student previously loaded, immediately return
        if let student {
            return student
        }
        
        guard let studentId = sessionManager.userId else {
            throw URLError(.userAuthenticationRequired)
        }
        
        // Build API endpoint for fetching all of current student's info
        guard let url = URL(string: "\(baseURL)/student/\(studentId)") else {
            throw URLError(.badURL)
        }
            
        var request = URLRequest(url: url)
        
        // Use GET to retrieve student info from backend
        request.httpMethod = "GET"
        
        // Send request to backend (API Gateway -> Lambda -> database)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Validate HTTP response and throw error if request failed
        try handleErrorResponse(data: data, response: response)

        // Decode JSON into Student struct
        let student = try JSONDecoder().decode(Student.self, from: data)
        
        self.student = student
        
        return student
    }
    
    func addStudentCourse(courseId: Int) async throws {
        
        guard let studentId = sessionManager.userId else {
            throw URLError(.userAuthenticationRequired)
        }
        
        // Build API endpoint to add a course for a student
        guard let url = URL(string: "\(baseURL)/student/\(studentId)/courses/\(courseId)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        
        // Use POST to add a course to the student's enrolled courses
        request.httpMethod = "POST"
        
        // Send request to backend (API Gateway -> Lambda -> database)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Validate HTTP response and throw error if request failed
        try handleErrorResponse(data: data, response: response)
        
        // Add course to cached student
        if var student = student {
            if !student.courses.contains(courseId) {
                student.courses.append(courseId)
            }
            self.student = student
        }
    }
    
    func deleteStudentCourse(courseId: Int) async throws {
        
        guard let studentId = sessionManager.userId else {
            throw URLError(.userAuthenticationRequired)
        }
        
        // Build API endpoint to delete a course for a student
        guard let url = URL(string: "\(baseURL)/student/\(studentId)/courses/\(courseId)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        
        // Use DELETE to remove a course from the student's enrolled courses
        request.httpMethod = "DELETE"
        
        // Send request to backend (API Gateway -> Lambda -> database)
        let(data, response) = try await URLSession.shared.data(for: request)
        
        // Validate HTTP response and throw error if request failed
        try handleErrorResponse(data: data, response: response)
        
        // Remove course from cached student
        if var student = student {
            student.courses.removeAll { $0 == courseId }
            self.student = student
        }
    }
    
    
    // Add event to the student's event array
    func addStudentEvent(eventId: Int) async throws {
        
        guard let studentId = sessionManager.userId else {
            throw URLError(.userAuthenticationRequired)
        }
        
        // Build API endpoint to add an event for a student
        guard let url = URL(string: "\(baseURL)/student/\(studentId)/events/\(eventId)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        
        // Use POST to add an event to the student's enrolled events
        request.httpMethod = "POST"
        
        // Send request to backend (API Gateway -> Lambda -> database)
        let(data, response) = try await URLSession.shared.data(for: request)
        
        // Validate HTTP response and throw error if request failed
        try handleErrorResponse(data: data, response: response)
        
        // Add event to cached student
        if var student = student {
            if !student.events.contains(eventId) {
                student.events.append(eventId)
            }
            self.student = student
        }
    }

    func deleteStudentEvent(eventId: Int) async throws {
        
        guard let studentId = sessionManager.userId else {
            throw URLError(.userAuthenticationRequired)
        }
        
        // Build API endpoint to delete an event for a student
        guard let url = URL(string: "\(baseURL)/student/\(studentId)/events/\(eventId)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        
        // Use DELETE to remove an event from the student's enrolled events
        request.httpMethod = "DELETE"
        
        // Send request to backend (API Gateway -> Lambda -> database)
        let(data, response) = try await URLSession.shared.data(for: request)
        
        // Validate HTTP response and throw error if request failed
        try handleErrorResponse(data: data, response: response)
        
        // Remove event from cached student
        if var student = student {
            student.events.removeAll { $0 == eventId }
            self.student = student
        }
    }
    
    func ensureStudentExists() async throws -> Student {
            
        // Authenticates user exists in user pool
        guard let studentId = sessionManager.userId else {
            throw URLError(.userAuthenticationRequired)
        }
            
        let name = sessionManager.name ?? "User"

        guard let email = sessionManager.email, !email.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }
            
        guard let url = URL(string: "\(baseURL)/student/\(studentId)") else {
            throw URLError(.badURL)
        }
            
        // Checks if exists in database
        // If doesn't exist yet, creates and returns student from DB
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
        let body: [String: String] = [
            "name": name,
            "email": email
            ]
            
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
            
        try handleErrorResponse(data: data, response: response)
            
        let student = try JSONDecoder().decode(Student.self, from: data)
        self.student = student
            
        return student
        
    }
}
