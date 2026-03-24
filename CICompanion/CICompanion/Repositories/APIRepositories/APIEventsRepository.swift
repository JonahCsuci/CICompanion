//
//  ApiEventsRepository.swift
//  CICompanion
//
//  Created by Wummiez on 3/7/26.
//

import Foundation

class APIEventsRepository: EventsRepositoryProtocol {
    
    let studentRepository: StudentRepositoryProtocol
    
    init(studentRepository: StudentRepositoryProtocol) {
        self.studentRepository = studentRepository
    }
    
    let baseURL = "https://ibxw69g864.execute-api.us-west-1.amazonaws.com"
    
    private var cachedEvents: [Event]?
    
    func loadAllEvents() async throws -> [Event] {
        
        // Return cached events if already loaded
        if let cachedEvents {
            return cachedEvents
        }
        
        // Build API endpoint for fetching all events
        guard let url = URL(string: "\(baseURL)/events") else {
            throw URLError(.badURL)
        }
            
        var request = URLRequest(url: url)
        
        // Use GET to retrieve events from backend
        request.httpMethod = "GET"
        
        // Send requesto to backend (API Gateway -> Lambda -> database)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Validate HTTP response and throw error if request failed
        try handleErrorResponse(data: data, response: response)
        
        // Decode JSON into Events struct array
        let events = try JSONDecoder().decode([Event].self, from: data)
            
        return events
    }
    
    func loadStudentEvents() async throws -> [Event] {
        let events = try await loadAllEvents()
        let student = try await studentRepository.loadStudent()
        
        return events.filter {
            student.events.contains($0.id)
        }
    }
    
}
