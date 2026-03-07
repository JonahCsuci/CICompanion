//
//  EventsRepository.swift
//  CICompanion
//
//  Created by Wummiez on 3/6/26.
//

import Foundation

protocol EventsRepositoryProtocol {
    func loadEvents() throws -> [Event]
}

class EventsRepository: EventsRepositoryProtocol {

    func loadEvents() throws -> [Event] {

        let url = Bundle.main.url(forResource: "events", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let events = try JSONDecoder().decode([Event].self, from: data)

        return events
    }
}
