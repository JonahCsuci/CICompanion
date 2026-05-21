//
//  ContactRequestsViewModelTests.swift
//  CICompanionTests
//

import XCTest
@testable import CICompanion

@MainActor
final class ContactRequestsViewModelTests: XCTestCase {

    func testLoadRequestsPopulatesIncomingAndOutgoing() async {
        let repository = ContactRequestRepositoryStub()
        repository.incomingResponse = [makeRequest(id: 1, direction: "incoming")]
        repository.outgoingResponse = [makeRequest(id: 2, direction: "outgoing")]

        let viewModel = ContactRequestsViewModel(studentRepository: repository)
        await viewModel.loadRequests()

        XCTAssertEqual(viewModel.incoming.map(\.requestId), [1])
        XCTAssertEqual(viewModel.outgoing.map(\.requestId), [2])
        XCTAssertEqual(viewModel.incomingPendingCount, 1)
        XCTAssertEqual(viewModel.outgoingPendingCount, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testRefreshSilentlySwallowsErrors() async {
        let repository = ContactRequestRepositoryStub()
        repository.shouldFailLoad = true

        let viewModel = ContactRequestsViewModel(studentRepository: repository)
        await viewModel.refreshSilently()

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.incoming.isEmpty)
    }

    func testAcceptRemovesRequestFromIncomingAndCallsRepository() async {
        let repository = ContactRequestRepositoryStub()
        repository.incomingResponse = [makeRequest(id: 1, direction: "incoming")]

        let viewModel = ContactRequestsViewModel(studentRepository: repository)
        await viewModel.loadRequests()

        await viewModel.accept(1)

        XCTAssertEqual(repository.acceptedIds, [1])
        XCTAssertTrue(viewModel.incoming.isEmpty)
        XCTAssertEqual(viewModel.incomingPendingCount, 0)
    }

    func testAcceptCallsOnAcceptedClosureWithResponse() async {
        let repository = ContactRequestRepositoryStub()
        repository.incomingResponse = [makeRequest(id: 7, direction: "incoming")]
        repository.acceptResponse = ContactRequestActionResponse(
            success: true,
            action: "accept",
            status: "accepted",
            requestId: 7,
            requesterId: nil,
            recipientId: nil,
            contactStudentId: "user-A",
            conversationId: 99
        )

        let viewModel = ContactRequestsViewModel(studentRepository: repository)
        await viewModel.loadRequests()

        var capturedConversationId: Int?
        await viewModel.accept(7) { response in
            capturedConversationId = response.conversationId
        }

        XCTAssertEqual(capturedConversationId, 99)
    }

    func testDeclineRemovesRequestFromIncoming() async {
        let repository = ContactRequestRepositoryStub()
        repository.incomingResponse = [makeRequest(id: 5, direction: "incoming")]

        let viewModel = ContactRequestsViewModel(studentRepository: repository)
        await viewModel.loadRequests()

        await viewModel.decline(5)

        XCTAssertEqual(repository.declinedIds, [5])
        XCTAssertTrue(viewModel.incoming.isEmpty)
    }

    func testCancelRemovesRequestFromOutgoing() async {
        let repository = ContactRequestRepositoryStub()
        repository.outgoingResponse = [makeRequest(id: 3, direction: "outgoing")]

        let viewModel = ContactRequestsViewModel(studentRepository: repository)
        await viewModel.loadRequests()

        await viewModel.cancel(3)

        XCTAssertEqual(repository.canceledIds, [3])
        XCTAssertTrue(viewModel.outgoing.isEmpty)
    }

    func testActionFailureLeavesListUnchangedAndSurfaceErrorMessage() async {
        let repository = ContactRequestRepositoryStub()
        repository.incomingResponse = [makeRequest(id: 1, direction: "incoming")]
        repository.shouldFailAction = true

        let viewModel = ContactRequestsViewModel(studentRepository: repository)
        await viewModel.loadRequests()

        await viewModel.accept(1)

        XCTAssertEqual(viewModel.incoming.count, 1)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testAppendOutgoingPlaceholderInsertsRequestAtTop() {
        let repository = ContactRequestRepositoryStub()
        let viewModel = ContactRequestsViewModel(studentRepository: repository)

        let recipient = StudentSummary(id: "user-B", name: "Bob", email: "bob@x.edu")
        viewModel.appendOutgoingPlaceholder(requestId: 42, recipient: recipient)

        XCTAssertEqual(viewModel.outgoing.first?.requestId, 42)
        XCTAssertEqual(viewModel.outgoing.first?.recipientId, "user-B")
        XCTAssertEqual(viewModel.outgoing.first?.otherStudent?.name, "Bob")
        XCTAssertEqual(viewModel.outgoingPendingCount, 1)
    }

    func testAppendOutgoingPlaceholderIsIdempotentForSameRequestId() {
        let repository = ContactRequestRepositoryStub()
        let viewModel = ContactRequestsViewModel(studentRepository: repository)

        let recipient = StudentSummary(id: "user-B", name: "Bob", email: "bob@x.edu")
        viewModel.appendOutgoingPlaceholder(requestId: 42, recipient: recipient)
        viewModel.appendOutgoingPlaceholder(requestId: 42, recipient: recipient)

        XCTAssertEqual(viewModel.outgoing.count, 1)
    }

    func testApplyChangeRemovesAcceptedFromIncoming() {
        let repository = ContactRequestRepositoryStub()
        let viewModel = ContactRequestsViewModel(studentRepository: repository)
        viewModel.incoming = [makeRequest(id: 9, direction: "incoming")]

        let change = makeChange(action: "accepted", requestId: 9, status: "accepted")
        viewModel.applyChange(change)

        XCTAssertTrue(viewModel.incoming.isEmpty)
    }

    func testApplyChangeRemovesAutoAcceptedFromBothLists() {
        let repository = ContactRequestRepositoryStub()
        let viewModel = ContactRequestsViewModel(studentRepository: repository)
        viewModel.outgoing = [makeRequest(id: 11, direction: "outgoing")]

        let change = makeChange(action: "auto_accepted", requestId: 11, status: "accepted")
        viewModel.applyChange(change)

        XCTAssertTrue(viewModel.outgoing.isEmpty)
    }

    func testApplyChangeIgnoresCreatedAction() {
        let repository = ContactRequestRepositoryStub()
        let viewModel = ContactRequestsViewModel(studentRepository: repository)

        let change = makeChange(action: "created", requestId: 21, status: "pending")
        viewModel.applyChange(change)

        // No local row to add since "created" doesn't carry student info; the
        // refresh path is responsible for fetching the new row.
        XCTAssertTrue(viewModel.incoming.isEmpty)
        XCTAssertTrue(viewModel.outgoing.isEmpty)
    }

    func testApplyChangeIgnoresUnknownAction() {
        let repository = ContactRequestRepositoryStub()
        let viewModel = ContactRequestsViewModel(studentRepository: repository)
        viewModel.incoming = [makeRequest(id: 1, direction: "incoming")]

        let change = makeChange(action: "future_action_x", requestId: 1, status: "future")
        viewModel.applyChange(change)

        XCTAssertEqual(viewModel.incoming.count, 1)
    }

    // MARK: - Test helpers

    private func makeRequest(id: Int, direction: String) -> ContactRequest {
        ContactRequest(
            requestId: id,
            requesterId: "user-A",
            recipientId: "user-B",
            status: "pending",
            direction: direction,
            createdAt: "2026-05-05T00:00:00Z",
            updatedAt: nil,
            respondedAt: nil,
            otherStudent: StudentSummary(id: "user-X", name: "Sample", email: "sample@x.edu"),
            requester: nil,
            recipient: nil
        )
    }

    private func makeChange(action: String, requestId: Int, status: String) -> ContactRequestChange {
        ContactRequestChange(
            type: "contact_request_changed",
            action: action,
            requestId: requestId,
            status: status,
            requesterId: "user-A",
            recipientId: "user-B",
            conversationId: nil,
            shouldRefreshContactRequests: true,
            shouldRefreshContacts: status == "accepted",
            shouldRefreshConversations: status == "accepted"
        )
    }
}

private final class ContactRequestRepositoryStub: StudentRepositoryProtocol {

    var incomingResponse: [ContactRequest] = []
    var outgoingResponse: [ContactRequest] = []
    var shouldFailLoad = false
    var shouldFailAction = false
    var acceptResponse: ContactRequestActionResponse?

    private(set) var acceptedIds: [Int] = []
    private(set) var declinedIds: [Int] = []
    private(set) var canceledIds: [Int] = []

    func loadStudent() async throws -> Student {
        Student(id: "stub", name: "Stub", email: "stub@x.edu", courses: [], events: [])
    }

    func addStudentCourse(courseId: Int) async throws {}

    func deleteStudentCourse(courseId: Int) async throws {}

    func ensureStudentExists() async throws -> Student {
        try await loadStudent()
    }

    func updateStudentEvents(events: [Event]) async throws {}

    func addStudentEvent(event: Event) async throws {}

    func hasStudentEvent(event: Event) async throws -> Bool { false }

    func deleteStudentEvent(event: Event) async throws {}

    func addStudentContact(email: String) async throws {}

    func loadStudentContacts() async throws -> [ContactStudent] { [] }

    func deleteStudentContact(contactStudentId: String) async throws {}

    func hasStudentContact(contactStudentId: String) async throws -> Bool { false }

    func searchContactStudents(query: String) async throws -> [StudentSharedCourses] { [] }

    func updateScheduleTimes(meetings: [MeetingProposal]) async throws {}

    func loadStudentSharedCourses() async throws -> [StudentSharedCourses] { [] }

    func sendContactRequest(toEmail email: String) async throws -> SendContactRequestResponse {
        SendContactRequestResponse(
            success: true,
            status: "pending",
            autoAccepted: nil,
            requestId: 1,
            contactStudentId: "stub",
            conversationId: nil
        )
    }

    func loadContactRequests(status: String?, direction: String?, limit: Int?) async throws -> ContactRequestListResponse {
        if shouldFailLoad {
            throw NSError(domain: "Stub", code: -1)
        }
        return ContactRequestListResponse(
            success: true,
            studentId: nil,
            statusFilter: status,
            directionFilter: direction,
            incoming: incomingResponse,
            outgoing: outgoingResponse,
            counts: ContactRequestListResponse.Counts(
                incomingPending: incomingResponse.count,
                outgoingPending: outgoingResponse.count,
                totalPending: incomingResponse.count + outgoingResponse.count
            )
        )
    }

    func acceptContactRequest(requestId: Int) async throws -> ContactRequestActionResponse {
        if shouldFailAction {
            throw NSError(domain: "Stub", code: -2)
        }
        acceptedIds.append(requestId)
        return acceptResponse ?? ContactRequestActionResponse(
            success: true,
            action: "accept",
            status: "accepted",
            requestId: requestId,
            requesterId: nil,
            recipientId: nil,
            contactStudentId: nil,
            conversationId: 1
        )
    }

    func declineContactRequest(requestId: Int) async throws -> ContactRequestActionResponse {
        if shouldFailAction {
            throw NSError(domain: "Stub", code: -3)
        }
        declinedIds.append(requestId)
        return ContactRequestActionResponse(
            success: true,
            action: "decline",
            status: "declined",
            requestId: requestId,
            requesterId: nil,
            recipientId: nil,
            contactStudentId: nil,
            conversationId: nil
        )
    }

    func cancelContactRequest(requestId: Int) async throws -> ContactRequestActionResponse {
        if shouldFailAction {
            throw NSError(domain: "Stub", code: -4)
        }
        canceledIds.append(requestId)
        return ContactRequestActionResponse(
            success: true,
            action: "cancel",
            status: "canceled",
            requestId: requestId,
            requesterId: nil,
            recipientId: nil,
            contactStudentId: nil,
            conversationId: nil
        )
    }
}
