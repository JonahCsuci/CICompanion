//
//  ContactStudentTests.swift
//  CICompanionTests
//

import XCTest
@testable import CICompanion

final class ContactStudentTests: XCTestCase {

    func testDecodesContactStudentSummary() throws {
        let data = Data("""
        {
          "id": "b9d959de-9091-70c6-dc3b-cd0519f3a0c9",
          "name": "Sergio",
          "email": "sergio.macias207@myci.csuci.edu"
        }
        """.utf8)

        let contact = try JSONDecoder().decode(ContactStudent.self, from: data)

        XCTAssertEqual(contact.id, "b9d959de-9091-70c6-dc3b-cd0519f3a0c9")
        XCTAssertEqual(contact.name, "Sergio")
        XCTAssertEqual(contact.email, "sergio.macias207@myci.csuci.edu")
    }
}
