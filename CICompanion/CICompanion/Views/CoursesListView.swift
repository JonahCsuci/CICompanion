//
//  CoursesListView.swift
//  CICompanion
//
//  Displays the master list of all available courses.
//  Users can search, add courses to their schedule, or remove them via swipe actions.
//

import SwiftUI

// MARK: - CoursesListView

/// A searchable list of all courses with swipe actions for adding/removing.
///
/// Courses the student is already enrolled in show a checkmark.
/// Swipe right reveals "Add to Schedule"; swipe left reveals "Remove".
struct CoursesListView: View {

    // MARK: - Dependencies

    @StateObject var viewModel: CoursesListViewModel

    init(viewModel: CoursesListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            courseNavigationList
        }
    }
}

private extension CoursesListView {

    /// A capsule-shaped search bar pinned above the list.
    var searchBar: some View {
        HStack {
            TextField("Search Courses", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .onChange(of: viewModel.searchQuery) {
                    viewModel.search()
                }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(Capsule())
        .padding(.horizontal)
        .padding(.top, AppTheme.Spacing.screen)
    }

    /// The navigable course list with swipe actions.
    var courseNavigationList: some View {
        NavigationStack {
            List(viewModel.shownCourses) { course in
                NavigationLink(
                    destination: CourseView(
                        courseViewModel: CourseViewModel(course: course),
                        coursesListViewModel: viewModel
                    )
                ) {
                    courseRow(for: course)
                        .swipeActions(edge: .trailing) {
                            swipeAction(for: course)
                        }
                }
            }
            .onAppear { viewModel.loadAllCourses() }
            .navigationTitle("Course List")
        }
    }
}

private extension CoursesListView {

    /// Whether the student is currently enrolled in the given course.
    func isEnrolled(in course: Course) -> Bool {
        viewModel.studentCourses.contains { $0.id == course.id }
    }

    /// A single row showing the course name/code and an optional checkmark.
    func courseRow(for course: Course) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(course.courseName)
                Text(course.courseCode)
            }

            if isEnrolled(in: course) {
                Spacer()
                Image(systemName: "checkmark")
            }
        }
    }

    /// Contextual swipe action — add or remove depending on enrollment.
    @ViewBuilder
    func swipeAction(for course: Course) -> some View {
        if isEnrolled(in: course) {
            Button(role: .destructive) {
                viewModel.removeCourse(course: course)
            } label: {
                Label("Remove from Schedule", systemImage: "trash")
            }
            .tint(AppTheme.Colors.error)
        } else {
            Button {
                viewModel.addCourse(course: course)
            } label: {
                Label("Add to Schedule", systemImage: "plus")
            }
            .tint(AppTheme.Colors.actionPrimary)
        }
    }
}

// MARK: - Preview

#Preview {
    CoursesListView(
        viewModel: CoursesListViewModel(
            courseRepository: CourseRepository(studentRepository: StudentRepository()),
            studentRepository: StudentRepository()
        )
    )
}
