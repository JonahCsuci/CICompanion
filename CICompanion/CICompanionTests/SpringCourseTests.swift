//
//  SpringCourseTests.swift
//  CICompanionTests
//

import XCTest
@testable import CICompanion

final class SpringCourseTests: XCTestCase {

    func testSpringCourseCatalogDecodesBundledJSON() throws {
        let courses = try LocalCourseCatalog.loadCourses()

        XCTAssertEqual(courses.count, 1036)

        let firstCourse = try XCTUnwrap(courses.first)
        XCTAssertEqual(firstCourse.id, 1892)
        XCTAssertEqual(firstCourse.courseCode, "AAS 100-01")
        XCTAssertEqual(firstCourse.courseName, "Intro to Asian American Studie")
        XCTAssertEqual(firstCourse.instructor, "Lily Anne Tamai")
        XCTAssertEqual(firstCourse.location, "Gateway Hall 2502")
        XCTAssertEqual(firstCourse.scheduledOccurrences.count, 1)
        XCTAssertEqual(firstCourse.scheduledOccurrences.first?.days, ["Monday", "Wednesday"])
        XCTAssertEqual(firstCourse.scheduledOccurrences.first?.startTime, "9:00AM")
        XCTAssertEqual(firstCourse.scheduledOccurrences.first?.endTime, "10:15AM")
    }

    func testSpringCourseCatalogHandlesNullableAndArrangedFields() throws {
        let courses = try LocalCourseCatalog.loadCourses()

        let emptyMeetingCourse = try XCTUnwrap(courses.first { $0.id == 2399 })
        XCTAssertEqual(emptyMeetingCourse.instructor, "Instructor TBD")
        XCTAssertTrue(emptyMeetingCourse.isAsynchronous)
        XCTAssertTrue(emptyMeetingCourse.scheduledOccurrences.isEmpty)
        XCTAssertEqual(emptyMeetingCourse.startTime, "N/A")
        XCTAssertEqual(emptyMeetingCourse.scheduleSummary, "Arranged")

        let arrangedCourse = try XCTUnwrap(courses.first { $0.id == 2309 })
        XCTAssertTrue(arrangedCourse.isAsynchronous)
        XCTAssertTrue(arrangedCourse.scheduledOccurrences.isEmpty)
        XCTAssertEqual(arrangedCourse.location, "Online")
    }

    func testSpringCourseCatalogClassNumbersAreUnique() throws {
        let courses = try LocalCourseCatalog.loadCourses()
        let ids = courses.map(\.id)

        XCTAssertEqual(Set(ids).count, ids.count)
    }
}

@MainActor
final class CourseRepositorySpringCatalogTests: XCTestCase {

    func testCourseRepositoryLoadsSpringCatalogAndFiltersStudentCourses() async throws {
        let studentRepository = RepositoryTestStudentRepository(courseIds: [1892, 2309])
        let repository = CourseRepository(studentRepository: studentRepository)

        let allCourses = try await repository.loadAllCourses()
        let studentCourses = try await repository.loadStudentCourses()

        XCTAssertEqual(allCourses.count, 1036)
        XCTAssertEqual(Set(studentCourses.map(\.id)), Set([1892, 2309]))
    }
}

@MainActor
final class AcademicCalendarSpringCourseTests: XCTestCase {

