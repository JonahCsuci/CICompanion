//
//  Event.swift
//  CICompanion
//
//  Created by Emma on 5/14/26.
//

import Combine

struct Event: Codable, Hashable {
    let name : String
    let description : String
    let location : String
    let timeRange : TimeRange
}
