//
//  AddClassView.swift
//  CICompanion
//
//  Created by Codex on 3/23/26.
//

import SwiftUI

struct AddClassView: View {
    
    @StateObject var viewModel: AddClassViewModel
    
    init(viewModel: AddClassViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        List {
            if let successMessage = viewModel.successMessage {
                Text(successMessage)
                    .foregroundStyle(.green)
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
            
            ForEach(viewModel.courses) { course in
                VStack(alignment: .leading, spacing: 8) {
                    Text(course.courseName)
                        .font(.headline)
                    Text(course.courseCode)
                    Text(course.instructor)
                    Text(course.location)
                    
                    Button("Add") {
                        viewModel.addCourse(course)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Add Class")
        .onAppear {
            viewModel.loadAvailableCourses()
        }
    }
}

#Preview {
    AddClassView(
        viewModel: AddClassViewModel(
            courseRepository: CourseRepository(studentRepository: StudentRepository()),
            studentRepository: StudentRepository()
        )
    )
}
