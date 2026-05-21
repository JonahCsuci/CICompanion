//
//  ContactsViewModelTests.swift
//  CICompanionTests
//

import XCTest
@testable import CICompanion

@MainActor
final class ContactsViewModelTests: XCTestCase {

    func testLoadContactsPublishesContactsAndBadgeState() async {
        let repository = ContactStudentRepositoryStub()
        let viewModel = ContactsViewModel(studentRepository: repository)

        await viewModel.loadContacts()

        XCTAssertEqual(viewModel.contacts.count, 2)
        XCTAssertTrue(viewModel.isContact(studentId: "contact-1"))
        XCTAssertFalse(viewModel.isContact(studentId: "not-a-contact"))
        XCTAssertNil(viewModel.errorMessage)
    }

    func testAddContactPendingDoesNotReloadContacts() async {
        let repository = ContactStudentRepositoryStub()
        repository.availableContacts["new.student@myci.csuci.edu"] = ContactStudent(
            id: "contact-3",
            name: "New Student",
            email: "new.student@myci.csuci.edu"
        )

        let viewModel = ContactsViewModel(studentRepository: repository)
        await viewModel.loadContacts()
        XCTAssertEqual(viewModel.contacts.count, 2)

        let outcome = await viewModel.addContact(email: "new.student@myci.csuci.edu")

        guard case let .pendingSent(requestId, contactStudentId) = outcome else {
            XCTFail("Expected .pendingSent; got \(outcome)")
            return
        }
        XCTAssertEqual(requestId, 1)
        XCTAssertEqual(contactStudentId, "contact-3")
        XCTAssertEqual(viewModel.contacts.count, 2)
        XCTAssertFalse(viewModel.isContact(studentId: "contact-3"))
        XCTAssertNil(viewModel.errorMessage)
    }

    func testAddContactAutoAcceptedReloadsContacts() async {
        let repository = ContactStudentRepositoryStub()
        repository.availableContacts["new.student@myci.csuci.edu"] = ContactStudent(
            id: "contact-3",
            name: "New Student",
            email: "new.student@myci.csuci.edu"
        )
        repository.autoAcceptOnSend = true

        let viewModel = ContactsViewModel(studentRepository: repository)
        await viewModel.loadContacts()
        XCTAssertEqual(viewModel.contacts.count, 2)

        let outcome = await viewModel.addContact(email: "new.student@myci.csuci.edu")

        guard case let .autoAccepted(conversationId) = outcome else {
            XCTFail("Expected .autoAccepted; got \(outcome)")
            return
        }
        XCTAssertEqual(conversationId, 99)
        XCTAssertEqual(viewModel.contacts.count, 3)
        XCTAssertTrue(viewModel.isContact(studentId: "contact-3"))
        XCTAssertNil(viewModel.errorMessage)
    }

    func testAddContactAlreadyContactReturnsAlreadyContactCase() async {
        let repository = ContactStudentRepositoryStub()
        let viewModel = ContactsViewModel(studentRepository: repository)
        await viewModel.loadContacts()

        let outcome = await viewModel.addContact(email: "contact.one@myci.csuci.edu")

        if case .alreadyContact = outcome {} else {
            XCTFail("Expected .alreadyContact; got \(outcome)")
        }
    }

    func testAddContactSharedCourseRequiredSetsCopyAndOutcome() async {
        let repository = ContactStudentRepositoryStub()
        repository.simulateSharedCourseRequiredFor = "blocked@myci.csuci.edu"

        let viewModel = ContactsViewModel(studentRepository: repository)

        let outcome = await viewModel.addContact(email: "blocked@myci.csuci.edu")

        if case .sharedCourseRequired = outcome {} else {
            XCTFail("Expected .sharedCourseRequired; got \(outcome)")
        }
        XCTAssertEqual(viewModel.errorMessage, "You and this person need to share at least one course.")
    }

    func testAddContactStudentNotFoundSurfacesCopy() async {
        let repository = ContactStudentRepositoryStub()
        let viewModel = ContactsViewModel(studentRepository: repository)

        let outcome = await viewModel.addContact(email: "missing@myci.csuci.edu")

        if case .studentNotFound = outcome {} else {
            XCTFail("Expected .studentNotFound; got \(outcome)")
        }
        XCTAssertEqual(viewModel.errorMessage, "We couldn't find a CIApp account with that email.")
    }

