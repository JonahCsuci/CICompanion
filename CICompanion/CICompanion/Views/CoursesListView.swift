//
//  CoursesView.swift
//  CICompanion
//
//  Created by Wummiez on 3/6/26.
//

import SwiftUI


struct CoursesListView: View {

    @StateObject var viewModel: CoursesListViewModel
    @ObservedObject var sessionManager: SessionManager
    @ObservedObject var tutorViewModel: TutorViewModel

    let courseRepository: CourseRepositoryProtocol
    let studentRepository: StudentRepositoryProtocol

    @State private var selectedSubject = "All"
    @State private var expandedCourseID: Int?
    @State private var showSettings = false
    @State private var showSignIn = false

    init(
        viewModel: CoursesListViewModel,
        courseRepository: CourseRepositoryProtocol,
        studentRepository: StudentRepositoryProtocol,
        sessionManager: SessionManager,
        tutorViewModel: TutorViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.courseRepository = courseRepository
        self.studentRepository = studentRepository
        self.sessionManager = sessionManager
        self.tutorViewModel = tutorViewModel
    }

    var body: some View {
        NavigationStack {
            CIView {
                CIHeader {
                    HStack(spacing: ViewHelper.spacing) {
                        settingsButton

                        CIPageTitle("myCourses")

                        Spacer()

                        NavigationLink {
                            ManageMyCoursesView(viewModel: viewModel)
                        } label: {
                            Text("Manage")
                                .font(.system(size: ViewHelper.smallTextSize, weight: .semibold))
                                .foregroundColor(ViewHelper.textImportant)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(ViewHelper.fieldBgColor)
                                .cornerRadius(ViewHelper.componentRounding)
                                .overlay {
                                    RoundedRectangle(cornerRadius: ViewHelper.componentRounding)
                                        .stroke(ViewHelper.text.opacity(0.25), lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }

                    searchField

                    subjectFilter
                        .padding(.bottom, ViewHelper.spacing)
                }

                if !sessionManager.isSignedIn {
                    signInPrompt
                } else if viewModel.isLoading && viewModel.courses.isEmpty {
                    CILoadingPage()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    catalogList
                }
            }
            .task {
                viewModel.loadAllCourses(for: sessionManager.userId)
            }
            .onChange(of: sessionManager.userId) { _, newUserId in
                selectedSubject = "All"
                expandedCourseID = nil
                viewModel.handleSessionChanged(to: newUserId)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(
                    courseRepository: courseRepository,
                    studentRepository: studentRepository,
                    tutorViewModel: tutorViewModel,
                    sessionManager: sessionManager
                )
            }
            .sheet(isPresented: $showSignIn) {
                SignInView(sessionManager: sessionManager)
            }
        }
    }

    private var settingsButton: some View {
        Button {
            showSettings = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: ViewHelper.navIconSize, weight: .semibold))
                .foregroundColor(ViewHelper.textImportant)
                .frame(width: ViewHelper.navButtonSize, height: ViewHelper.navButtonSize)
                .background(Circle().fill(ViewHelper.fieldBgColor))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Settings")
    }

    private var signInPrompt: some View {
        VStack {
            Spacer()

            Text("Sign in to view your courses")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(ViewHelper.textImportant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Button {
                showSignIn = true
            } label: {
                Text("Sign In")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ViewHelper.textImportant)
                    .frame(width: 200, height: 50)
                    .background(ViewHelper.accentBlue)
                    .cornerRadius(ViewHelper.componentRounding)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var searchField: some View {
        HStack(spacing: ViewHelper.spacing) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(ViewHelper.text)

            TextField(
                "",
                text: $viewModel.searchQuery,
                prompt: Text("Search subject, class, or professor").foregroundColor(ViewHelper.text)
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .foregroundColor(ViewHelper.textImportant)
            .font(.system(size: ViewHelper.textSize))
        }
        .padding(ViewHelper.padding)
        .background(ViewHelper.fieldBgColor)
        .cornerRadius(ViewHelper.componentRounding)
    }

    private var subjectFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ViewHelper.spacing) {
                ForEach(subjects, id: \.self) { subject in
                    Button {
                        selectedSubject = subject
                    } label: {
                        Text(subject)
                            .font(.system(size: ViewHelper.smallTextSize, weight: .semibold))
                            .foregroundColor(selectedSubject == subject ? .white : ViewHelper.text)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(selectedSubject == subject ? ViewHelper.accentBlue : ViewHelper.fieldBgColor)
                            .cornerRadius(ViewHelper.componentRounding)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var catalogList: some View {
        CIScrollView {
            if let errorMessage = viewModel.errorMessage {
                CIText(errorMessage, color: ViewHelper.accentRed)
                    .padding(.bottom, ViewHelper.spacing)
            }

            if filteredCourses.isEmpty {
                VStack(alignment: .leading, spacing: ViewHelper.spacing) {
                    CIText("No matching courses", color: ViewHelper.textImportant, fontWeight: .bold)
                    Text("Try another subject, course title, or professor name.")
                        .font(.system(size: ViewHelper.smallTextSize))
                        .foregroundColor(ViewHelper.text)
                }
                .padding(ViewHelper.padding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ViewHelper.fieldBgColor)
                .cornerRadius(ViewHelper.componentRounding)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredCourses) { course in
                        MyCourseCatalogRow(
                            course: course,
                            isExpanded: expandedCourseID == course.id,
                            isEnrolled: viewModel.isEnrolled(course),
                            onToggleExpanded: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    expandedCourseID = expandedCourseID == course.id ? nil : course.id
                                }
                            },
                            onAdd: {
                                viewModel.addCourse(course: course, for: sessionManager.userId)
                            }
                        )
                    }
                }
            }
        }
    }

    private var subjects: [String] {
        let values = Set(viewModel.courses.map { $0.springCourse.subject })
        return ["All"] + values.sorted()
    }

    private var filteredCourses: [Course] {
        let query = viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return viewModel.courses.filter { course in
            let subjectMatches = selectedSubject == "All" || course.springCourse.subject == selectedSubject

            let queryMatches = query.isEmpty
                || course.springCourse.subject.lowercased().contains(query)
                || course.courseName.lowercased().contains(query)
                || course.courseCode.lowercased().contains(query)
                || course.instructor.lowercased().contains(query)

            return subjectMatches && queryMatches
        }
    }
}

private struct MyCourseCatalogRow: View {
    let course: Course
    let isExpanded: Bool
    let isEnrolled: Bool
    let onToggleExpanded: () -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: ViewHelper.spacing) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: ViewHelper.iconSize, weight: .semibold))
                    .foregroundColor(ViewHelper.text)
                    .frame(width: 16)

                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor)
                    .frame(width: 3, height: 46)

                VStack(alignment: .leading, spacing: 5) {
                    Text("\(course.courseCode) - \(course.courseName)")
                        .font(.system(size: ViewHelper.textSize, weight: .bold))
                        .foregroundColor(accentColor)
                        .lineLimit(2)

                    Text(rowSubtitle)
                        .font(.system(size: ViewHelper.smallTextSize))
                        .foregroundColor(ViewHelper.text)
                        .lineLimit(1)
                }

                Spacer(minLength: ViewHelper.spacing)

                Button(action: onAdd) {
                    Image(systemName: isEnrolled ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(isEnrolled ? ViewHelper.accentGreen : ViewHelper.accentBlue)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .disabled(isEnrolled)
                .accessibilityLabel(isEnrolled ? "Course added" : "Add course")
            }
            .padding(ViewHelper.padding)
            .contentShape(Rectangle())
            .onTapGesture(perform: onToggleExpanded)

            if isExpanded {
                Divider()
                    .background(ViewHelper.text.opacity(0.2))

                CourseDetailsDropDown(course: course)
                    .padding(ViewHelper.padding)
            }
        }
        .background(ViewHelper.fieldBgColor)
        .cornerRadius(ViewHelper.componentRounding)
    }

    private var rowSubtitle: String {
        "\(course.springCourse.subject) • \(course.instructor) • \(course.scheduleSummary)"
    }

    private var accentColor: Color {
        let colors = [
            ViewHelper.accentBlue,
            ViewHelper.accentGreen,
            ViewHelper.accentPurple,
            ViewHelper.accentOrange,
            ViewHelper.accentPink
        ]
        return colors[abs(course.springCourse.subject.hashValue % colors.count)]
    }
}