    func testBuildScheduleUsesScheduledMeetingsAndSkipsArrangedMeetings() {
        let viewModel = AcademicCalendarViewModel(
            courseRepository: EmptyCourseRepository(),
            studentRepository: RepositoryTestStudentRepository(courseIds: [])
        )

        let scheduledCourse = makeCourse(
            id: 1001,
            subject: "AAS",
            number: "100",
            meetingTimes: [
                SpringCourseMeetingTime(
                    type: "scheduled",
                    days: ["Monday", "Wednesday"],
                    startTime: "9:00AM",
                    endTime: "10:15AM",
                    room: "Gateway Hall 2502"
                )
            ]
        )

        let multiMeetingCourse = makeCourse(
            id: 1002,
            subject: "BIOL",
            number: "201",
            meetingTimes: [
                SpringCourseMeetingTime(
                    type: "scheduled",
                    days: ["Thursday"],
                    startTime: "9:00AM",
                    endTime: "10:15AM",
                    room: "Sierra Hall 1411"
                ),
                SpringCourseMeetingTime(
                    type: "scheduled",
                    days: ["Friday"],
                    startTime: "1:30PM",
                    endTime: "2:45PM",
                    room: "Sierra Hall 1411"
                )
            ]
        )

        let arrangedOnlyCourse = makeCourse(
            id: 1003,
            subject: "ACCT",
            number: "300",
            room: "Online",
            meetingTimes: [
                SpringCourseMeetingTime(
                    type: "arranged",
                    days: nil,
                    startTime: nil,
                    endTime: nil,
                    room: nil
                )
            ]
        )

        let emptyMeetingCourse = makeCourse(
            id: 1004,
            subject: "CHS",
            number: "150",
            room: nil,
            meetingTimes: []
        )

        let hybridCourse = makeCourse(
            id: 1005,
            subject: "MATH",
            number: "150",
            meetingTimes: [
                SpringCourseMeetingTime(
                    type: "scheduled",
                    days: ["Tuesday"],
                    startTime: "10:30AM",
                    endTime: "11:45AM",
                    room: "Bell Tower 1501"
                ),
                SpringCourseMeetingTime(
                    type: "arranged",
                    days: nil,
                    startTime: nil,
                    endTime: nil,
                    room: "Online"
                )
            ]
        )

        viewModel.buildSchedule(
            courses: [scheduledCourse, multiMeetingCourse, arrangedOnlyCourse, emptyMeetingCourse, hybridCourse],
            meetings: [],
            events: []
        )

        XCTAssertEqual(viewModel.scheduleBlocks.count, 5)
        XCTAssertEqual(Set(viewModel.scheduleBlocks.map(\.courseId)), Set([1001, 1002, 1005]))
        XCTAssertEqual(Set(viewModel.asyncCourses.map(\.id)), Set([1003, 1004]))
        XCTAssertTrue(viewModel.scheduleBlocks.contains { $0.courseId == 1005 && $0.day == "Tuesday" })
        XCTAssertFalse(viewModel.scheduleBlocks.contains { $0.courseId == 1003 })
        XCTAssertFalse(viewModel.scheduleBlocks.contains { $0.courseId == 1004 })
    }

    private func makeCourse(
        id: Int,
        subject: String,
        number: String,
        room: String? = "Room 100",
        meetingTimes: [SpringCourseMeetingTime]
    ) -> Course {
        Course(
            springCourse: SpringCourse(
                classNumber: id,
                subject: subject,
                courseNumber: number,
                section: "01",
                component: "LEC",
                title: "\(subject) \(number)",
                units: "3 units",
                instructor: "Instructor",
                instructionMode: room == "Online" ? "Online" : "In Person",
                room: room,
                campus: "Channel Islands Main Campus",
                location: "Channel Islands",
                description: "Course description",
                enrollmentRequirements: nil,
                classNotes: nil,
                meetingTimes: meetingTimes
            )
        )
    }
}

private final class EmptyCourseRepository: CourseRepositoryProtocol {
    func loadAllCourses() async throws -> [Course] { [] }
    func loadStudentCourses() async throws -> [Course] { [] }
}

private final class RepositoryTestStudentRepository: StudentRepositoryProtocol {
    private var student: Student

    init(courseIds: [Int]) {
        student = Student(
            id: "student-id",
            name: "Student",
            email: "student@myci.csuci.edu",
            courses: courseIds,
            events: []
        )
    }

    func loadStudent() async throws -> Student { student }

    func addStudentCourse(courseId: Int) async throws {
        if !student.courses.contains(courseId) {
            student.courses.append(courseId)
        }
    }

    func deleteStudentCourse(courseId: Int) async throws {
        student.courses.removeAll { $0 == courseId }
    }

    func ensureStudentExists() async throws -> Student { student }
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
            autoAccepted: false,
            requestId: nil,
            contactStudentId: nil,
            conversationId: nil
        )
    }
    func loadContactRequests(status: String?, direction: String?, limit: Int?) async throws -> ContactRequestListResponse {
        ContactRequestListResponse(
            success: true,
            studentId: student.id,
            statusFilter: status,
            directionFilter: direction,
            incoming: [],
            outgoing: [],
            counts: nil
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
            conversationId: nil
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
