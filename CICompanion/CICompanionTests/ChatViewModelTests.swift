//
//  ChatViewModelTests.swift
//  CICompanionTests
//

import XCTest
@testable import CICompanion

@MainActor
final class ChatViewModelTests: XCTestCase {

    func testSuccessfulSendIncrementsSuccessfulSendCount() async {
        let repository = ChatMessagingRepositoryStub()
        let viewModel = ChatViewModel(
            messagingRepository: repository,
            currentUserId: "current-user"
        )
        viewModel.messageText = "Hello"

        viewModel.sendMessage(conversationId: 123)
        await waitForAsyncWork()

        XCTAssertEqual(viewModel.successfulSendCount, 1)
        XCTAssertEqual(viewModel.messages.map { $0.body }, ["Hello"])
        XCTAssertEqual(viewModel.messageText, "")
    }

    func testIngestDedupesById() async {
        let repository = ChatMessagingRepositoryStub()
        repository.stubbedMessages = [
            makeMessage(id: 1, conversationId: 100, body: "First", createdAt: "2026-05-05T12:00:00Z"),
            makeMessage(id: 2, conversationId: 100, body: "Second", createdAt: "2026-05-05T12:01:00Z")
        ]
        let viewModel = ChatViewModel(messagingRepository: repository, currentUserId: "u")
        viewModel.loadMessages(conversationId: 100)
        await waitForAsyncWork()
        XCTAssertEqual(viewModel.messages.count, 2)

        viewModel.ingest(makeMessage(id: 1, conversationId: 100, body: "Duplicate", createdAt: "2026-05-05T12:00:00Z"))

        XCTAssertEqual(viewModel.messages.count, 2)
        XCTAssertEqual(viewModel.messages.first?.body, "First")
    }

    func testIngestIgnoresWrongConversation() async {
        let repository = ChatMessagingRepositoryStub()
        let viewModel = ChatViewModel(messagingRepository: repository, currentUserId: "u")
        viewModel.loadMessages(conversationId: 100)
        await waitForAsyncWork()

        viewModel.ingest(makeMessage(id: 99, conversationId: 200, body: "Foreign", createdAt: "2026-05-05T13:00:00Z"))

        XCTAssertTrue(viewModel.messages.isEmpty)
    }

    func testIngestOrdersByCreatedAtThenId() async {
        let repository = ChatMessagingRepositoryStub()
        let viewModel = ChatViewModel(messagingRepository: repository, currentUserId: "u")
        viewModel.loadMessages(conversationId: 100)
        await waitForAsyncWork()

        viewModel.ingest(makeMessage(id: 2, conversationId: 100, body: "B", createdAt: "2026-05-05T12:01:00Z"))
        viewModel.ingest(makeMessage(id: 1, conversationId: 100, body: "A", createdAt: "2026-05-05T12:00:00Z"))
        viewModel.ingest(makeMessage(id: 3, conversationId: 100, body: "C", createdAt: "2026-05-05T12:01:00Z"))

        XCTAssertEqual(viewModel.messages.map(\.id), [1, 2, 3])
    }

    private func makeMessage(id: Int, conversationId: Int, body: String, createdAt: String) -> Message {
        Message(
            id: id,
            conversationId: conversationId,
            senderId: "u",
            senderName: "U",
            body: body,
            createdAt: createdAt
        )
    }

    private func waitForAsyncWork() async {
        try? await Task.sleep(nanoseconds: 100_000_000)
    }
}

private final class ChatMessagingRepositoryStub: MessagingRepositoryProtocol {

    func loadAllStudents() async throws -> [Participant] { [] }

    func loadContact(studentId: String) async throws -> Student {
        Student(id: studentId, name: "Student", email: "student@myci.csuci.edu", courses: [], events: [])
    }

    func loadConversations() async throws -> [Conversation] { [] }

    func searchConversations(query: String) async throws -> [Conversation] { [] }

    func searchMeetingSchedulers(query: String) async throws -> [MeetingSearchResult] { [] }

    func createOrGetDirectConversation(otherStudentId: String) async throws -> Conversation {
        Conversation(
            id: 1,
            conversationType: "direct",
            participantIds: ["current-user", otherStudentId],
            otherParticipant: Participant(id: otherStudentId, name: "Other", email: "other@myci.csuci.edu"),
            lastMessagePreview: nil,
            lastMessageAt: nil,
            createdAt: "2026-04-01T12:00:00Z"
        )
    }

    func createGroupConversation(groupName: String, memberIds: [String], firstMessageBody: String) async throws -> Conversation {
        Conversation(
            id: 2,
            conversationType: "group",
            participantIds: ["current-user"] + memberIds,
            otherParticipant: nil,
            groupName: groupName,
            lastMessagePreview: firstMessageBody,
            lastMessageAt: "2026-04-21T12:00:00Z",
            createdAt: "2026-04-21T12:00:00Z"
        )
    }

    var stubbedMessages: [Message] = []

    func loadMessages(conversationId: Int) async throws -> ConversationDetail {
        ConversationDetail(
            conversation: try await createOrGetDirectConversation(otherStudentId: "other"),
            messages: stubbedMessages
        )
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

    func requestImageUpload(conversationId: Int) async throws -> ImageUpload {
        ImageUpload(uploadURL: "https://example.com/upload", objectKey: "conversations/\(conversationId)/test.jpg")
    }

    func uploadImage(_ data: Data, to uploadURL: String) async throws {}

    func sendImageMessage(conversationId: Int, imageKey: String) async throws -> Message {
        Message(
            id: 1,
            conversationId: conversationId,
            senderId: "current-user",
            senderName: "Student",
            body: "",
            createdAt: "2026-04-21T12:00:00Z",
            imageKey: imageKey,
            imageURL: "https://example.com/image.jpg"
        )
    }

    func editMeetup(messageId: Int, body: String) async throws {}

    func loadMeetup(messageId: Int) async throws -> Message {
        Message(
            id: messageId,
            conversationId: 1,
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

    func hideDirectConversation(conversationId: Int) async throws {}
}
