//
//  StudentCoursesView.swift
//  CICompanion
//
//  Created by Wummiez on 3/6/26.
//

import SwiftUI


struct StudentCoursesView: View {
    
    @StateObject var viewModel: StudentCoursesViewModel
    @State private var isShowingCalendar = false
    
    let coursesListViewModel: CoursesListViewModel
    let myAcademicCalendarViewModel: AcademicCalendarViewModel
    
    init(
        viewModel: StudentCoursesViewModel,
        coursesListViewModel: CoursesListViewModel,
        myAcademicCalendarViewModel: AcademicCalendarViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.coursesListViewModel = coursesListViewModel
        self.myAcademicCalendarViewModel = myAcademicCalendarViewModel
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                NavigationLink {
                    CoursesListView(viewModel: coursesListViewModel)
                } label: {
                    HStack {
                        Text("Manage Courses")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Divider()
                
                List(viewModel.courses) { course in
                    VStack(alignment: .leading) {
                        Text(course.courseName)
                        Text(course.courseCode)
                    }
                }
                
                ScheduleBottomBannerView(
                    isShowingCalendar: false,
                    onScheduleTapped: {},
                    onCalendarTapped: {
                        isShowingCalendar = true
                    }
                )
            }
            .navigationTitle("My Schedule")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: NotificationSettingsView(courses: viewModel.courses)) {
                        Label("Notification Settings", systemImage: "gearshape")
                            .labelStyle(.iconOnly)
                    }
                }
            }
            .onAppear {
                viewModel.loadStudentCourses()
            }
            .onChange(of: viewModel.courses) {
                Task {
                    await NotificationSchedulerService.shared.rescheduleNotifications(for: viewModel.courses)
                }
            }
            .navigationDestination(isPresented: $isShowingCalendar) {
                AcademicCalendarView(viewModel: myAcademicCalendarViewModel)
            }
        }

    }
}

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
        )
    )
}
