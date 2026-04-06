//
//  NewAssignmentView.swift
//  CICompanion
//
//  A modal form for creating a new assignment for a specific course.
//  Presented as a sheet from `TodayView` when the user taps the gear icon.
//

import SwiftUI

// MARK: - NewAssignmentView

/// A full-screen modal form that lets the user create a new assignment.
///
/// **Fields:** title, class name (read-only), details, priority toggle,
/// all-day toggle, and alert settings.
struct NewAssignmentView: View {

    // MARK: - Input Properties

    /// The course block this assignment belongs to.
    let course: CalendarScheduleBlock

    /// Whether the parent's sheet is presented (used for dismiss coordination).
    @Binding var isPresented: Bool

    /// Shared assignment storage — the new item is appended here on save.
    @Binding var assignments: [String: [Assignment]]

    @Environment(\.dismiss) private var dismiss

    // MARK: - Form State

    @State private var title = ""
    @State private var details = ""
    @State private var isPriority = false
    @State private var isAllDay = true
    @State private var alertEnabled = true
    @State private var alertTime = "1 day before class"
    @State private var selectedDate = Date()

    // MARK: - Body

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                toolbar
                formContent
            }
        }
    }
}

private extension NewAssignmentView {

    /// Top bar with Cancel and Save buttons.
    var toolbar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Text("Cancel")
                    .font(AppTheme.Fonts.toolbarAction)
                    .foregroundColor(AppTheme.Colors.actionPrimary)
            }

            Spacer()

            Button(action: saveAssignment) {
                Text("Save")
                    .font(AppTheme.Fonts.toolbarActionBold)
                    .foregroundColor(AppTheme.Colors.actionPrimary)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.screen)
        .padding(.vertical, AppTheme.Spacing.cardInternal)
    }
}

private extension NewAssignmentView {

    /// The scrollable set of form fields.
    var formContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("New assignment")
                    .font(AppTheme.Fonts.title)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                titleField
                classNameField
                detailsField
                priorityToggle

                Divider().background(AppTheme.Colors.gridLine)

                allDaySection
                alertSection
            }
            .padding(AppTheme.Spacing.screen)
        }
    }

    // MARK: Individual Fields

    /// Assignment title text field.
    var titleField: some View {
        FormField(label: "Title") {
            TextField("Eg. Read Book", text: $title)
                .font(AppTheme.Fonts.body)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .padding(AppTheme.Spacing.cardInternal)
                .background(AppTheme.Colors.cardBackground)
                .cornerRadius(AppTheme.Spacing.fieldCornerRadius)
        }
    }

    /// Read-only course name with a chevron (mimics a dropdown).
    var classNameField: some View {
        FormField(label: "Class name") {
            HStack {
                Text("\(course.courseCode) - \(course.courseName)")
                    .font(AppTheme.Fonts.body)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(AppTheme.Fonts.iconChevron)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(AppTheme.Spacing.cardInternal)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.Spacing.fieldCornerRadius)
        }
    }

    /// Multi-line details/description field.
    var detailsField: some View {
        FormField(label: "Details") {
            TextField("Eg. Read from page 100 to 150", text: $details, axis: .vertical)
                .font(AppTheme.Fonts.body)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(3...6)
                .padding(AppTheme.Spacing.cardInternal)
                .background(AppTheme.Colors.cardBackground)
                .cornerRadius(AppTheme.Spacing.fieldCornerRadius)
        }
    }

    /// "Set as priority" checkbox.
    var priorityToggle: some View {
        Button(action: { isPriority.toggle() }) {
            HStack(spacing: 10) {
                Image(systemName: isPriority ? "checkmark.square.fill" : "square")
                    .font(AppTheme.Fonts.iconCheckbox)
                    .foregroundColor(isPriority ? AppTheme.Colors.actionPrimary : AppTheme.Colors.textSecondary)

                Text("Set as priority")
                    .font(AppTheme.Fonts.body)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
        }
        .buttonStyle(.plain)
    }

    /// "All day" toggle row + formatted date.
    var allDaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            toggleRow(title: "All day", isOn: $isAllDay)

            Text(selectedDate.shortOrdinalDisplay)
                .font(AppTheme.Fonts.bodyMedium)
                .foregroundColor(AppTheme.Colors.actionPrimary)
        }
    }

    /// "Alert" toggle row + lead-time label.
    var alertSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            toggleRow(title: "Alert", isOn: $alertEnabled)

            if alertEnabled {
                Text(alertTime)
                    .font(AppTheme.Fonts.bodyMedium)
                    .foregroundColor(AppTheme.Colors.actionPrimary)
            }
        }
    }
}

private extension NewAssignmentView {

    /// A labeled form section (label + content).
    struct FormField<Content: View>: View {
        let label: String
        @ViewBuilder let content: Content

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(label)
                    .font(AppTheme.Fonts.captionMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                content
            }
        }
    }

    /// A standard toggle row with a title label and teal switch.
    func toggleRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(AppTheme.Fonts.bodySemibold)
                .foregroundColor(AppTheme.Colors.textPrimary)
            Spacer()
            Toggle("", isOn: isOn)
                .tint(AppTheme.Colors.success)
        }
    }
}

private extension NewAssignmentView {

    /// Creates a new `Assignment` from the form fields and appends it to storage.
    func saveAssignment() {
        let newAssignment = Assignment(
            courseId: course.id,
            title: title.isEmpty ? "Untitled Assignment" : title,
            details: details,
            isPriority: isPriority,
            alertTime: alertTime
        )

        if assignments[course.id] != nil {
            assignments[course.id]?.append(newAssignment)
        } else {
            assignments[course.id] = [newAssignment]
        }

        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NewAssignmentView(
        course: CalendarScheduleBlock(
            id: "1",
            courseId: 1,
            courseName: "Organization Management",
            courseCode: "MGT101",
            location: "Room 101",
            startTime: "09:00 AM",
            endTime: "10:00 AM",
            day: "Monday",
            startMinutes: 540,
            endMinutes: 600,
            colorIndex: 0
        ),
        isPresented: .constant(true),
        assignments: .constant([:])
    )
}
