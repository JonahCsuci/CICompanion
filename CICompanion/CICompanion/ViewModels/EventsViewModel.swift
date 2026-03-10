//
//  EventsViewModel.swift
//  CICompanion
//
//  Created by Wummiez on 3/6/26.
//

import Foundation
import Combine

class EventsViewModel: ObservableObject {

    @Published var events: [Event] = []

    // eventsRepository methods fetch all events or student enrolled events
    let eventsRepository: EventsRepositoryProtocol
    
    // studentRepository methods let you update student enrolled events
    let studentRepository: StudentRepositoryProtocol
    
    // NOTE: if you update a student's events, call a load method after
    // to receive the newly updated student data
        
    init(
        eventsRepository: EventsRepositoryProtocol,
        studentRepository: StudentRepositoryProtocol
    ) {
        self.eventsRepository = eventsRepository
        self.studentRepository = studentRepository
    }

    func loadAllEvents() {
        Task {
            do {
                events = try await eventsRepository.loadAllEvents()
            } catch {
                print("Error loading events:", error)
            }
        }
    }
}
