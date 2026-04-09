//
//  ContactStudent.swift
//  CICompanion
//

import Foundation

struct ContactStudent: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let email: String
}
