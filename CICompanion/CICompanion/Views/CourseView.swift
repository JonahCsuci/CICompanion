//
//  CourseView.swift
//  CICompanion
//
//  Created by Emma on 3/23/26.
//

import SwiftUI

struct CourseView: View {
    @StateObject var viewModel : CourseViewModel
    
    init(course: Course) {
        _viewModel = StateObject(wrappedValue: CourseViewModel(course: course))
    }
    
    var body: some View {
            Text(viewModel.course.courseName)
            Text(viewModel.course.courseCode)
            Text(viewModel.course.instructor)
            Text(viewModel.course.location)
            Text(viewModel.course.startTime + " to " + viewModel.course.endTime)
            Text(viewModel.getDatesDisplay(course: viewModel.course))
            Text(viewModel.course.isAsynchronous ? "Asynchronous" : "Synchronous")

    }
}

#Preview {
    EventsView()
}
