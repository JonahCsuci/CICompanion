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
}
