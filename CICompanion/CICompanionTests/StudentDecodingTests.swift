//
//  StudentDecodingTests.swift
//  CICompanionTests
//

import XCTest
@testable import CICompanion

final class StudentDecodingTests: XCTestCase {
    func testStudentDecodesCourseIDsFromJSONArray() throws {
        let data = """
        {
          "id": "student-1",
          "name": "Student One",
          "email": "student.one@myci.csuci.edu",
          "courses": [1892, 1081],
          "events": [],
          "meetings": []
        }
        """.data(using: .utf8)!

        let student = try JSONDecoder().decode(Student.self, from: data)

        XCTAssertEqual(student.courses, [1892, 1081])
        XCTAssertTrue(student.events.isEmpty)
        XCTAssertTrue(student.meetings.isEmpty)
    }

    func testStudentDecodesCourseIDsFromStringifiedJSONArray() throws {
        let data = """
        {
          "id": "student-1",
          "name": "Student One",
          "email": "student.one@myci.csuci.edu",
          "courses": "[1892, \\"1081\\"]",
          "events": "[]",
          "meetings": "[]"
        }
        """.data(using: .utf8)!

        let student = try JSONDecoder().decode(Student.self, from: data)

        XCTAssertEqual(student.courses, [1892, 1081])
        XCTAssertTrue(student.events.isEmpty)
        XCTAssertTrue(student.meetings.isEmpty)
    }
}
