//
//  ConversationsViewModelTests.swift
//  CICompanionTests
//

import XCTest
@testable import CICompanion

@MainActor
final class ConversationsViewModelTests: XCTestCase {

    func testLoadConversationsPopulatesDisplayedConversationsSortedByRecent() async {
        let repository = MessagingRepositoryStub()
        let older = makeConversation(id: 1, name: "Older", timestamp: "2026-04-18T11:01:14Z")
        let newer = makeConversation(id: 2, name: "Newer", timestamp: "2026-04-19T11:01:14Z")
        repository.conversations = [older, newer]

        let viewModel = ConversationsViewModel(messagingRepository: repository)
        viewModel.loadConversations()

        await waitForAsyncWork()

        XCTAssertEqual(viewModel.conversations.map(\.id), [2, 1])
        XCTAssertEqual(viewModel.displayedConversations.map(\.id), [2, 1])
    }

    func testLoadConversationsKeepsTrulyEmptyConversationsHidden() async {
        let repository = MessagingRepositoryStub()
        let emptyConversation = makeConversation(id: 1, name: "Empty", timestamp: nil, preview: nil)
        let activeConversation = makeConversation(id: 2, name: "Active", timestamp: "2026-04-19T11:01:14Z")
        repository.conversations = [emptyConversation, activeConversation]

        let viewModel = ConversationsViewModel(messagingRepository: repository)
        viewModel.loadConversations()

        await waitForAsyncWork()

        XCTAssertEqual(viewModel.conversations.map(\.id), [2])
        XCTAssertEqual(viewModel.displayedConversations.map(\.id), [2])
    }

    func testShortSearchQueryDoesNotTriggerBackendSearch() async {
        let repository = MessagingRepositoryStub()
        repository.conversations = [makeConversation(id: 1, name: "Default", timestamp: "2026-04-19T11:01:14Z")]

        let viewModel = ConversationsViewModel(messagingRepository: repository)
        viewModel.loadConversations()
        await waitForAsyncWork()

        viewModel.updateSearchQuery("he")
        await waitForSearchDebounce()

        XCTAssertTrue(viewModel.shouldShowShortSearchHint)
        XCTAssertEqual(repository.searchQueries, [])
        XCTAssertEqual(viewModel.displayedConversations.map(\.id), [1])
    }

    func testSearchUsesBackendOrderWithoutResorting() async {
        let repository = MessagingRepositoryStub()
        repository.conversations = [makeConversation(id: 1, name: "Default", timestamp: "2026-04-19T11:01:14Z")]
        repository.searchResults["hello"] = [
            makeConversation(id: 5, name: "Second Match", timestamp: "2026-04-18T10:00:00Z", preview: "hello two"),
            makeConversation(id: 4, name: "First Match", timestamp: "2026-04-19T10:00:00Z", preview: "hello one")
        ]

        let viewModel = ConversationsViewModel(messagingRepository: repository)
        viewModel.loadConversations()
        await waitForAsyncWork()

        viewModel.updateSearchQuery("hello")
        await waitForSearchDebounce()

        XCTAssertEqual(repository.searchQueries, ["hello"])
        XCTAssertEqual(viewModel.displayedConversations.map(\.id), [5, 4])
    }

    func testRapidSearchChangesCancelStaleResults() async {
        let repository = MessagingRepositoryStub()
        repository.searchDelays["hel"] = 900_000_000
        repository.searchResults["hel"] = [
            makeConversation(id: 1, name: "Stale Result", timestamp: "2026-04-18T10:00:00Z", preview: "hel")
        ]
        repository.searchResults["hello"] = [
            makeConversation(id: 2, name: "Fresh Result", timestamp: "2026-04-19T10:00:00Z", preview: "hello")
        ]

        let viewModel = ConversationsViewModel(messagingRepository: repository)
        viewModel.updateSearchQuery("hel")

        try? await Task.sleep(nanoseconds: 100_000_000)

        viewModel.updateSearchQuery("hello")
        await waitForSearchDebounce(extraDelay: 700_000_000)

        XCTAssertEqual(viewModel.displayedConversations.map(\.id), [2])
        XCTAssertEqual(repository.searchQueries.contains("hello"), true)
    }

