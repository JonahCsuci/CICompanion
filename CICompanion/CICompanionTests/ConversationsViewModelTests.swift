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

    func testSearchCombinesConversationAndMeetingResults() async {
        let repository = MessagingRepositoryStub()
        repository.conversations = [makeConversation(id: 1, name: "Default", timestamp: "2026-04-19T11:01:14Z")]
        repository.searchResults["biology"] = [
            makeConversation(id: 5, name: "Chat Match", timestamp: "2026-04-18T10:00:00Z", preview: "biology chat")
        ]
        repository.meetingSearchResults["biology"] = [
            makeMeetingSearchResult(messageId: 90, title: "Biology Study Session")
        ]

        let viewModel = ConversationsViewModel(messagingRepository: repository)
        viewModel.loadConversations()
        await waitForAsyncWork()

        viewModel.updateSearchQuery("biology")
        await waitForSearchDebounce()

        XCTAssertEqual(repository.searchQueries, ["biology"])
        XCTAssertEqual(repository.meetingSearchQueries, ["biology"])
        XCTAssertEqual(viewModel.displayedSearchResults.map(\.id), ["conversation-5", "meeting-90"])
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

    private func makeMeetingSearchResult(messageId: Int, title: String) -> MeetingSearchResult {
        MeetingSearchResult(
            messageId: messageId,
            conversation: makeConversation(
                id: 44,
                name: "Meeting Chat",
                timestamp: "2026-04-19T11:01:14Z"
            ),
            meetingSchedulerId: "8E5BDB1B-7536-4B57-9E5E-F8DCA28C7149",
            title: title,
            createdAt: "2026-04-19T11:01:14Z"
        )
    }
}

@MainActor
final class HideConversationTests: XCTestCase {

    func testHideConversationRemovesRowAndDropsUnreadOverride() async {
        let stub = MessagingRepositoryStub()
        let directChat = makeDirectConversation(id: 7, unreadCount: 3)
        stub.conversations = [directChat]
        let viewModel = ConversationsViewModel(messagingRepository: stub)
        await viewModel.refreshConversationsSilently()

        viewModel.markConversationReadLocally(conversationId: 7)
        XCTAssertEqual(viewModel.unreadCount(for: directChat), 0)   // override applied

        // Mimic the server confirming the hide on the next load.
        stub.conversations = []
        viewModel.hideConversation(conversationId: 7)

        XCTAssertTrue(viewModel.conversations.isEmpty)
        XCTAssertTrue(viewModel.displayedConversations.isEmpty)

        try? await Task.sleep(nanoseconds: 100_000_000)

        // If the chat reappears later (e.g. via a new_message), the override
        // should have been cleared on hide so the server count is what shows.
        stub.conversations = [directChat]
        await viewModel.refreshConversationsSilently()
        XCTAssertEqual(viewModel.unreadCount(for: directChat), 3)
        XCTAssertEqual(stub.hiddenConversationIds, [7])
    }

    func testHideConversationFailureReloadsListAndSetsErrorMessage() async {
        let stub = MessagingRepositoryStub()
        let directChat = makeDirectConversation(id: 8)
        stub.conversations = [directChat]
        let viewModel = ConversationsViewModel(messagingRepository: stub)
        await viewModel.refreshConversationsSilently()

        stub.shouldFailHideDirect = true
        viewModel.hideConversation(conversationId: 8)

        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(viewModel.conversations.map(\.id), [8])
        XCTAssertEqual(viewModel.errorMessage, "Couldn't hide chat. Try again.")
    }

    private func makeDirectConversation(id: Int, unreadCount: Int? = nil) -> Conversation {
        Conversation(
            id: id,
            conversationType: "direct",
            participantIds: ["me", "other"],
            otherParticipant: Participant(id: "other", name: "Other", email: "other@x.edu"),
            unreadCount: unreadCount,
            lastMessageAt: "2026-05-05T12:00:00Z",
            createdAt: "2026-05-05T11:00:00Z"
        )
    }
}

@MainActor
final class HandleRealtimeNewMessageTests: XCTestCase {

    func testHandleRealtimeNewMessageTriggersSilentRefresh() async {
        let repository = MessagingRepositoryStub()
        repository.conversations = [
            Conversation(
                id: 42,
                conversationType: "direct",
                participantIds: ["me", "other"],
                otherParticipant: Participant(id: "other", name: "Other", email: "other@x.edu"),
                lastMessageAt: "2026-05-05T12:00:00Z",
                createdAt: "2026-05-05T11:00:00Z"
            )
        ]
        let viewModel = ConversationsViewModel(messagingRepository: repository)

        XCTAssertTrue(viewModel.conversations.isEmpty)

        await viewModel.handleRealtimeNewMessage(conversationId: 42)

        XCTAssertEqual(viewModel.conversations.map(\.id), [42])
    }
}

private final class MessagingRepositoryStub: MessagingRepositoryProtocol {

    var conversations: [Conversation] = []
    var searchResults: [String: [Conversation]] = [:]
    var meetingSearchResults: [String: [MeetingSearchResult]] = [:]
    var searchDelays: [String: UInt64] = [:]
    var searchQueries: [String] = []
    var meetingSearchQueries: [String] = []

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

    func searchMeetingSchedulers(query: String) async throws -> [MeetingSearchResult] {
        meetingSearchQueries.append(query)
        return meetingSearchResults[query] ?? []
    }

    func createOrGetDirectConversation(otherStudentId: String) async throws -> Conversation {
        makeFallbackConversation()
    }

    func createGroupConversation(groupName: String, memberIds: [String], firstMessageBody: String) async throws -> Conversation {
        Conversation(
            id: 1000,
            conversationType: "group",
            participantIds: ["current-user"] + memberIds,
            otherParticipant: nil,
            groupName: groupName,
            lastMessagePreview: firstMessageBody,
            lastMessageAt: "2026-04-21T12:00:00Z",
            createdAt: "2026-04-21T12:00:00Z"
        )
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

    func addParticipant(conversationId: Int, memberId: String) async throws {}

    func removeParticipant(conversationId: Int, memberId: String) async throws {}

    func leaveGroup(conversationId: Int) async throws -> LeaveGroupResult {
        LeaveGroupResult(
            conversationId: conversationId,
            leftStudentId: "current-user",
            wasAdmin: false,
            newAdminStudentId: nil,
            conversationDeleted: false
        )
    }

    func renameGroup(conversationId: Int, groupName: String) async throws {}

    func markRead(conversationId: Int) async throws {}

    func getMeeting(body: String) -> MeetingScheduler? { nil }

    func getMeetingProposal(body: String) -> MeetingProposal? { nil }

    func fetchStudyRooms(start: Date, end: Date) async throws -> [Int: [TimeRange]] { [:] }

    var shouldFailHideDirect = false
    private(set) var hiddenConversationIds: [Int] = []

    func hideDirectConversation(conversationId: Int) async throws {
        if shouldFailHideDirect {
            throw NSError(
                domain: "Stub",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Stubbed failure"]
            )
        }
        hiddenConversationIds.append(conversationId)
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
