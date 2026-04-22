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

// Skinny snapshot of the most recent message included on the conversation list endpoint.
// It does not carry conversationId / deliveryStatus / readBy — those only appear on full message loads.
struct ConversationLastMessage: Codable, Hashable {
    let id: Int
    let senderId: String
    let senderName: String?
    let body: String
    let createdAt: String?
}

struct Conversation: Codable, Identifiable, Hashable {
    let id: Int
    let conversationType: String
    let participantIds: [String]
    let otherParticipant: Participant?
    let groupName: String?
    let adminStudentId: String?
    let participants: [Participant]?
    let unreadCount: Int?
    let lastMessagePreview: String?
    let lastMessage: ConversationLastMessage?
    let lastMessageAt: String?
    let createdAt: String
    let archivedAt: String?
}

extension Conversation {
    var isGroup: Bool { conversationType == "group" }

    var displayTitle: String {
        if isGroup {
            return groupName ?? "Group"
        }
        return otherParticipant?.name ?? "Conversation"
    }

    func isAdmin(currentUserId: String) -> Bool {
        adminStudentId == currentUserId
    }
}

// Conversation list endpoint returns { conversations: [...] } — bare arrays will not decode.
struct ConversationsResponse: Codable {
    let conversations: [Conversation]
}

// Result of leaving a group. The backend may delete the conversation if the last member left,
// or transfer admin to the oldest remaining participant.
struct LeaveGroupResult: Codable {
    let conversationId: Int
    let leftStudentId: String
    let wasAdmin: Bool
    let newAdminStudentId: String?
    let conversationDeleted: Bool
}
