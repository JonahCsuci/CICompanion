//
//  APIStudentRepository.swift
//  CICompanion
//
//  Created by Wummiez on 3/9/26.
//

import Foundation
import Amplify
import AWSCognitoAuthPlugin
import AWSPluginsCore


class APIStudentRepository: StudentRepositoryProtocol {
    
    // Stored student in memory
    private var student: Student?
    private var contacts: [ContactStudent]?
    private let sessionManager: SessionManager
    
    let baseURL = "https://ibxw69g864.execute-api.us-west-1.amazonaws.com"
    
    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }
    
    func loadStudent() async throws -> Student {
        
        // If student previously loaded, immediately return
        if let student {
            return student
        }
        
        guard let studentId = sessionManager.userId else {
            throw URLError(.userAuthenticationRequired)
        }
        
        // Build API endpoint for fetching all of current student's info
        guard let url = URL(string: "\(baseURL)/student/\(studentId)") else {
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
        let student = try JSONDecoder().decode(Student.self, from: data)
        
        self.student = student
        
        return student
    }
    
    func addStudentCourse(courseId: Int) async throws {
        
        guard let studentId = sessionManager.userId else {
            throw URLError(.userAuthenticationRequired)
        }
        
        // Build API endpoint to add a course for a student
        guard let url = URL(string: "\(baseURL)/student/\(studentId)/courses/\(courseId)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        
        // Use POST to add a course to the student's enrolled courses
        request.httpMethod = "POST"
        
        // Send request to backend (API Gateway -> Lambda -> database)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Validate HTTP response and throw error if request failed
        try handleErrorResponse(data: data, response: response)
        
        // Add course to cached student
        if var student = student {
            if !student.courses.contains(courseId) {
                student.courses.append(courseId)
            }
            self.student = student
        }
    }
    
    func deleteStudentCourse(courseId: Int) async throws {
        
        guard let studentId = sessionManager.userId else {
            throw URLError(.userAuthenticationRequired)
        }
        
        // Build API endpoint to delete a course for a student
        guard let url = URL(string: "\(baseURL)/student/\(studentId)/courses/\(courseId)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        
        // Use DELETE to remove a course from the student's enrolled courses
        request.httpMethod = "DELETE"
        
        // Send request to backend (API Gateway -> Lambda -> database)
        let(data, response) = try await URLSession.shared.data(for: request)
        
        // Validate HTTP response and throw error if request failed
        try handleErrorResponse(data: data, response: response)
        
        // Remove course from cached student
        if var student = student {
            student.courses.removeAll { $0 == courseId }
            self.student = student
        }
    }
    
    func updateStudentEvents(events: [String]) async throws {
            if student != nil {
                student!.events = events
            }

            guard let studentId = sessionManager.userId else {
                throw URLError(.userAuthenticationRequired)
            }

            guard let url = URL(string: "\(baseURL)/student/\(studentId)/events") else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            struct RequestBody: Codable {
                let studentId: String
                let events: [String]
            }

            let body = RequestBody(
                studentId: studentId,
                events: events
            )

            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)
            try handleErrorResponse(data: data, response: response)
        }
        
        func addStudentEvent(event: String) async throws {
            var events = student?.events ?? []

            if !events.contains(event) {
                events.append(event)
            }

            try await updateStudentEvents(events: events)
        }
        
        func deleteStudentEvent(event: String) async throws {
            var events = student?.events ?? []

            events.removeAll { $0 == event }

            try await updateStudentEvents(events: events)
        }
    
    // Legacy thin wrapper: existing call sites still call `addStudentContact`.
    // Pass 2 migrates them to `sendContactRequest` directly so the
    // AddContactOutcome cases can drive UI state for pending vs auto-accepted.
    func addStudentContact(email: String) async throws {
        _ = try await sendContactRequest(toEmail: email)
    }

    func sendContactRequest(toEmail email: String) async throws -> SendContactRequestResponse {
        guard let studentId = sessionManager.userId else {
            throw URLError(.userAuthenticationRequired)
        }

        guard let url = URL(string: "\(baseURL)/student/\(studentId)/contacts") else {
            throw URLError(.badURL)
        }

        var request = try await authenticatedRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email.trimmingCharacters(in: .whitespacesAndNewlines)
        ])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            let decoded = try JSONDecoder().decode(SendContactRequestResponse.self, from: data)
            if decoded.status == KnownContactRequestStatus.accepted.rawValue {
                // Auto-accept created a mutual contact server-side; refetch on next read.
                contacts = nil
            }
            return decoded
        }

        // 409 with status="pending" means the request was already pending —
        // idempotent success rather than an error.
        if httpResponse.statusCode == 409,
           let decoded = try? JSONDecoder().decode(SendContactRequestResponse.self, from: data),
           decoded.status == KnownContactRequestStatus.pending.rawValue {
            return decoded
        }

        try handleErrorResponse(data: data, response: response)
        throw URLError(.badServerResponse)
    }

    func loadContactRequests(status: String?, direction: String?, limit: Int?) async throws -> ContactRequestListResponse {
        guard let studentId = sessionManager.userId else {
            throw URLError(.userAuthenticationRequired)
        }

        var components = URLComponents(string: "\(baseURL)/student/\(studentId)/contact-requests")
        var queryItems: [URLQueryItem] = []
        if let status { queryItems.append(URLQueryItem(name: "status", value: status)) }
        if let direction { queryItems.append(URLQueryItem(name: "direction", value: direction)) }
        if let limit { queryItems.append(URLQueryItem(name: "limit", value: String(limit))) }
        if !queryItems.isEmpty { components?.queryItems = queryItems }

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)
        do {
            try handleErrorResponse(data: data, response: response)
        } catch {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("[APIStudentRepository.loadContactRequests] HTTP \(statusCode) at \(url) — body: \(String(decoding: data, as: UTF8.self))")
            throw error
        }

        do {
            return try JSONDecoder().decode(ContactRequestListResponse.self, from: data)
        } catch {
            print("[APIStudentRepository.loadContactRequests] Decode failed at \(url) — body: \(String(decoding: data, as: UTF8.self)) — error: \(error)")
            throw error
        }
    }

    func acceptContactRequest(requestId: Int) async throws -> ContactRequestActionResponse {
        try await performContactRequestAction(requestId: requestId, action: "accept")
    }

    func declineContactRequest(requestId: Int) async throws -> ContactRequestActionResponse {
        try await performContactRequestAction(requestId: requestId, action: "decline")
    }

    func cancelContactRequest(requestId: Int) async throws -> ContactRequestActionResponse {
        try await performContactRequestAction(requestId: requestId, action: "cancel")
    }

    private func performContactRequestAction(requestId: Int, action: String) async throws -> ContactRequestActionResponse {
        guard let studentId = sessionManager.userId else {
            throw URLError(.userAuthenticationRequired)
        }

        guard let url = URL(string: "\(baseURL)/student/\(studentId)/contact-requests/\(requestId)/\(action)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [:] as [String: Any])

        let (data, response) = try await URLSession.shared.data(for: request)
        do {
            try handleErrorResponse(data: data, response: response)
        } catch {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("[APIStudentRepository.performContactRequestAction action=\(action) requestId=\(requestId)] HTTP \(statusCode) — body: \(String(decoding: data, as: UTF8.self))")
            throw error
        }

        if action == "accept" {
            // Accept created a mutual contact server-side; refetch on next read.
            contacts = nil
        }

        return try JSONDecoder().decode(ContactRequestActionResponse.self, from: data)
    }

    func searchContactStudents(query: String) async throws -> [StudentSharedCourses] {

        guard let studentId = sessionManager.userId else {
            throw URLError(.userAuthenticationRequired)
        }

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        var components = URLComponents(string: "\(baseURL)/student/\(studentId)/contacts/search")
        components?.queryItems = [
            URLQueryItem(name: "q", value: trimmedQuery),
            URLQueryItem(name: "limit", value: "10")
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = try await authenticatedRequest(url: url)
        request.httpMethod = "GET"

        let(data, response) = try await URLSession.shared.data(for: request)

        try handleErrorResponse(data: data, response: response)

        let decoder = JSONDecoder()
        if let wrapped = try? decoder.decode(ContactStudentSearchResponse.self, from: data) {
            return wrapped.students
        }

        return try decoder.decode([StudentSharedCourses].self, from: data)
    }
    
    func loadStudentContacts() async throws -> [ContactStudent] {

        // Always refetch. The in-memory cache has no invalidation path for
        // server-side mutations driven by another user (e.g., the recipient
        // accepting our pending request creates a contact row for us that no
        // local code path touches). Returning the cached list there leaves
        // the new contact invisible until the app is force-quit.
        guard let studentId = sessionManager.userId else {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard let url = URL(string: "\(baseURL)/student/\(studentId)/contacts") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let(data, response) = try await URLSession.shared.data(for: request)
        
        try handleErrorResponse(data: data, response: response)
        
        let contacts = try JSONDecoder().decode([ContactStudent].self, from: data)
        self.contacts = contacts
        
        return contacts
    }
    
    func deleteStudentContact(contactStudentId: String) async throws {
        
        guard let studentId = sessionManager.userId else {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard let encodedContactStudentId = contactStudentId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/student/\(studentId)/contacts/\(encodedContactStudentId)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let(data, response) = try await URLSession.shared.data(for: request)
        
        try handleErrorResponse(data: data, response: response)
        
        if var contacts {
            contacts.removeAll { $0.id == contactStudentId }
            self.contacts = contacts
        }
    }
    
    func hasStudentContact(contactStudentId: String) async throws -> Bool {
        let contacts = try await loadStudentContacts()
        return contacts.contains { $0.id == contactStudentId }
    }
    
    func ensureStudentExists() async throws -> Student {
        
        // Authenticates user exists in user pool
        guard let studentId = sessionManager.userId else {
            throw URLError(.userAuthenticationRequired)
        }
        
        let name = sessionManager.name ?? "User"
        
        guard let email = sessionManager.email, !email.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard let url = URL(string: "\(baseURL)/student/\(studentId)") else {
            throw URLError(.badURL)
        }
        
        // Checks if exists in database
        // If doesn't exist yet, creates and returns student from DB
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "name": name,
            "email": email
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        try handleErrorResponse(data: data, response: response)
        
        let student = try JSONDecoder().decode(Student.self, from: data)
        self.student = student
        
        return student
        
    }
    
    func updateScheduleTimes(meetings: [MeetingProposal]) async throws {
        if student != nil {
            student!.meetings = meetings
        }
        
        guard let studentId = sessionManager.userId else {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard let url = URL(string: "\(baseURL)/student/\(studentId)/meeting-proposal") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        struct RequestBody: Codable {
            let studentId: String
            let meetingProposal: [MeetingProposal]
        }
        
        let body = RequestBody(
            studentId: studentId,
            meetingProposal: meetings
        )
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        print("updateScheduleTimes response: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        print("updateScheduleTimes body: \(String(decoding: data, as: UTF8.self))")
        try handleErrorResponse(data: data, response: response)
    }
    
    func loadStudentSharedCourses() async throws -> [StudentSharedCourses] {
        
        guard let studentId = sessionManager.userId else {
            throw URLError(.userAuthenticationRequired)
        }
        
        // Build API endpoint for fetching all of current student's info
        guard let url = URL(string: "\(baseURL)/contact/students/sharedCourses/\(studentId)") else {
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
        let students = try JSONDecoder().decode([StudentSharedCourses].self, from: data)
        
        return students
    }

    private func authenticatedRequest(url: URL) async throws -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(try await idToken())", forHTTPHeaderField: "Authorization")
        return request
    }

    private func idToken() async throws -> String {
        let session = try await Amplify.Auth.fetchAuthSession()

        guard session.isSignedIn else {
            throw URLError(.userAuthenticationRequired)
        }

        guard let tokenProvider = session as? AuthCognitoTokensProvider else {
            throw URLError(.userAuthenticationRequired)
        }

        let tokens = try tokenProvider.getCognitoTokens().get()
        return tokens.idToken
    }
}
