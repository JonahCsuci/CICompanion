//
//  APITestView.swift
//  CICompanion
//
//  Debug-only view for exercising every API endpoint.
//  Presents load / add / delete buttons for courses and events,
//  with inline result lists below.
//

import SwiftUI

// MARK: - APITestView

/// Developer test harness for verifying API repository behaviour.
///
/// Not shipped in production — guarded behind a debug flag or hidden menu.
struct APITestView: View {

    // MARK: - Dependencies

    @StateObject var viewModel: APITestViewModel

    init(viewModel: APITestViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                statusBanner
                actionButtons
                resultsSection
            }
            .padding()
        }
    }
}

private extension APITestView {

    /// Shows the latest status / error message from the view model.
    var statusBanner: some View {
        Text(viewModel.statusMessage)
            .padding()
    }

    /// Grouped action buttons for load, add, and delete operations.
    var actionButtons: some View {
        VStack(spacing: 12) {
            loadButtons
            courseActionRow(label: "Add Course",    action: viewModel.testAddCourse)
            courseActionRow(label: "Delete Course",  action: viewModel.testDeleteCourse)
            eventActionRow(label: "Add Event",      action: viewModel.testAddEvent)
            eventActionRow(label: "Delete Event",   action: viewModel.testDeleteEvent)
        }
    }

    /// Load Courses / Student Courses / Events / Student Events.
    var loadButtons: some View {
        Group {
            styledButton("Load Courses")          { viewModel.testLoadCourses() }
            styledButton("Load Student Courses")   { viewModel.testLoadStudentCourses() }
            styledButton("Load Events")            { viewModel.testLoadEvents() }
            styledButton("Load Student Events")    { viewModel.testLoadStudentEvents() }
        }
    }

    /// A pair of buttons (id 1 & 2) for course add/delete actions.
    func courseActionRow(label: String, action: @escaping (Int) -> Void) -> some View {
        HStack(spacing: 10) {
            styledButton("\(label) 1") { action(1) }
            styledButton("\(label) 2") { action(2) }
        }
    }

    /// A pair of buttons (id 1 & 2) for event add/delete actions.
    func eventActionRow(label: String, action: @escaping (Int) -> Void) -> some View {
        HStack(spacing: 10) {
            styledButton("\(label) 1") { action(1) }
            styledButton("\(label) 2") { action(2) }
        }
    }

    /// Reusable bordered-prominent button.
    func styledButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.borderedProminent)
    }
}

private extension APITestView {

    /// All four result lists stacked vertically.
    var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            resultList(title: "Courses", items: viewModel.courses) {
                "\($0.courseName): \($0.courseCode)"
            }
            resultList(title: "Student Courses", items: viewModel.studentCourses) {
                "\($0.courseName): \($0.courseCode)"
            }
            resultList(title: "Events", items: viewModel.events) {
                "\($0.eventTitle): \($0.eventTime)"
            }
            resultList(title: "Student Events", items: viewModel.studentEvents) {
                "\($0.eventTitle): \($0.eventTime)"
            }
        }
    }

    /// Generic labelled list rendering.
    func resultList<T: Identifiable>(
        title: String,
        items: [T],
        display: @escaping (T) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTheme.Fonts.headline)

            ForEach(items) { item in
                Text(display(item))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
