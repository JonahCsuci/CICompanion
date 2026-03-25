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
                    NavigationLink("Manage Courses") {
                        CoursesListView(viewModel: coursesListViewModel)
                    }
                }
            }
            .onAppear {
                viewModel.loadStudentCourses()
            }
            .navigationDestination(isPresented: $isShowingCalendar) {
                AcademicCalendarView(viewModel: myAcademicCalendarViewModel)
            }
        }
        .navigationTitle("My Courses")
        .toolbar {
            // Gear icon in the top-right corner opens Notification Settings
            ToolbarItem(placement: .topBarTrailing) {
                // Pass the current course list so the settings page
                // can reschedule notifications when preferences change
                NavigationLink(destination: NotificationSettingsView(courses: viewModel.courses)) {
                    Label("Notification Settings", systemImage: "gearshape")
                        .labelStyle(.iconOnly)
                }
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
