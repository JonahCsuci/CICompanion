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

    func testAddContactReloadsContacts() async {
        let repository = ContactStudentRepositoryStub()
        repository.availableContacts["new.student@myci.csuci.edu"] = ContactStudent(
            id: "contact-3",
            name: "New Student",
            email: "new.student@myci.csuci.edu"
        )

        let viewModel = ContactsViewModel(studentRepository: repository)
        await viewModel.loadContacts()

        let added = await viewModel.addContact(email: "new.student@myci.csuci.edu")

        XCTAssertTrue(added)
        XCTAssertEqual(viewModel.contacts.count, 3)
        XCTAssertTrue(viewModel.isContact(studentId: "contact-3"))
        XCTAssertNil(viewModel.errorMessage)
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

    func testAddContactPublishesReadableError() async {
        let repository = ContactStudentRepositoryStub()
        let viewModel = ContactsViewModel(studentRepository: repository)

        let added = await viewModel.addContact(email: "")

        XCTAssertFalse(added)
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

    func addStudentEvent(eventId: Int) async throws {}

    func deleteStudentEvent(eventId: Int) async throws {}

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
}
