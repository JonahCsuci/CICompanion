//
//  EventsRepository.swift
//  CICompanion
//
//  Created by Wummiez on 3/6/26.
//

import Foundation

class EventsRepository: EventsRepositoryProtocol {

    let studentRepository: StudentRepositoryProtocol
    
    init(studentRepository: StudentRepositoryProtocol) {
        self.studentRepository = studentRepository
    }
    
    func loadAllEvents() async throws -> [Event] {
        let url = Bundle.main.url(forResource: "events", withExtension: "json")!
        let data = try Data(contentsOf: url)
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