struct CourseDetailsDropDown: View {
    let course: Course

    var body: some View {
        VStack(alignment: .leading, spacing: ViewHelper.biggerSpacing) {
            detailSection("Information") {
                detailRow("Class Number", "\(course.springCourse.classNumber)")
                detailRow("Subject", course.springCourse.subject)
                detailRow("Course Number", course.springCourse.courseNumber)
                detailRow("Section", course.springCourse.section)
                detailRow("Component", course.springCourse.component)
                detailRow("Title", course.springCourse.title)
                detailRow("Units", course.springCourse.units)
                detailRow("Description", course.springCourse.description)
                detailRow("Enrollment Requirements", course.springCourse.enrollmentRequirements ?? "None listed")
                detailRow("Class Notes", course.springCourse.classNotes ?? "None listed")
            }

            detailSection("Details") {
                detailRow("Instructor", course.springCourse.instructor ?? "Instructor TBD")
                detailRow("Meets", course.scheduleSummary)
                detailRow("Instruction Mode", course.springCourse.instructionMode)
                detailRow("Room", course.springCourse.room ?? "Arranged")
                detailRow("Campus", course.springCourse.campus)
                detailRow("Location", course.springCourse.location)
            }
        }
    }

    private func detailSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: ViewHelper.spacing) {
            Text(title.uppercased())
                .font(.system(size: ViewHelper.smallTextSize, weight: .bold))
                .foregroundColor(ViewHelper.text)

            content()
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: ViewHelper.smallTextSize))
                .foregroundColor(ViewHelper.text)

            Text(value)
                .font(.system(size: ViewHelper.smallTextSize + 2))
                .foregroundColor(ViewHelper.textImportant)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

}

