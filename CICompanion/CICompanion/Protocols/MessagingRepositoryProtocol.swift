//
//  MessagingRepositoryProtocol.swift
//  CICompanion
//

import Foundation

protocol MessagingRepositoryProtocol {
    func loadAllStudents() async throws -> [Participant]
    func loadContact(studentId: String) async throws -> Student
    func loadConversations() async throws -> [Conversation]
    func createOrGetDirectConversation(otherStudentId: String) async throws -> Conversation
    func loadMessages(conversationId: Int) async throws -> ConversationDetail
    func sendMessage(conversationId: Int, body: String) async throws -> Message
    func editMeetup(messageId: Int, body: String) async throws
    func loadMeetup(messageId: Int) async throws -> Message

    func createGroupConversation(groupName: String, memberIds: [String], firstMessageBody: String) async throws -> Conversation
    func addGroupParticipant(conversationId: Int, memberId: String) async throws
    func removeGroupParticipant(conversationId: Int, memberId: String) async throws
    func leaveGroup(conversationId: Int) async throws
    func renameGroup(conversationId: Int, groupName: String) async throws
    func markDelivered(conversationId: Int) async throws
    func markRead(conversationId: Int) async throws
}
