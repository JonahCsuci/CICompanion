//
//  APIMessagingRepository.swift
//  CICompanion
//

import Foundation

class APIMessagingRepository: MessagingRepositoryProtocol {

    private let sessionManager: SessionManager
    let baseURL = "https://ibxw69g864.execute-api.us-west-1.amazonaws.com"

    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }

    func loadContact(studentId: String) async throws -> Student {
        
        // Build API endpoint for fetching all of current student's info
        guard let url = URL(string: "\(baseURL)/contact/\(studentId)") else {
            throw URLError(.badURL)
        }
            
        var request = URLRequest(url: url)
        
        // Use GET to retrieve student info from backend
        request.httpMethod = "GET"
        
        // Send request to backend (API Gateway -> Lambda -> database)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Validate HTTP response and throw error if request failed
        try handleErrorResponse(data: data, response: response)

        // Decode JSON into Student struct
        let contact = try JSONDecoder().decode(Student.self, from: data)
        
        return contact
    }
    
    func loadConversations() async throws -> [Conversation] {
        let studentId = try authenticatedUserId()

        guard let url = URL(string: "\(baseURL)/student/\(studentId)/conversations") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)
        try handleErrorResponse(data: data, response: response)

        // Backend returns { "conversations": [...] }, not a bare array.
        return try JSONDecoder().decode(ConversationsResponse.self, from: data).conversations
    }

    func createOrGetDirectConversation(otherStudentId: String) async throws -> Conversation {
        let studentId = try authenticatedUserId()

        guard let url = URL(string: "\(baseURL)/student/\(studentId)/conversations/direct") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "otherStudentId": otherStudentId
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        // POST returns 200 for existing conversation, 201 for newly created
        try handleMessagingResponse(data: data, response: response)

        return try JSONDecoder().decode(Conversation.self, from: data)
    }

    func loadMessages(conversationId: Int) async throws -> ConversationDetail {
        let studentId = try authenticatedUserId()

        guard let url = URL(string: "\(baseURL)/student/\(studentId)/conversations/\(conversationId)/messages") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)
        try handleErrorResponse(data: data, response: response)
        
        return try JSONDecoder().decode(ConversationDetail.self, from: data)
    }

    func sendMessage(conversationId: Int, body: String) async throws -> Message {
        let studentId = try authenticatedUserId()

        guard let url = URL(string: "\(baseURL)/student/\(studentId)/conversations/\(conversationId)/messages") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "body": body
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        // POST returns 201 for newly created message
        try handleMessagingResponse(data: data, response: response)

        return try JSONDecoder().decode(Message.self, from: data)
    }

    func editMeetup(messageId: Int, body: String) async throws {
        guard let url = URL(string: "\(baseURL)/meeting/\(messageId)/conversations") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "body": body
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        try handleMessagingResponse(data: data, response: response)
    }
    
    func loadMeetup(messageId: Int) async throws -> Message {
        
        guard let url = URL(string: "\(baseURL)/meeting/\(messageId)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try handleMessagingResponse(data: data, response: response)
        
        return try JSONDecoder().decode(Message.self, from: data)
    }
    
    func createGroupConversation(groupName: String, memberIds: [String], firstMessageBody: String) async throws -> Conversation {
        let studentId = try authenticatedUserId()

        guard let url = URL(string: "\(baseURL)/student/\(studentId)/conversations/group") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "groupName": groupName,
            "memberIds": memberIds,
            "firstMessageBody": firstMessageBody
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        // POST returns 201 for newly created group
        try handleMessagingResponse(data: data, response: response)

        return try JSONDecoder().decode(Conversation.self, from: data)
    }

    func addParticipant(conversationId: Int, memberId: String) async throws {
        let studentId = try authenticatedUserId()

        guard let url = URL(string: "\(baseURL)/student/\(studentId)/conversations/\(conversationId)/participants") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "memberId": memberId
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        try handleErrorResponse(data: data, response: response)
    }

    func removeParticipant(conversationId: Int, memberId: String) async throws {
        let studentId = try authenticatedUserId()

        guard let url = URL(string: "\(baseURL)/student/\(studentId)/conversations/\(conversationId)/participants/\(memberId)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (data, response) = try await URLSession.shared.data(for: request)
        try handleErrorResponse(data: data, response: response)
    }

    func leaveGroup(conversationId: Int) async throws -> LeaveGroupResult {
        let studentId = try authenticatedUserId()

        guard let url = URL(string: "\(baseURL)/student/\(studentId)/conversations/\(conversationId)/leave") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [:] as [String: Any])

        let (data, response) = try await URLSession.shared.data(for: request)
        try handleErrorResponse(data: data, response: response)

        return try JSONDecoder().decode(LeaveGroupResult.self, from: data)
    }

    func renameGroup(conversationId: Int, groupName: String) async throws {
        let studentId = try authenticatedUserId()

        guard let url = URL(string: "\(baseURL)/student/\(studentId)/conversations/\(conversationId)/rename") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "groupName": groupName
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        try handleErrorResponse(data: data, response: response)
    }

    // The /read endpoint also fills delivered_at when read_at is set, so we never need to call /delivered separately.
    func markRead(conversationId: Int) async throws {
        let studentId = try authenticatedUserId()

        guard let url = URL(string: "\(baseURL)/student/\(studentId)/conversations/\(conversationId)/read") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [:] as [String: Any])

        let (data, response) = try await URLSession.shared.data(for: request)
        try handleErrorResponse(data: data, response: response)
    }

    private func authenticatedUserId() throws -> String {
        guard let userId = sessionManager.userId else {
            throw URLError(.userAuthenticationRequired)
        }
        return userId
    }

    // Accepts both 200 and 201 for POST endpoints that create resources.
    // Separate from the shared handleErrorResponse to avoid changing behavior for other features.
    private func handleMessagingResponse(data: Data, response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...201).contains(httpResponse.statusCode) else {
            let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
            throw NSError(
                domain: "APIError",
                code: httpResponse.statusCode,
                userInfo: [
                    NSLocalizedDescriptionKey: apiError?.error ?? "Unknown error"
                ]
            )
        }
    }
}