    func testAddContactRateLimitedSurfacesCopy() async {
        let repository = ContactStudentRepositoryStub()
        repository.simulateRateLimit = true

        let viewModel = ContactsViewModel(studentRepository: repository)

        let outcome = await viewModel.addContact(email: "anyone@myci.csuci.edu")

        if case .rateLimited = outcome {} else {
            XCTFail("Expected .rateLimited; got \(outcome)")
        }
        XCTAssertEqual(viewModel.errorMessage, "Slow down a moment, then try again.")
    }

    func testRemoveContactUpdatesPublishedContacts() async {
        let repository = ContactStudentRepositoryStub()
        let viewModel = ContactsViewModel(studentRepository: repository)
        await viewModel.loadContacts()

        await viewModel.removeContact(contactStudentId: "contact-1")

        XCTAssertEqual(viewModel.contacts.map(\.id), ["contact-2"])
        XCTAssertFalse(viewModel.isContact(studentId: "contact-1"))
        XCTAssertNil(viewModel.errorMessage)
    }

    func testAddContactWithEmptyEmailReturnsFailedOutcome() async {
        let repository = ContactStudentRepositoryStub()
        let viewModel = ContactsViewModel(studentRepository: repository)

        let outcome = await viewModel.addContact(email: "")

        if case .failed = outcome {} else {
            XCTFail("Expected .failed; got \(outcome)")
        }
        XCTAssertEqual(viewModel.errorMessage, "Enter a contact email.")
    }

    func testShortSearchPublishesHintWithoutCallingRepository() async {
        let repository = ContactStudentRepositoryStub()
        let viewModel = ContactsViewModel(studentRepository: repository)

        await viewModel.searchContactStudents(query: "se")

        XCTAssertTrue(viewModel.shouldShowShortSearchHint)
        XCTAssertTrue(viewModel.searchResults.isEmpty)
        XCTAssertEqual(repository.searchCallCount, 0)
        XCTAssertNil(viewModel.searchErrorMessage)
    }

    func testPrepareSearchUpdatesStateWithoutCallingRepository() async {
        let repository = ContactStudentRepositoryStub()
        let viewModel = ContactsViewModel(studentRepository: repository)

        viewModel.prepareContactSearch(query: "ser")

        XCTAssertEqual(viewModel.searchQuery, "ser")
        XCTAssertTrue(viewModel.isSearchActive)
        XCTAssertTrue(viewModel.isSearching)
        XCTAssertEqual(repository.searchCallCount, 0)
    }

    func testSearchContactsPublishesNameAndEmailMatches() async {
        let repository = ContactStudentRepositoryStub()
        let viewModel = ContactsViewModel(studentRepository: repository)

        await viewModel.searchContactStudents(query: "ser")

        XCTAssertEqual(viewModel.searchResults.map(\.id), ["search-1"])
        XCTAssertFalse(viewModel.shouldShowShortSearchHint)
        XCTAssertNil(viewModel.searchErrorMessage)

        await viewModel.searchContactStudents(query: "maya@")

        XCTAssertEqual(viewModel.searchResults.map(\.id), ["search-2"])
    }

    func testSearchContactsPublishesReadableError() async {
        let repository = ContactStudentRepositoryStub()
        repository.searchError = NSError(
            domain: "APIError",
            code: 403,
            userInfo: [NSLocalizedDescriptionKey: "Unable to search contacts"]
        )
        let viewModel = ContactsViewModel(studentRepository: repository)

        await viewModel.searchContactStudents(query: "ser")

        XCTAssertTrue(viewModel.searchResults.isEmpty)
        XCTAssertEqual(viewModel.searchErrorMessage, "Unable to search contacts")
    }
}

private final class ContactStudentRepositoryStub: StudentRepositoryProtocol {

    var availableContacts: [String: ContactStudent] = [
        "contact.one@myci.csuci.edu": ContactStudent(
            id: "contact-1",
            name: "Contact One",
            email: "contact.one@myci.csuci.edu"
        ),
        "contact.two@myci.csuci.edu": ContactStudent(
            id: "contact-2",
            name: "Contact Two",
            email: "contact.two@myci.csuci.edu"
        )
    ]

    var storedContacts: [ContactStudent]
    var searchCallCount = 0
    var searchError: Error?
    var searchDirectory: [StudentSharedCourses] = [
        StudentSharedCourses(
            id: "search-1",
            name: "Sergio Student",
            email: "sergio.student@myci.csuci.edu",
            sharedCourseCount: 2
        ),
        StudentSharedCourses(
            id: "search-2",
            name: "Maya Contact",
            email: "maya@myci.csuci.edu",
            sharedCourseCount: 1
        ),
        StudentSharedCourses(
            id: "search-3",
            name: "No Shared",
            email: "not.shared@myci.csuci.edu",
            sharedCourseCount: 0
        )
    ]

