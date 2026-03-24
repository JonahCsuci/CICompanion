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
    
    private var cachedEvents: [Event]?
    
    func loadAllEvents() async throws -> [Event] {
        
        // If events were previously loaded, return
        if let cachedEvents {
            return cachedEvents
        }
        
        let baseURL = "https://ibxw69g864.execute-api.us-west-1.amazonaws.com"
        // Create URL
        guard let url = URL(string: "\(baseURL)/events") else {
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
        
        // Decode JSON into Events structs
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
