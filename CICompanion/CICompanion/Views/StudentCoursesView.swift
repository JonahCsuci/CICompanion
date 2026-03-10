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
            viewModel.loadAllCourses()
        }
    }
}

#Preview {
    StudentCoursesView(viewModel: StudentCoursesViewModel(repository: CourseRepository(studentRepository: StudentRepository())))
}
