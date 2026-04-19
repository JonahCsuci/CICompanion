//
//  MessagingRepositoryProtocol.swift
//  CICompanion
//

import Foundation

protocol MessagingRepositoryProtocol {
    func loadContact(studentId: String) async throws -> Student
    func loadConversations() async throws -> [Conversation]
    func createOrGetDirectConversation(otherStudentId: String) async throws -> Conversation
    func createGroupConversation(groupName: String, memberIds: [String], firstMessageBody: String) async throws -> Conversation
    func loadMessages(conversationId: Int) async throws -> ConversationDetail
    func sendMessage(conversationId: Int, body: String) async throws -> Message
    func addParticipant(conversationId: Int, memberId: String) async throws
    func removeParticipant(conversationId: Int, memberId: String) async throws
    func leaveGroup(conversationId: Int) async throws -> LeaveGroupResult
    func renameGroup(conversationId: Int, groupName: String) async throws
    func markRead(conversationId: Int) async throws
    func editMeetup(messageId: Int, body: String) async throws
    func loadMeetup(messageId: Int) async throws -> Message
}
