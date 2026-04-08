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
}
