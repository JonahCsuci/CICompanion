//
//  ContactRequestModelTests.swift
//  CICompanionTests
//

import XCTest
@testable import CICompanion

final class ContactRequestModelTests: XCTestCase {

    private let decoder = JSONDecoder()

    // Sample of the 201 pending body returned by `lambda_add_contact.py`.
    func testDecodesPendingResponse() throws {
        let json = #"""
        {
          "success": true,
          "status": "pending",
          "requestId": 12,
          "contactStudentId": "abc-123"
        }
        """#.data(using: .utf8)!

        let response = try decoder.decode(SendContactRequestResponse.self, from: json)

        XCTAssertEqual(response.status, "pending")
        XCTAssertEqual(response.requestId, 12)
        XCTAssertEqual(response.contactStudentId, "abc-123")
        XCTAssertNil(response.autoAccepted)
        XCTAssertNil(response.conversationId)
    }

    // Sample of the 200 auto-accept body returned by `lambda_add_contact.py`
    // when the other student already had a pending request out.
    func testDecodesAutoAcceptedResponse() throws {
        let json = #"""
        {
          "success": true,
          "status": "accepted",
          "autoAccepted": true,
          "requestId": 12,
          "contactStudentId": "abc-123",
          "conversationId": 34
        }
        """#.data(using: .utf8)!

        let response = try decoder.decode(SendContactRequestResponse.self, from: json)

        XCTAssertEqual(response.status, "accepted")
        XCTAssertEqual(response.autoAccepted, true)
        XCTAssertEqual(response.conversationId, 34)
    }

    // Verbatim shape from `lambda_list_contact_requests.py` — empty lists with counts.
    func testDecodesListResponseWithEmptyArrays() throws {
        let json = #"""
        {
          "success": true,
          "studentId": "abc",
          "statusFilter": "pending",
          "directionFilter": "all",
          "incoming": [],
          "outgoing": [],
          "counts": {
            "incomingPending": 0,
            "outgoingPending": 0,
            "totalPending": 0
          }
        }
        """#.data(using: .utf8)!

        let response = try decoder.decode(ContactRequestListResponse.self, from: json)

        XCTAssertTrue(response.incoming.isEmpty)
        XCTAssertTrue(response.outgoing.isEmpty)
        XCTAssertEqual(response.counts?.totalPending, 0)
    }

    // Per-item shape projected by the list lambda: camelCase keys, nested
    // requester / recipient / otherStudent objects, and a per-row direction.
    func testDecodesContactRequestListItem() throws {
        let json = #"""
        {
          "requestId": 7,
          "requesterId": "user-A",
          "recipientId": "user-B",
          "status": "pending",
          "direction": "incoming",
          "createdAt": "2026-05-05T10:00:00Z",
          "updatedAt": "2026-05-05T10:00:00Z",
          "respondedAt": null,
          "otherStudent": {
            "id": "user-A",
            "name": "Alice",
            "email": "alice@myci.csuci.edu"
          },
          "requester": {
            "id": "user-A",
            "name": "Alice",
            "email": "alice@myci.csuci.edu"
          },
          "recipient": {
            "id": "user-B",
            "name": "Bob",
            "email": "bob@myci.csuci.edu"
          }
        }
        """#.data(using: .utf8)!

        let request = try decoder.decode(ContactRequest.self, from: json)

        XCTAssertEqual(request.requestId, 7)
        XCTAssertEqual(request.id, 7) // Identifiable mirrors requestId.
        XCTAssertEqual(request.requesterId, "user-A")
        XCTAssertEqual(request.recipientId, "user-B")
        XCTAssertEqual(request.status, "pending")
        XCTAssertEqual(request.direction, "incoming")
        XCTAssertEqual(request.otherStudent?.name, "Alice")
        XCTAssertEqual(request.requester?.email, "alice@myci.csuci.edu")
        XCTAssertEqual(request.recipient?.id, "user-B")
        XCTAssertNil(request.respondedAt)
    }

    // Verbatim shape from `lambda_update_contact_request.py` — accept response.
    func testDecodesAcceptActionResponse() throws {
        let json = #"""
        {
          "success": true,
          "action": "accept",
          "status": "accepted",
          "requestId": 12,
          "requesterId": "user-A",
          "recipientId": "user-B",
          "contactStudentId": "user-A",
          "conversationId": 34
        }
        """#.data(using: .utf8)!

        let action = try decoder.decode(ContactRequestActionResponse.self, from: json)

        XCTAssertEqual(action.action, "accept")
        XCTAssertEqual(action.status, "accepted")
        XCTAssertEqual(action.conversationId, 34)
        XCTAssertEqual(action.contactStudentId, "user-A")
    }

    // Verbatim shape from `lambda_update_contact_request.py` — decline / cancel responses.
    // Both omit conversationId and contactStudentId (no conversation is created).
    func testDecodesDeclineActionResponse() throws {
        let json = #"""
        {
          "success": true,
          "action": "decline",
          "status": "declined",
          "requestId": 12,
          "requesterId": "user-A",
          "recipientId": "user-B"
        }
        """#.data(using: .utf8)!

        let action = try decoder.decode(ContactRequestActionResponse.self, from: json)

        XCTAssertEqual(action.action, "decline")
        XCTAssertEqual(action.status, "declined")
        XCTAssertNil(action.conversationId)
        XCTAssertNil(action.contactStudentId)
    }

    // Verbatim shape from `lambda_hide_direct_conversation.py`.
    func testDecodesHideConversationResponse() throws {
        let json = #"""
        {
          "success": true,
          "message": "Direct conversation hidden for current user",
          "conversationId": 34,
          "studentId": "user-A",
          "hiddenReason": "user_deleted"
        }
        """#.data(using: .utf8)!

        let response = try decoder.decode(HideConversationResponse.self, from: json)

        XCTAssertEqual(response.success, true)
        XCTAssertEqual(response.conversationId, 34)
        XCTAssertEqual(response.hiddenReason, "user_deleted")
    }

    func testDecodesNewMessageRealtimeEvent() {
        let json = #"""
        {
          "type": "new_message",
          "conversationId": 123,
          "message": {
            "id": 456,
            "conversationId": 123,
            "senderId": "sender-1",
            "senderName": "Sender",
            "body": "hello",
            "createdAt": "2026-05-05T12:00:00Z"
          }
        }
        """#.data(using: .utf8)!

        let event = RealtimeEvent.decode(from: json)

        guard case let .newMessage(conversationId, message) = event else {
            XCTFail("Expected .newMessage; got \(event)")
            return
        }
        XCTAssertEqual(conversationId, 123)
        XCTAssertEqual(message.id, 456)
        XCTAssertEqual(message.body, "hello")
    }

    func testDecodesContactRequestChangedRealtimeEvent() {
        let json = #"""
        {
          "type": "contact_request_changed",
          "action": "accepted",
          "requestId": 12,
          "status": "accepted",
          "requesterId": "user-A",
          "recipientId": "user-B",
          "conversationId": 34,
          "shouldRefreshContactRequests": true,
          "shouldRefreshContacts": true,
          "shouldRefreshConversations": true
        }
        """#.data(using: .utf8)!

        let event = RealtimeEvent.decode(from: json)

        guard case let .contactRequestChanged(change) = event else {
            XCTFail("Expected .contactRequestChanged; got \(event)")
            return
        }
        XCTAssertEqual(change.action, "accepted")
        XCTAssertEqual(change.requestId, 12)
        XCTAssertEqual(change.conversationId, 34)
        XCTAssertTrue(change.shouldRefreshContacts)
    }

    // Auto-accept WebSocket payload from `lambda_add_contact.py` — uses
    // action="auto_accepted" and status="accepted".
    func testDecodesAutoAcceptedRealtimeEvent() {
        let json = #"""
        {
          "type": "contact_request_changed",
          "action": "auto_accepted",
          "requestId": 12,
          "status": "accepted",
          "requesterId": "user-A",
          "recipientId": "user-B",
          "conversationId": 34,
          "shouldRefreshContactRequests": true,
          "shouldRefreshContacts": true,
          "shouldRefreshConversations": true
        }
        """#.data(using: .utf8)!

        let event = RealtimeEvent.decode(from: json)

        guard case let .contactRequestChanged(change) = event else {
            XCTFail("Expected .contactRequestChanged; got \(event)")
            return
        }
        XCTAssertEqual(change.action, "auto_accepted")
        XCTAssertEqual(KnownRealtimeAction(rawValue: change.action), .autoAccepted)
    }

    func testUnknownRealtimeTypeYieldsUnknownCase() {
        let json = #"""
        {"type": "future_event_type", "foo": "bar"}
        """#.data(using: .utf8)!

        let event = RealtimeEvent.decode(from: json)

        guard case let .unknown(type) = event else {
            XCTFail("Expected .unknown; got \(event)")
            return
        }
        XCTAssertEqual(type, "future_event_type")
    }
}
