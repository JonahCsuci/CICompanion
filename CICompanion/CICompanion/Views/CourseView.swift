//
//  CourseView.swift
//  CICompanion
//
//  Created by Emma on 3/23/26.
//

import SwiftUI

struct CourseView: View {
    @StateObject var courseViewModel : CourseViewModel
    
    init(course: Course, courseViewModel: CourseViewModel) {
        _courseViewModel = StateObject(wrappedValue: courseViewModel)
    }
    
    var body: some View {
            Text(courseViewModel.course.courseName)
            Text(courseViewModel.course.courseCode)
            Text(courseViewModel.course.instructor)
            Text(courseViewModel.course.location)
            Text(courseViewModel.course.startTime + " to " + courseViewModel.course.endTime)
            Text(courseViewModel.getDatesDisplay(course: courseViewModel.course))
            Text(courseViewModel.course.isAsynchronous ? "Asynchronous" : "Synchronous")

    }
}

#Preview {
    EventsView()
}
