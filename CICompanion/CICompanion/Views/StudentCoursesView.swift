//
//  StudentCoursesView.swift
//  CICompanion
//
//  Displays the student's enrolled courses with navigation to
//  course management and the academic calendar.
//

import SwiftUI

// MARK: - StudentCoursesView

/// Shows the student's current schedule with a "Manage Courses" link,
/// a course list, and a bottom banner for switching to the calendar view.
struct StudentCoursesView: View {

    // MARK: - Dependencies

    @StateObject var viewModel: StudentCoursesViewModel
    @ObservedObject var sessionManager: SessionManager
    @State private var isShowingCalendar = false

    let coursesListViewModel: CoursesListViewModel
    let myAcademicCalendarViewModel: AcademicCalendarViewModel

    init(
        viewModel: StudentCoursesViewModel,
        coursesListViewModel: CoursesListViewModel,
        myAcademicCalendarViewModel: AcademicCalendarViewModel,
        sessionManager: SessionManager
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.coursesListViewModel = coursesListViewModel
        self.myAcademicCalendarViewModel = myAcademicCalendarViewModel
        self.sessionManager = sessionManager
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                manageCoursesLink
                Divider()
                courseList
                scheduleBottomBanner
            }
            .navigationTitle("My Schedule")
            .toolbar { settingsToolbarItem }
            .onAppear { viewModel.loadStudentCourses() }
            .onChange(of: viewModel.courses) { rescheduleNotifications() }
            .navigationDestination(isPresented: $isShowingCalendar) {
                AcademicCalendarView(
                    viewModel: myAcademicCalendarViewModel,
                    sessionManager: sessionManager
                )
            }
        }
    }
}

private extension StudentCoursesView {

    /// Row that navigates to the full course catalogue.
    var manageCoursesLink: some View {
        NavigationLink {
            CoursesListView(viewModel: coursesListViewModel)
        } label: {
            HStack {
                Text("Manage Courses")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Scrollable list of the student's enrolled courses.
    var courseList: some View {
        List(viewModel.courses) { course in
            VStack(alignment: .leading) {
                Text(course.courseName)
                Text(course.courseCode)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }

    /// Bottom banner with Schedule / Calendar toggle.
    var scheduleBottomBanner: some View {
        ScheduleBottomBannerView(
            isShowingCalendar: false,
            onScheduleTapped: {},
            onCalendarTapped: { isShowingCalendar = true }
        )
    }

    /// Gear icon linking to Notification Settings.
    var settingsToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            NavigationLink(destination: NotificationSettingsView(courses: viewModel.courses)) {
                Label("Notification Settings", systemImage: "gearshape")
                    .labelStyle(.iconOnly)
            }
        }
    }
}

private extension StudentCoursesView {

    /// Re-creates all local notifications when the course list changes.
    func rescheduleNotifications() {
        Task {
            await NotificationSchedulerService.shared.rescheduleNotifications(for: viewModel.courses)
        }
    }
}

// MARK: - Preview

#Preview {
    StudentCoursesView(
        viewModel: StudentCoursesViewModel(
            courseRepository: CourseRepository(studentRepository: StudentRepository()),
            studentRepository: StudentRepository()
        ),
        coursesListViewModel: CoursesListViewModel(
            courseRepository: CourseRepository(studentRepository: StudentRepository()),
            studentRepository: StudentRepository()
        ),
        myAcademicCalendarViewModel: AcademicCalendarViewModel(
            courseRepository: CourseRepository(studentRepository: StudentRepository()),
            studentRepository: StudentRepository()
        ),
        sessionManager: SessionManager()
    )
}
