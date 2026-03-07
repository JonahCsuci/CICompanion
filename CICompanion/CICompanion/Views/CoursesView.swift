//
//  CoursesView.swift
//  CICompanion
//
//  Created by Wummiez on 3/6/26.
//

import SwiftUI


struct CoursesView: View {
    
    @StateObject var viewModel: CourseViewModel
    
    init(viewModel: CourseViewModel) {
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
            viewModel.loadCourses()
        }
    }
}

#Preview {
    CoursesView(viewModel: CourseViewModel(repository: CourseRepository()))
}
