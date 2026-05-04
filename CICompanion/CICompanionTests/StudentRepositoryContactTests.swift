//
//  StudentRepositoryContactTests.swift
//  CICompanionTests
//

import XCTest
@testable import CICompanion

@MainActor
final class StudentRepositoryContactTests: XCTestCase {

    func testMockRepositoryAddsLoadsAndChecksContact() async throws {
        let repository = StudentRepository()

        try await repository.addStudentContact(email: "sergio.macias207@myci.csuci.edu")

        let contacts = try await repository.loadStudentContacts()
        XCTAssertEqual(contacts.count, 1)
        XCTAssertEqual(contacts.first?.email, "sergio.macias207@myci.csuci.edu")

        let hasContact = try await repository.hasStudentContact(contactStudentId: "b9d959de-9091-70c6-dc3b-cd0519f3a0c9")
        XCTAssertTrue(hasContact)
    }

    func testMockRepositoryPreventsDuplicateContacts() async throws {
        let repository = StudentRepository()

        try await repository.addStudentContact(email: "sergio.macias207@myci.csuci.edu")

        do {
            try await repository.addStudentContact(email: "sergio.macias207@myci.csuci.edu")
            XCTFail("Expected duplicate contact add to throw")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "APIError")
            XCTAssertEqual(error.code, 409)
            XCTAssertEqual(error.localizedDescription, "Contact already exists")
        }
    }

    func testMockRepositoryDeletesContact() async throws {
        let repository = StudentRepository()

        try await repository.addStudentContact(email: "sergio.macias207@myci.csuci.edu")
        try await repository.deleteStudentContact(contactStudentId: "b9d959de-9091-70c6-dc3b-cd0519f3a0c9")

        let contacts = try await repository.loadStudentContacts()
        XCTAssertTrue(contacts.isEmpty)

        let hasContact = try await repository.hasStudentContact(contactStudentId: "b9d959de-9091-70c6-dc3b-cd0519f3a0c9")
        XCTAssertFalse(hasContact)
    }

    func testMockRepositorySearchesSharedContactsByNameAndEmail() async throws {
        let repository = StudentRepository()

        let nameMatches = try await repository.searchContactStudents(query: "sergio")
        XCTAssertEqual(nameMatches.map(\.id), ["b9d959de-9091-70c6-dc3b-cd0519f3a0c9"])

        let emailMatches = try await repository.searchContactStudents(query: "wummiez")
        XCTAssertEqual(emailMatches.map(\.id), ["d9e9d9be-b021-703b-62f8-f1eef1eb72a2"])
    }

    func testMockRepositorySearchExcludesExistingContacts() async throws {
        let repository = StudentRepository()

        try await repository.addStudentContact(email: "sergio.macias207@myci.csuci.edu")

        let results = try await repository.searchContactStudents(query: "sergio")
        XCTAssertTrue(results.isEmpty)
    }

    func testMockRepositoryRejectsExactEmailAddWithoutSharedCourse() async throws {
        let repository = StudentRepository()

        do {
            try await repository.addStudentContact(email: "not.shared@myci.csuci.edu")
            XCTFail("Expected non-shared contact add to throw")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "APIError")
            XCTAssertEqual(error.code, 403)
            XCTAssertEqual(error.localizedDescription, "Contacts must share at least one course")
        }
    }
}
