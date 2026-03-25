//
//  StudentCoursesView.swift
//  CICompanion
//
//  Created by Wummiez on 3/6/26.
//

import SwiftUI


struct StudentCoursesView: View {
    
    @StateObject var viewModel: StudentCoursesViewModel
    
    init(viewModel: StudentCoursesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        List(viewModel.courses) { course in
            VStack(alignment: .leading) {
                Text(course.courseName)
                Text(course.courseCode)
            }
        }
        .onAppear {
            viewModel.loadStudentCourses()
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
        )
    )
}
