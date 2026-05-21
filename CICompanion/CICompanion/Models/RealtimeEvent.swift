//
//  RealtimeEvent.swift
//  CICompanion
//

import Foundation
import Combine

enum RealtimeEvent {
    case newMessage(conversationId: Int, message: Message)
    case contactRequestChanged(ContactRequestChange)
    case unknown(type: String?)

    static func decode(from data: Data) -> RealtimeEvent {
        let decoder = JSONDecoder()
        guard let envelope = try? decoder.decode(RealtimeEnvelope.self, from: data) else {
            return .unknown(type: nil)
        }

        switch envelope.type {
        case "new_message":
            guard let payload = try? decoder.decode(NewMessagePayload.self, from: data) else {
                return .unknown(type: envelope.type)
            }
            return .newMessage(conversationId: payload.conversationId, message: payload.message)

        case "contact_request_changed":
            guard let change = try? decoder.decode(ContactRequestChange.self, from: data) else {
                return .unknown(type: envelope.type)
            }
            return .contactRequestChanged(change)

        default:
            return .unknown(type: envelope.type)
        }
    }
}

struct ContactRequestChange: Decodable {
    let type: String
    let action: String
    let requestId: Int
    let status: String
    let requesterId: String
    let recipientId: String
    let conversationId: Int?
    let shouldRefreshContactRequests: Bool
    let shouldRefreshContacts: Bool
    let shouldRefreshConversations: Bool
}

// Switch on this for known actions; unrecognized values fall through to a default
// case so future server actions don't crash the client.
enum KnownRealtimeAction: String {
    case created
    case autoAccepted = "auto_accepted"
    case accepted
    case declined
    case canceled
}

private struct RealtimeEnvelope: Decodable {
    let type: String?
}

private struct NewMessagePayload: Decodable {
    let conversationId: Int
    let message: Message
}
