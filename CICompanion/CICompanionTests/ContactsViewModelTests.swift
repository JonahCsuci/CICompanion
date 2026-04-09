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
}
