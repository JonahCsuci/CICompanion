//
//  StudentCoursesView.swift
//  CICompanion
//
//  Created by Wummiez on 3/6/26.
//

import SwiftUI


struct StudentCoursesView: View {
    
    @StateObject var viewModel: StudentCoursesViewModel
    let addClassViewModel: AddClassViewModel
    
    init(
        viewModel: StudentCoursesViewModel,
        addClassViewModel: AddClassViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.addClassViewModel = addClassViewModel
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
                    NavigationLink("Add Class") {
                        AddClassView(viewModel: addClassViewModel)
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
        addClassViewModel: AddClassViewModel(
            courseRepository: CourseRepository(studentRepository: StudentRepository()),
            studentRepository: StudentRepository()
        )
    )
}
