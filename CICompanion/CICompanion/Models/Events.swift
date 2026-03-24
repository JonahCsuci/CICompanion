//
//  Events.swift
//  CICompanion
//
//  Created by Wummiez on 3/7/26.
//

import Foundation

struct Event: Codable, Identifiable {
    let id: Int
    let eventDay: String
    let eventDate: String
    let eventTime: String
    let eventTitle: String
    let eventDescription: String
}
