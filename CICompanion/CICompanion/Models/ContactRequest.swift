//
//  ContactRequest.swift
//  CICompanion
//

import Foundation

// Per-item shape returned by `GET /student/{id}/contact-requests` and used as the
// canonical contact-request DTO inside the iOS layer. Keys mirror the
// `lambda_list_contact_requests.py` projection (camelCase; nested
// `requester` / `recipient` / `otherStudent` objects rather than flat fields).
struct ContactRequest: Codable, Identifiable, Hashable {
    let requestId: Int
    let requesterId: String
    let recipientId: String
    let status: String
    let direction: String?
    let createdAt: String
    let updatedAt: String?
    let respondedAt: String?
    let otherStudent: StudentSummary?
    let requester: StudentSummary?
    let recipient: StudentSummary?

    var id: Int { requestId }
}

struct StudentSummary: Codable, Hashable {
    let id: String?
    let name: String?
    let email: String?
}

// Switch on this enum to handle known statuses safely; unrecognized values
// (added later server-side) simply fall through to a default case so a future
// status never crashes the client.
enum KnownContactRequestStatus: String {
    case pending
    case accepted
    case declined
    case canceled
}

enum KnownContactRequestDirection: String {
    case incoming
    case outgoing
}

struct ContactRequestListResponse: Codable {
    let success: Bool?
    let studentId: String?
    let statusFilter: String?
    let directionFilter: String?
    let incoming: [ContactRequest]
    let outgoing: [ContactRequest]
    let counts: Counts?

    struct Counts: Codable {
        let incomingPending: Int
        let outgoingPending: Int
        let totalPending: Int
    }
}

struct SendContactRequestResponse: Codable {
    let success: Bool?
    let status: String
    let autoAccepted: Bool?
    let requestId: Int?
    let contactStudentId: String?
    let conversationId: Int?
}

struct ContactRequestActionResponse: Codable {
    let success: Bool?
    let action: String?
    let status: String?
    let requestId: Int?
    let requesterId: String?
    let recipientId: String?
    let contactStudentId: String?
    let conversationId: Int?
}

struct HideConversationResponse: Codable {
    let success: Bool?
    let message: String?
    let conversationId: Int?
    let studentId: String?
    let hiddenReason: String?
}
