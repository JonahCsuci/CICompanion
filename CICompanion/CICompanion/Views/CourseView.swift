//
//  CourseView.swift
//  CICompanion
//
//  Detail screen for a single course — shows all course metadata
//  and an add/remove action button.
//

import SwiftUI

// MARK: - CourseView

/// Displays the details of a single course and a button to add or remove it
/// from the student's schedule.
struct CourseView: View {

    // MARK: - Dependencies

    @StateObject var courseViewModel: CourseViewModel
    @StateObject var courseListViewModel: CoursesListViewModel

    init(courseViewModel: CourseViewModel, coursesListViewModel: CoursesListViewModel) {
        _courseViewModel  = StateObject(wrappedValue: courseViewModel)
        _courseListViewModel = StateObject(wrappedValue: coursesListViewModel)
    }

    /// Convenience accessor for the viewed course.
    private var course: Course { courseViewModel.course }

    /// Whether the student is currently enrolled in this course.
    private var isEnrolled: Bool {
        courseListViewModel.studentCourses.contains { $0.id == course.id }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            courseInfoSection
            enrollmentButton
        }
        .padding(AppTheme.Spacing.screen)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private extension CourseView {

    /// All read-only course metadata fields.
    var courseInfoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(course.courseName)
                .font(AppTheme.Fonts.courseName)

            Text(course.courseCode)
                .foregroundColor(AppTheme.Colors.textSecondary)

            Text(course.instructor)

            Text(course.location)
                .foregroundColor(AppTheme.Colors.textSecondary)

            Text("\(course.startTime) to \(course.endTime)")

            Text(courseViewModel.getDatesDisplay(course: course))

            Text(course.isAsynchronous ? "Asynchronous" : "Synchronous")
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }

    /// Add or Remove button depending on enrollment status.
    @ViewBuilder
    var enrollmentButton: some View {
        if isEnrolled {
            Button(role: .destructive) {
                courseListViewModel.removeCourse(course: course)
            } label: {
                Label("Remove from Schedule", systemImage: "trash")
            }
            .tint(AppTheme.Colors.error)
        } else {
            Button {
                courseListViewModel.addCourse(course: course)
            } label: {
                Label("Add to Schedule", systemImage: "plus")
            }
            .tint(AppTheme.Colors.actionPrimary)
        }
    }
}

// MARK: - Preview

#Preview {
    CourseView(
        courseViewModel: CourseViewModel(
            course: Course(
                id: 1,
                courseName: "Organization Management",
                courseCode: "MGT 101",
                instructor: "Dr. Smith",
                location: "Room 101",
                startTime: "9:00 AM",
                endTime: "10:00 AM",
                days: ["Monday", "Wednesday"],
                isAsynchronous: false,
                courseDescription: "An intro to organizational management."
            )
        ),
        coursesListViewModel: CoursesListViewModel(
            courseRepository: CourseRepository(studentRepository: StudentRepository()),
            studentRepository: StudentRepository()
        )
    )
}
