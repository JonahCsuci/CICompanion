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
    // Set only on image messages; imageURL is a short-lived presigned GET URL.
    let imageKey: String?
    let imageURL: String?

    init(
        id: Int,
        conversationId: Int,
        senderId: String,
        senderName: String?,
        body: String,
        createdAt: String,
        deliveryStatus: String? = nil,
        readBy: [MessageReader]? = nil,
        imageKey: String? = nil,
        imageURL: String? = nil
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.senderName = senderName
        self.body = body
        self.createdAt = createdAt
        self.deliveryStatus = deliveryStatus
        self.readBy = readBy
        self.imageKey = imageKey
        self.imageURL = imageURL
    }
}

struct ConversationDetail: Codable {
    let conversation: Conversation
    let messages: [Message]
}
