//
//  MeetingSearchResult.swift
//  CICompanion
//

import Foundation

struct MeetingSearchResult: Codable, Identifiable, Hashable {
    let messageId: Int
    let conversation: Conversation
    let meetingSchedulerId: String?
    let title: String
    let createdAt: String

    var id: Int { messageId }
}

struct MeetingSearchResultsResponse: Codable {
    let meetings: [MeetingSearchResult]
}

enum MessageSearchResult: Identifiable, Hashable {
    case conversation(Conversation)
    case meeting(MeetingSearchResult)

    var id: String {
        switch self {
        case .conversation(let conversation):
            return "conversation-\(conversation.id)"
        case .meeting(let meeting):
            return "meeting-\(meeting.messageId)"
        }
    }
}