private struct ManageMyCoursesView: View {
    @ObservedObject var viewModel: CoursesListViewModel
    @State private var expandedCourseID: Int?

    var body: some View {
        CIView {
            CIHeader {
                CIPageTitle("Manage Courses")
            }

            CIScrollView {
                if viewModel.studentCourses.isEmpty {
                    VStack(alignment: .leading, spacing: ViewHelper.spacing) {
                        CIText("No enrolled courses", fontWeight: .bold)
                        Text("Added courses will appear here.")
                            .font(.system(size: ViewHelper.smallTextSize))
                            .foregroundColor(ViewHelper.text)
                    }
                    .padding(ViewHelper.padding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ViewHelper.fieldBgColor)
                    .cornerRadius(ViewHelper.componentRounding)
                } else {
                    LazyVStack(spacing: ViewHelper.spacing) {
                        ForEach(viewModel.studentCourses) { course in
                            VStack(spacing: 0) {
                                HStack(spacing: ViewHelper.spacing) {
                                    Image(systemName: expandedCourseID == course.id ? "chevron.down" : "chevron.right")
                                        .font(.system(size: ViewHelper.iconSize, weight: .semibold))
                                        .foregroundColor(ViewHelper.text)
                                        .frame(width: 16)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(course.courseCode)
                                            .font(.system(size: ViewHelper.textSize, weight: .bold))
                                            .foregroundColor(ViewHelper.textImportant)

                                        Text(course.courseName)
                                            .font(.system(size: ViewHelper.smallTextSize))
                                            .foregroundColor(ViewHelper.text)
                                            .lineLimit(2)
                                    }

                                    Spacer()

                                    Button {
                                        viewModel.removeCourse(course: course)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 24, weight: .semibold))
                                            .foregroundColor(ViewHelper.accentRed)
                                            .frame(width: 38, height: 38)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Remove \(course.courseCode)")
                                }
                                .padding(ViewHelper.padding)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        expandedCourseID = expandedCourseID == course.id ? nil : course.id
                                    }
                                }

                                if expandedCourseID == course.id {
                                    Divider()
                                        .background(ViewHelper.text.opacity(0.2))

                                    CourseDetailsDropDown(course: course)
                                        .padding(ViewHelper.padding)
                                }
                            }
                            .background(ViewHelper.fieldBgColor)
                            .cornerRadius(ViewHelper.componentRounding)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    CoursesListView(
        viewModel: CoursesListViewModel(
            courseRepository: CourseRepository(studentRepository: StudentRepository()),
            studentRepository: StudentRepository()
        ),
        courseRepository: CourseRepository(studentRepository: StudentRepository()),
        studentRepository: StudentRepository(),
        sessionManager: SessionManager(),
        tutorViewModel: TutorViewModel(tutorRepository: TutorRepository())
    )
}
