//
//  Message.swift
//  CICompanion
//

import Foundation

// One reader entry under a group message — distinct from Participant (no email).
struct MessageReader: Codable, Hashable, Identifiable {
    let studentId: String
    let name: String

    var id: String { studentId }
}

struct Message: Codable, Identifiable {
    let id: Int
    let conversationId: Int
    let senderId: String
    let senderName: String?
    let body: String
    let createdAt: String
    // Direct chats only, sender's own messages only: "sent" | "delivered" | "seen".
    // For an own outgoing message that has no recipient receipt yet, the API returns null
    // and the UI treats null + own-message as "Sent".
    let deliveryStatus: String?
    // Group chats: list of readers excluding the sender. Null on a brand-new outgoing message.
    let readBy: [MessageReader]?
}

struct ConversationDetail: Codable {
    let conversation: Conversation
    let messages: [Message]
}
