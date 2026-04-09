//
//  Message.swift
//  CICompanion
//

import Foundation

struct Message: Codable, Identifiable {
    let id: Int
    let conversationId: Int
    let senderId: String
    let senderName: String?
    let body: String
    let createdAt: String
}

struct ConversationDetail: Codable {
    let conversation: Conversation
    let messages: [Message]
}
