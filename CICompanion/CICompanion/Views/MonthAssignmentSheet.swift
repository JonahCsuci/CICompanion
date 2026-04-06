//
//  MonthAssignmentSheet.swift
//  CICompanion
//
//  A lightweight form for creating an assignment from the Month calendar view.
//  Unlike `NewAssignmentView` (which is tied to a specific course block),
//  this sheet lets the user pick which course the assignment belongs to
//  and automatically sets the due date to the selected calendar date.
//

import SwiftUI

// MARK: - MonthAssignmentSheet

/// Modal form presented when the user taps "+" on a selected date
/// in the month calendar view.
///
/// **Fields:** title, course picker, details, priority toggle.
/// The due date is pre-set from the tapped calendar date and displayed
/// as a read-only label.
struct MonthAssignmentSheet: View {

    // MARK: - Input Properties

    /// The calendar date that was selected when the user tapped "+".
    let date: Date

    /// All schedule blocks used to populate the course picker.
    let scheduleBlocks: [CalendarScheduleBlock]

    /// Shared assignment storage — the new item is appended on save.
    @Binding var assignments: [String: [Assignment]]

    @Environment(\.dismiss) private var dismiss

    // MARK: - Form State

    @State private var title = ""
    @State private var details = ""
    @State private var isPriority = false

    /// Index of the selected course in the unique-courses list.
    @State private var selectedCourseIndex = 0

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

// MARK: - Toolbar

private extension MonthAssignmentSheet {

    /// Cancel / Save top bar.
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

// MARK: - Form Content

private extension MonthAssignmentSheet {

    /// The scrollable form fields.
    var formContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("New Assignment")
                    .font(AppTheme.Fonts.title)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                dueDateLabel
                titleField
                coursePicker
                detailsField
                priorityToggle
            }
            .padding(AppTheme.Spacing.screen)
        }
    }

    /// Read-only due-date display.
    var dueDateLabel: some View {
        fieldSection(label: "Due date") {
            Text(date.formattedWithOrdinal)
                .font(AppTheme.Fonts.body)
                .foregroundColor(AppTheme.Colors.actionPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppTheme.Spacing.cardInternal)
                .background(AppTheme.Colors.cardBackground)
                .cornerRadius(AppTheme.Spacing.fieldCornerRadius)
        }
    }

    /// Title text field.
    var titleField: some View {
        fieldSection(label: "Title") {
            TextField("e.g. Read Chapter 5", text: $title)
                .font(AppTheme.Fonts.body)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .padding(AppTheme.Spacing.cardInternal)
                .background(AppTheme.Colors.cardBackground)
                .cornerRadius(AppTheme.Spacing.fieldCornerRadius)
        }
    }

    /// Picker that lists the student's unique courses.
    var coursePicker: some View {
        let courses = uniqueCourses

        return fieldSection(label: "Course") {
            Menu {
                ForEach(courses.indices, id: \.self) { index in
                    Button {
                        selectedCourseIndex = index
                    } label: {
                        Text("\(courses[index].courseCode) — \(courses[index].courseName)")
                    }
                }
            } label: {
                HStack {
                    if courses.isEmpty {
                        Text("No courses available")
                            .font(AppTheme.Fonts.body)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    } else {
                        Text("\(courses[selectedCourseIndex].courseCode) — \(courses[selectedCourseIndex].courseName)")
                            .font(AppTheme.Fonts.body)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .lineLimit(1)
                    }

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
    }

    /// Multi-line details field.
    var detailsField: some View {
        fieldSection(label: "Details") {
            TextField("e.g. Pages 100–150", text: $details, axis: .vertical)
                .font(AppTheme.Fonts.body)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(3...6)
                .padding(AppTheme.Spacing.cardInternal)
                .background(AppTheme.Colors.cardBackground)
                .cornerRadius(AppTheme.Spacing.fieldCornerRadius)
        }
    }

    /// Priority checkbox toggle.
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
}

// MARK: - Helpers

private extension MonthAssignmentSheet {

    /// A labeled form section (label text + content).
    func fieldSection<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(AppTheme.Fonts.captionMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            content()
        }
    }

    /// De-duplicated list of courses derived from the schedule blocks.
    var uniqueCourses: [CalendarScheduleBlock] {
        var seen = Set<Int>()
        return scheduleBlocks.filter { seen.insert($0.courseId).inserted }
    }

    /// Creates the assignment and appends it to shared storage.
    func saveAssignment() {
        let courses = uniqueCourses
        guard !courses.isEmpty else { dismiss(); return }

        let course = courses[selectedCourseIndex]

        let newAssignment = Assignment(
            courseId: "\(course.courseId)",
            title: title.isEmpty ? "Untitled Assignment" : title,
            details: details,
            isPriority: isPriority,
            dueDate: date
        )

        // Key by the course block ID so day-view and month-view share storage.
        let key = course.id
        if assignments[key] != nil {
            assignments[key]?.append(newAssignment)
        } else {
            assignments[key] = [newAssignment]
        }

        dismiss()
    }
}

// MARK: - Preview

#Preview {
    MonthAssignmentSheet(
        date: Date(),
        scheduleBlocks: [
            CalendarScheduleBlock(
                id: "1-Monday", courseId: 1,
                courseName: "Organization Management", courseCode: "MGT101",
                location: "Room 101", startTime: "09:00 AM", endTime: "10:00 AM",
                day: "Monday", startMinutes: 540, endMinutes: 600, colorIndex: 0
            )
        ],
        assignments: .constant([:])
    )
}
