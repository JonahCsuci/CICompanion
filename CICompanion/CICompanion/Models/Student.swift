//
//  Student.swift
//  CICompanion
//
//  Created by Wummiez on 3/6/26.
//

import Foundation

struct Student: Codable, Identifiable {
    let id: Int
    let name: String
    let email: String
    var courses: [Int]
    var events: [Int]
}
