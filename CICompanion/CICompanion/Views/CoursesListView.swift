//
//  CoursesView.swift
//  CICompanion
//
//  Created by Wummiez on 3/6/26.
//

import SwiftUI


struct CoursesListView: View {
    
    @StateObject var viewModel: CoursesListViewModel
    
    init(viewModel: CoursesListViewModel) {
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
                    NavigationLink(destination: CourseView(course: course, courseViewModel: CourseViewModel(course: course))) {
                        Button(role: .confirm, action: {
                            
                        }) {
                            HStack() {
                                VStack(alignment: .leading) {
                                    Text(course.courseName)
                                    Text(course.courseCode)
                                }
                                
                                if (viewModel.studentCourses.contains(where: { $0.id == course.id })) {
                                    Spacer()
                                    
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            if (viewModel.studentCourses.contains(where: { $0.id == course.id })) {
                                Button(role: .close) {
                                    viewModel.removeCourse(course: course)
                                } label: {
                                    Label("Remove from Schedule", systemImage: "trash")
                                }
                                .tint(.red)
                            } else {
                                Button(role: .confirm) {
                                    viewModel.addCourse(course: course)
                                } label: {
                                    Label("Add to Schedule", systemImage: "plus")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                }
                .onAppear {
                    viewModel.loadAllCourses()
                }
                .navigationTitle("Course List")
            }
        }
    }
}

#Preview {
    CoursesListView(
        viewModel: CoursesListViewModel(
            courseRepository: CourseRepository(studentRepository: StudentRepository()),
            studentRepository: StudentRepository()
        )
    )
}
