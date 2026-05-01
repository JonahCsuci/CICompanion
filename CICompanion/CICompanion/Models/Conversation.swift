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

    init(id: String, name: String, email: String, joinedAt: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.joinedAt = joinedAt
    }
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

    init(
        id: Int,
        conversationType: String,
        participantIds: [String],
        otherParticipant: Participant? = nil,
        groupName: String? = nil,
        adminStudentId: String? = nil,
        participants: [Participant]? = nil,
        unreadCount: Int? = nil,
        lastMessagePreview: String? = nil,
        lastMessage: ConversationLastMessage? = nil,
        lastMessageAt: String? = nil,
        createdAt: String,
        archivedAt: String? = nil
    ) {
        self.id = id
        self.conversationType = conversationType
        self.participantIds = participantIds
        self.otherParticipant = otherParticipant
        self.groupName = groupName
        self.adminStudentId = adminStudentId
        self.participants = participants
        self.unreadCount = unreadCount
        self.lastMessagePreview = lastMessagePreview
        self.lastMessage = lastMessage
        self.lastMessageAt = lastMessageAt
        self.createdAt = createdAt
        self.archivedAt = archivedAt
    }
}

extension Conversation {
    var isGroup: Bool { conversationType == "group" }

    var displayTitle: String {
        if isGroup {
            if let groupName, !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return groupName
            }
            return "Group Chat"
        }
        return otherParticipant?.name ?? "Conversation"
    }

    var isDirectConversation: Bool {
        conversationType == "direct"
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