    func testClearSearchRestoresDefaultConversationList() async {
        let repository = MessagingRepositoryStub()
        let defaultConversation = makeConversation(id: 1, name: "Default", timestamp: "2026-04-19T11:01:14Z")
        repository.conversations = [defaultConversation]
        repository.searchResults["hello"] = [
            makeConversation(id: 2, name: "Match", timestamp: "2026-04-18T10:00:00Z", preview: "hello")
        ]

        let viewModel = ConversationsViewModel(messagingRepository: repository)
        viewModel.loadConversations()
        await waitForAsyncWork()

        viewModel.updateSearchQuery("hello")
        await waitForSearchDebounce()
        viewModel.clearSearch()

        XCTAssertEqual(viewModel.searchQuery, "")
        XCTAssertFalse(viewModel.isSearchActive)
        XCTAssertNil(viewModel.searchErrorMessage)
        XCTAssertEqual(viewModel.displayedConversations.map(\.id), [1])
    }

    private func waitForAsyncWork() async {
        try? await Task.sleep(nanoseconds: 100_000_000)
    }

    private func waitForSearchDebounce(extraDelay: UInt64 = 200_000_000) async {
        try? await Task.sleep(nanoseconds: 300_000_000 + extraDelay)
    }

    private func makeConversation(
        id: Int,
        name: String,
        timestamp: String?,
        preview: String? = "Preview"
    ) -> Conversation {
        Conversation(
            id: id,
            conversationType: "direct",
            participantIds: ["current-user", "other-\(id)"],
            otherParticipant: Participant(
                id: "other-\(id)",
                name: name,
                email: "\(name.lowercased().replacingOccurrences(of: " ", with: "."))@myci.csuci.edu"
            ),
            lastMessagePreview: preview,
            lastMessageAt: timestamp,
            createdAt: "2026-04-01T12:00:00Z"
        )
    }
}

private final class MessagingRepositoryStub: MessagingRepositoryProtocol {

    var conversations: [Conversation] = []
    var searchResults: [String: [Conversation]] = [:]
    var searchDelays: [String: UInt64] = [:]
    var searchQueries: [String] = []

    func loadAllStudents() async throws -> [Participant] { [] }

    func loadContact(studentId: String) async throws -> Student {
        Student(id: studentId, name: "Student", email: "student@myci.csuci.edu", courses: [], events: [])
    }

    func loadConversations() async throws -> [Conversation] {
        conversations
    }

    func searchConversations(query: String) async throws -> [Conversation] {
        searchQueries.append(query)

        if let delay = searchDelays[query] {
            try await Task.sleep(nanoseconds: delay)
        }

        return searchResults[query] ?? []
    }

    func createOrGetDirectConversation(otherStudentId: String) async throws -> Conversation {
        makeFallbackConversation()
    }

    func loadMessages(conversationId: Int) async throws -> ConversationDetail {
        ConversationDetail(conversation: makeFallbackConversation(), messages: [])
    }

    func sendMessage(conversationId: Int, body: String) async throws -> Message {
        Message(
            id: 1,
            conversationId: conversationId,
            senderId: "current-user",
            senderName: "Student",
            body: body,
            createdAt: "2026-04-21T12:00:00Z"
        )
    }

    func editMeetup(messageId: Int, body: String) async throws {}

    func loadMeetup(messageId: Int) async throws -> Message {
        Message(
            id: messageId,
            conversationId: 999,
            senderId: "current-user",
            senderName: "Student",
            body: "Meetup",
            createdAt: "2026-04-21T12:00:00Z"
        )
    }

    private func makeFallbackConversation() -> Conversation {
        Conversation(
            id: 999,
            conversationType: "direct",
            participantIds: ["current-user", "other"],
            otherParticipant: Participant(id: "other", name: "Other", email: "other@myci.csuci.edu"),
            lastMessagePreview: "Preview",
            lastMessageAt: "2026-04-21T12:00:00Z",
            createdAt: "2026-04-01T12:00:00Z"
        )
    }
}
