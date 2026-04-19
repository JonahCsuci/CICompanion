//
//  Message.swift
//  CICompanion
//

import Foundation

enum DeliveryStatus: String, Codable, Hashable {
    case sent
    case delivered
    case seen
}

struct MessageReader: Codable, Hashable {
    let studentId: String
    let name: String
}

struct Message: Codable, Identifiable, Hashable {
    let id: Int
    let conversationId: Int
    let senderId: String
    let senderName: String?
    let body: String
    let createdAt: String
    let deliveryStatus: DeliveryStatus?
    let readBy: [MessageReader]?
}

struct ConversationDetail: Codable {
    let conversation: Conversation
    let messages: [Message]
}
