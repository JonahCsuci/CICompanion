//
//  Conversation.swift
//  CICompanion
//

import Foundation

struct Participant: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let email: String
}

struct Conversation: Codable, Identifiable, Hashable {
    let id: Int
    let conversationType: String
    let participantIds: [String]
    let otherParticipant: Participant
    let lastMessagePreview: String?
    let lastMessageAt: String?
    let createdAt: String
}
