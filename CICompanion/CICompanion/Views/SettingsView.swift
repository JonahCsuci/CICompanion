//
//  SettingsView.swift
//  CICompanion
//
//  The Settings tab — provides class management (add/remove) and app preferences.
//

import SwiftUI

// MARK: - SettingsView

/// Root settings screen with sections for class management, preferences, and about.
struct SettingsView: View {

    // MARK: - Dependencies

    let courseRepository: CourseRepositoryProtocol
    let studentRepository: StudentRepositoryProtocol

    /// Authentication state — used for the sign-out action.
    @ObservedObject var sessionManager: SessionManager

    // MARK: - Local State

    @State private var showAddClass    = false
    @State private var showRemoveClass = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()

                List {
                    classesSection
                    preferencesSection
                    aboutSection
                    signOutSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showAddClass) {
                AddClassSheet(
                    courseRepository: courseRepository,
                    studentRepository: studentRepository
                )
            }
            .sheet(isPresented: $showRemoveClass) {
                RemoveClassSheet(
                    courseRepository: courseRepository,
                    studentRepository: studentRepository
                )
            }
        }
        .preferredColorScheme(.dark)
    }
}

private extension SettingsView {

    /// Add / Remove class buttons.
    var classesSection: some View {
        Section {
            Button { showAddClass = true } label: {
                Label("Add Class", systemImage: "plus.circle.fill")
            }

            Button { showRemoveClass = true } label: {
                Label("Remove Class", systemImage: "minus.circle.fill")
                    .foregroundColor(AppTheme.Colors.error)
            }
        } header: {
            Text("My Classes")
        }
    }

    /// Navigation to notification preferences.
    var preferencesSection: some View {
        Section {
            NavigationLink {
                NotificationSettingsView(courses: [])
            } label: {
                Label("Notifications", systemImage: "bell.fill")
            }
        } header: {
            Text("Preferences")
        }
    }

    /// Static version info.
    var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        } header: {
            Text("About")
        }
    }

    /// Sign-out button — ends the Amplify auth session.
    var signOutSection: some View {
        Section {
            Button {
                Task { await sessionManager.signOut() }
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(AppTheme.Colors.error)
            }
            .buttonStyle(.borderless)
        }
    }
}

// MARK: - Add Class Sheet

/// Modal that lists available courses the student can enroll in.
private struct AddClassSheet: View {

    let courseRepository: CourseRepositoryProtocol
    let studentRepository: StudentRepositoryProtocol
    @Environment(\.dismiss) private var dismiss

    @State private var availableCourses: [Course] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()

                if isLoading {
                    ProgressView().tint(.white)
                } else if availableCourses.isEmpty {
                    Text("All courses already added")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                } else {
                    courseList
                }
            }
            .navigationTitle("Add Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { cancelButton }
        }
        .preferredColorScheme(.dark)
        .task { await loadAvailableCourses() }
    }

    // MARK: Subviews

    private var courseList: some View {
        List(availableCourses) { course in
            Button {
                Task {
                    try? await studentRepository.addStudentCourse(courseId: course.id)
                    dismiss()
                }
            } label: {
                courseRow(course)
            }
            .listRowBackground(AppTheme.Colors.cardBackground)
        }
        .scrollContentBackground(.hidden)
    }

    private func courseRow(_ course: Course) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(course.courseCode) - \(course.courseName)")
                .font(AppTheme.Fonts.bodySemibold)
                .foregroundColor(AppTheme.Colors.textPrimary)

            HStack(spacing: 8) {
                Text(course.instructor)
                Text("•")
                Text(course.location)
            }
            .font(AppTheme.Fonts.smallCaption)
            .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(.vertical, 4)
    }

    private var cancelButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
    }

    // MARK: Data

    private func loadAvailableCourses() async {
        do {
            let all     = try await courseRepository.loadAllCourses()
            let student = try await studentRepository.loadStudent()
            availableCourses = all.filter { !student.courses.contains($0.id) }
        } catch {
            availableCourses = []
        }
        isLoading = false
    }
}

// MARK: - Remove Class Sheet

/// Modal that lists the student's enrolled courses for removal.
private struct RemoveClassSheet: View {

    let courseRepository: CourseRepositoryProtocol
    let studentRepository: StudentRepositoryProtocol
    @Environment(\.dismiss) private var dismiss

    @State private var studentCourses: [Course] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()

                if isLoading {
                    ProgressView().tint(.white)
                } else if studentCourses.isEmpty {
                    Text("No classes to remove")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                } else {
                    courseList
                }
            }
            .navigationTitle("Remove Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { cancelButton }
        }
        .preferredColorScheme(.dark)
        .task { await loadStudentCourses() }
    }

    // MARK: Subviews

    private var courseList: some View {
        List(studentCourses) { course in
            Button {
                Task {
                    try? await studentRepository.deleteStudentCourse(courseId: course.id)
                    dismiss()
                }
            } label: {
                courseRow(course)
            }
            .listRowBackground(AppTheme.Colors.cardBackground)
        }
        .scrollContentBackground(.hidden)
    }

    private func courseRow(_ course: Course) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(course.courseCode) - \(course.courseName)")
                    .font(AppTheme.Fonts.bodySemibold)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text(course.location)
                    .font(AppTheme.Fonts.smallCaption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()

            Image(systemName: "trash")
                .foregroundColor(AppTheme.Colors.error)
        }
        .padding(.vertical, 4)
    }

    private var cancelButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
    }

    // MARK: Data

    private func loadStudentCourses() async {
        do {
            studentCourses = try await courseRepository.loadStudentCourses()
        } catch {
            studentCourses = []
        }
        isLoading = false
    }
}

// MARK: - Preview

#Preview {
    SettingsView(
        courseRepository: CourseRepository(studentRepository: StudentRepository()),
        studentRepository: StudentRepository(),
        sessionManager: SessionManager()
    )
}
