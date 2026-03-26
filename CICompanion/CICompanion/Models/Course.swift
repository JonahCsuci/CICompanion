//
//  Course.swift
//  CICompanion
//
//  Created by Wummiez on 3/6/26.
//

import Foundation

struct Course: Codable, Identifiable, Equatable {
    let id: Int
    let courseName: String
    let courseCode: String
    let instructor: String
    let location: String
    let startTime: String
    let endTime: String
    let days: [String]
    let isAsynchronous: Bool
    let courseDescription: String
}