    init() {
        storedContacts = [
            ContactStudent(id: "contact-1", name: "Contact One", email: "contact.one@myci.csuci.edu"),
            ContactStudent(id: "contact-2", name: "Contact Two", email: "contact.two@myci.csuci.edu")
        ]
    }

    func loadStudent() async throws -> Student {
        Student(id: "student-1", name: "Student", email: "student@email.com", courses: [], events: [])
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

    func addStudentContact(email: String) async throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard let contact = availableContacts[normalizedEmail] else {
            throw NSError(
                domain: "APIError",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Contact student not found"]
            )
        }

        guard !storedContacts.contains(where: { $0.id == contact.id }) else {
            throw NSError(
                domain: "APIError",
                code: 409,
                userInfo: [NSLocalizedDescriptionKey: "Contact already exists"]
            )
        }

        storedContacts.append(contact)
        storedContacts.sort { $0.name < $1.name }
    }

    func loadStudentContacts() async throws -> [ContactStudent] {
        storedContacts
    }

    func deleteStudentContact(contactStudentId: String) async throws {
        storedContacts.removeAll { $0.id == contactStudentId }
    }

    func hasStudentContact(contactStudentId: String) async throws -> Bool {
        storedContacts.contains { $0.id == contactStudentId }
    }

    func searchContactStudents(query: String) async throws -> [StudentSharedCourses] {
        searchCallCount += 1

        if let searchError {
            throw searchError
        }

        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return searchDirectory.filter { student in
            student.sharedCourseCount > 0
            && !storedContacts.contains { contact in contact.id == student.id }
            && (
                student.name.lowercased().contains(normalizedQuery)
                || student.email.lowercased().contains(normalizedQuery)
            )
        }
    }

    func updateScheduleTimes(meetings: [MeetingProposal]) async throws {}

    func loadStudentSharedCourses() async throws -> [StudentSharedCourses] { [] }

    var autoAcceptOnSend = false
    var simulateRateLimit = false
    var simulateSharedCourseRequiredFor: String?

    func sendContactRequest(toEmail email: String) async throws -> SendContactRequestResponse {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if simulateRateLimit {
            throw NSError(
                domain: "APIError",
                code: 429,
                userInfo: [NSLocalizedDescriptionKey: "Too many contact requests"]
            )
        }

        if let blocked = simulateSharedCourseRequiredFor, blocked.lowercased() == normalizedEmail {
            throw NSError(
                domain: "APIError",
                code: 403,
                userInfo: [NSLocalizedDescriptionKey: "Contacts must share at least one course"]
            )
        }

        guard let contact = availableContacts[normalizedEmail] else {
            throw NSError(
                domain: "APIError",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Contact student not found"]
            )
        }

        if storedContacts.contains(where: { $0.id == contact.id }) {
            throw NSError(
                domain: "APIError",
                code: 409,
                userInfo: [NSLocalizedDescriptionKey: "Students are already contacts"]
            )
        }

        if autoAcceptOnSend {
            // Mimic the lambda's auto-accept path: server-side mutual contact
            // is created, so the stub appends to storedContacts before returning.
            storedContacts.append(contact)
            storedContacts.sort { $0.name < $1.name }
            return SendContactRequestResponse(
                success: true,
                status: "accepted",
                autoAccepted: true,
                requestId: 1,
                contactStudentId: contact.id,
                conversationId: 99
            )
        }

        return SendContactRequestResponse(
            success: true,
            status: "pending",
            autoAccepted: nil,
            requestId: 1,
            contactStudentId: contact.id,
            conversationId: nil
        )
    }

    func loadContactRequests(status: String?, direction: String?, limit: Int?) async throws -> ContactRequestListResponse {
        ContactRequestListResponse(
            success: true,
            studentId: nil,
            statusFilter: status,
            directionFilter: direction,
            incoming: [],
            outgoing: [],
            counts: ContactRequestListResponse.Counts(
                incomingPending: 0,
                outgoingPending: 0,
                totalPending: 0
            )
        )
    }

    func acceptContactRequest(requestId: Int) async throws -> ContactRequestActionResponse {
        ContactRequestActionResponse(
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
        ContactRequestActionResponse(
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
        ContactRequestActionResponse(
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
