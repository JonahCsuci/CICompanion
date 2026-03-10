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

    let repository: EventsRepositoryProtocol

    init(repository: EventsRepositoryProtocol) {
        self.repository = repository
    }

    func loadEvents() {
        Task {
            do {
                events = try await repository.loadAllEvents()
            } catch {
                print("Error loading events:", error)
            }
        }
    }
}
