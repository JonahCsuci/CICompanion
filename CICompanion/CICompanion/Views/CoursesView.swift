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
        VStack(spacing:0) {
            HStack {
            
                TextField("Search Courses", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .onChange(of: viewModel.searchQuery) {
                        viewModel.search()
                    }
            }
            .padding(12)
            .background(.thinMaterial)
            .clipShape(Capsule())
            .padding(.horizontal)
            .padding(.top, 16)
            NavigationStack {
                List(viewModel.shownCourses) { course in
                    Button(role: .none, action: {
                        
                    }) {
                        VStack(alignment: .leading) {
                            Text(course.courseName)
                            Text(course.courseCode)
                        }
                    }
                }
                .onAppear {
                    viewModel.loadCourses()
                }
                .navigationTitle("Course List")
            }
        }
    }
}

#Preview {
    CoursesView(viewModel: CourseViewModel(repository: CourseRepository()))
}
