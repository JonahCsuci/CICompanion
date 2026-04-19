//
//  Conversation.swift
//  CICompanion
//

import Foundation

struct Participant: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let email: String
    let joinedAt: String?
}

struct Conversation: Codable, Identifiable, Hashable {
    let id: Int
    let conversationType: String
    let participantIds: [String]
    let otherParticipant: Participant?
    let groupName: String?
    let adminStudentId: String?
    let participants: [Participant]?
    let lastMessagePreview: String?
    let lastMessageAt: String?
    let createdAt: String
    let archivedAt: String?
    let unreadCount: Int?

    var displayTitle: String {
        if let groupName = groupName {
            return groupName
        }
        return otherParticipant?.name ?? "Unknown"
    }

    var isGroup: Bool {
        conversationType == "group"
    }
}
