//
//  CourseView.swift
//  CICompanion
//
//  Created by Emma on 3/23/26.
//

import SwiftUI

struct CourseView: View {
    @StateObject var courseViewModel : CourseViewModel
    @StateObject var courseListViewModel : CoursesListViewModel
    
    init(courseViewModel: CourseViewModel, coursesListViewModel: CoursesListViewModel) {
        _courseViewModel = StateObject(wrappedValue: courseViewModel)
        _courseListViewModel = StateObject(wrappedValue: coursesListViewModel)
    }
    
    var body: some View {
        Text(courseViewModel.course.courseName)
        Text(courseViewModel.course.courseCode)
        Text(courseViewModel.course.instructor)
        Text(courseViewModel.course.location)
        Text(courseViewModel.course.startTime + " to " + courseViewModel.course.endTime)
        Text(courseViewModel.getDatesDisplay(course: courseViewModel.course))
        Text(courseViewModel.course.isAsynchronous ? "Asynchronous" : "Synchronous")
        
        if (courseListViewModel.studentCourses.contains(where: { $0.id == courseViewModel.course.id })) {
            Button(role: .close) {
                courseListViewModel.removeCourse(course: courseViewModel.course)
            } label: {
                Label("Remove from Schedule", systemImage: "trash")
            }
            .tint(.red)
        } else {
            Button(role: .confirm) {
                courseListViewModel.addCourse(course: courseViewModel.course)
            } label: {
                Label("Add to Schedule", systemImage: "plus")
            }
            .tint(.blue)
        }
    }
}

#Preview {
    EventsView()
}
