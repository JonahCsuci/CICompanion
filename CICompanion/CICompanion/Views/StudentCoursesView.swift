//
//  StudentCoursesView.swift
//  CICompanion
//
//  Created by Wummiez on 3/6/26.
//

import SwiftUI


struct StudentCoursesView: View {
    
    @StateObject var viewModel: StudentCoursesViewModel
    let coursesListViewModel: CoursesListViewModel
    
    init(
        viewModel: StudentCoursesViewModel,
        coursesListViewModel: CoursesListViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.coursesListViewModel = coursesListViewModel
    }
    
    var body: some View {
        NavigationStack {
            List(viewModel.courses) { course in
                VStack(alignment: .leading) {
                    Text(course.courseName)
                    Text(course.courseCode)
                }
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
        )
    )
}
