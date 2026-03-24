//
//  APIStudentRepository.swift
//  CICompanion
//
//  Created by Wummiez on 3/9/26.
//

import Foundation


class APIStudentRepository: StudentRepositoryProtocol {
    let baseURL = "https://ibxw69g864.execute-api.us-west-1.amazonaws.com"
    
    func loadStudent() async throws -> Student {
        
        // Temporary hardcoded student ID (will be dynamic later)
        let studentId = 1
        
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
            
        return student
    }
    
    func addStudentCourse(courseId: Int) async throws {

        // Temporary hardcoded student ID (will be dynamic later)
        let studentId = 1

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
    }
    
    func deleteStudentCourse(courseId: Int) async throws {
        
        // Temporary hardcoded student ID (will be dynamic later)
        let studentId = 1
        
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
    }
    
    // Checks if student has course
    func hasStudentCourse(courseId: Int) async throws -> Bool {
        return true
    }
    
    // Add event to the student's event array
    func addStudentEvent(eventId: Int) async throws {
        
        // Temporary hardcoded student ID (will be dynamic later)
        let studentId = 1
        
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
    }

    func deleteStudentEvent(eventId: Int) async throws {
        
        // Temporary hardcoded student ID (will be dynamic later)
        let studentId = 1
        
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
    }
}
