//
//  ContactStudentTests.swift
//  CICompanionTests
//

import XCTest
@testable import CICompanion

final class ContactStudentTests: XCTestCase {

    func testDecodesContactStudentSummary() throws {
        let data = Data("""
        {
          "id": "b9d959de-9091-70c6-dc3b-cd0519f3a0c9",
          "name": "Sergio",
          "email": "sergio.macias207@myci.csuci.edu"
        }
        """.utf8)

        let contact = try JSONDecoder().decode(ContactStudent.self, from: data)

        XCTAssertEqual(contact.id, "b9d959de-9091-70c6-dc3b-cd0519f3a0c9")
        XCTAssertEqual(contact.name, "Sergio")
        XCTAssertEqual(contact.email, "sergio.macias207@myci.csuci.edu")
    }

    func testDecodesConversationSearchResultsUsingConversationModel() throws {
        let data = Data("""
        [
          {
            "id": 45,
            "conversationType": "direct",
            "participantIds": [
              "1909f9ee-b061-701e-1dc8-8453d8754204",
              "b9d959de-9091-70c6-dc3b-cd0519f3a0c9"
            ],
            "otherParticipant": {
              "id": "b9d959de-9091-70c6-dc3b-cd0519f3a0c9",
              "name": "Sergio",
              "email": "sergio.macias207@myci.csuci.edu"
            },
            "groupName": null,
            "lastMessagePreview": "biology final tomorrow at 3",
            "lastMessageAt": "2026-04-21T18:14:00Z",
            "createdAt": "2026-04-01T12:00:00Z"
          }
        ]
        """.utf8)

        let conversations = try JSONDecoder().decode([Conversation].self, from: data)

        XCTAssertEqual(conversations.count, 1)
        XCTAssertEqual(conversations[0].id, 45)
        XCTAssertEqual(conversations[0].otherParticipant?.name, "Sergio")
        XCTAssertEqual(conversations[0].displayTitle, "Sergio")
        XCTAssertEqual(conversations[0].lastMessagePreview, "biology final tomorrow at 3")
        XCTAssertEqual(conversations[0].lastMessageAt, "2026-04-21T18:14:00Z")
    }

    func testDecodesWrappedConversationsPayloadUsingConversationModel() throws {
        let data = Data("""
        {
          "conversations": [
            {
              "id": 34,
              "conversationType": "direct",
              "participantIds": [
                "39a9094e-a051-708c-6ca1-6ae3fc53f622",
                "69f9292e-a0a1-7097-8e33-5f604ada3c03"
              ],
              "otherParticipant": {
                "id": "69f9292e-a0a1-7097-8e33-5f604ada3c03",
                "name": "Emma",
                "email": "emma.schwartz515@myci.csuci.edu",
                "joinedAt": "2026-04-21T23:33:24Z"
              },
              "lastMessagePreview": "Bless up",
              "lastMessageAt": "2026-04-21T23:33:34Z",
              "createdAt": "2026-04-21T23:33:24Z"
            }
          ]
        }
        """.utf8)

        struct ConversationsEnvelope: Decodable {
            let conversations: [Conversation]
        }

        let payload = try JSONDecoder().decode(ConversationsEnvelope.self, from: data)

        XCTAssertEqual(payload.conversations.count, 1)
        XCTAssertEqual(payload.conversations[0].otherParticipant?.name, "Emma")
        XCTAssertEqual(payload.conversations[0].lastMessagePreview, "Bless up")
    }

    func testDecodesGroupConversationSearchResultsUsingConversationModel() throws {
        let data = Data("""
        [
          {
            "id": 45,
            "conversationType": "group",
            "participantIds": [
              "1909f9ee-b061-701e-1dc8-8453d8754204",
              "b9d959de-9091-70c6-dc3b-cd0519f3a0c9",
              "d9e9d9be-b021-703b-62f8-f1eef1eb72a2"
            ],
            "otherParticipant": null,
            "groupName": "Study Group",
            "lastMessagePreview": "biology final tomorrow at 3",
            "lastMessageAt": "2026-04-21T18:14:00Z",
            "createdAt": "2026-04-01T12:00:00Z"
          }
        ]
        """.utf8)

        let conversations = try JSONDecoder().decode([Conversation].self, from: data)

        XCTAssertEqual(conversations.count, 1)
        XCTAssertEqual(conversations[0].id, 45)
        XCTAssertNil(conversations[0].otherParticipant)
        XCTAssertEqual(conversations[0].groupName, "Study Group")
        XCTAssertEqual(conversations[0].displayTitle, "Study Group")
        XCTAssertEqual(conversations[0].lastMessagePreview, "biology final tomorrow at 3")
        XCTAssertEqual(conversations[0].lastMessageAt, "2026-04-21T18:14:00Z")
    }

    func testGroupConversationDisplayTitleFallsBackWhenNameIsMissing() throws {
        let data = Data("""
        {
          "id": 46,
          "conversationType": "group",
          "participantIds": [
            "1909f9ee-b061-701e-1dc8-8453d8754204",
            "b9d959de-9091-70c6-dc3b-cd0519f3a0c9"
          ],
          "otherParticipant": null,
          "groupName": "   ",
          "lastMessagePreview": "hello group",
          "lastMessageAt": "2026-04-21T18:14:00Z",
          "createdAt": "2026-04-01T12:00:00Z"
        }
        """.utf8)

        let conversation = try JSONDecoder().decode(Conversation.self, from: data)

        XCTAssertEqual(conversation.displayTitle, "Group Chat")
    }
}
