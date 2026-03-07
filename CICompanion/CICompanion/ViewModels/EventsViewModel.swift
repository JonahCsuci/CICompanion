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

        do {
            events = try repository.loadEvents()
        } catch {
            print("Error loading events:", error)
        }

    }
}
