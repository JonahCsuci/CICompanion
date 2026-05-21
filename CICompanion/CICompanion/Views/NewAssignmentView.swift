//
//  NewAssignmentView.swift
//  CICompanion
//
//  A modal form for creating a new assignment for a specific course.
//

import SwiftUI

struct NewAssignmentView: View {
    
    // MARK: - Input Properties
    
    let course: CalendarScheduleBlock
    @Binding var isPresented: Bool
    @Binding var assignments: [String: [Assignment]]
    /// The date the caller suggests the assignment should default to (usually the currently-selected day).
    var initialDate: Date = Date()
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Local Form State
    
    @State private var title: String = ""
    @State private var details: String = ""
    @State private var isPriority: Bool = false
    @State private var alertEnabled: Bool = true
    /// How many days before the due date to fire the alert. 0 means "on the day of class".
    @State private var alertDaysBefore: Int = 1
    @State private var selectedDate: Date = Date()
    @State private var selectedTime: Date = Calendar.current.date(
        bySettingHour: 9, minute: 0, second: 0, of: Date()
    ) ?? Date()
    
    // MARK: - Layout
    
    private enum Layout {
        static let cancelSaveTextSize: CGFloat = 16
        static let titleTextSize: CGFloat = 26
        static let fieldLabelTextSize: CGFloat = 13
        static let fieldTextSize: CGFloat = 15
        static let chevronSize: CGFloat = 12
        static let priorityIconSize: CGFloat = 20
        static let sectionSpacing: CGFloat = 24
        static let fieldSpacing: CGFloat = 8
        static let toggleSectionSpacing: CGFloat = 10
        static let dividerColor = Color(white: 0.25)
        static let toggleTint = Color(red: 0.2, green: 0.85, blue: 0.8)
        /// Max alert offset the user can pick, in days (0 = same day, 7 = a week before).
        static let maxAlertDaysBefore = 7
    }
    
    // MARK: - Theme aliases
    
    private var bgColor: Color { ViewHelper.bgColor }
    private var fieldBgColor: Color { ViewHelper.fieldBgColor }
    private var accentBlue: Color { ViewHelper.accentBlue }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                toolbar
                
                ScrollView {
                    VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                        Text("New assignment")
                            .font(.system(size: Layout.titleTextSize, weight: .bold))
                            .foregroundColor(ViewHelper.textImportant)
                        
                        titleField
                        classNameField
                        detailsField
                        priorityToggle
                        
                        Divider().background(Layout.dividerColor)
                        
                        dateSection
                        alertSection
                    }
                    .padding(ViewHelper.biggerSpacing)
                }
            }
        }
        .onAppear {
            selectedDate = initialDate
            if let nineAM = Calendar.current.date(
                bySettingHour: 9, minute: 0, second: 0, of: initialDate
            ) {
                selectedTime = nineAM
            }
        }
    }
    
    // MARK: - Subviews
    
    private var toolbar: some View {
        let isTitleValid = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        return HStack {
            Button(action: { dismiss() }) {
                Text("Cancel")
                    .font(.system(size: Layout.cancelSaveTextSize, weight: .medium))
                    .foregroundColor(accentBlue)
            }
            
            Spacer()
            
            Button(action: saveAssignment) {
                Text("Save")
                    .font(.system(size: Layout.cancelSaveTextSize, weight: .semibold))
                    .foregroundColor(isTitleValid ? accentBlue : ViewHelper.text)
            }
            .disabled(!isTitleValid)
        }
        .padding(.horizontal, ViewHelper.biggerSpacing)
        .padding(.vertical, ViewHelper.padding)
    }
    
    private var titleField: some View {
        VStack(alignment: .leading, spacing: Layout.fieldSpacing) {
            requiredFieldLabel("Title")
            
            TextField("Eg. Read Book", text: $title)
                .font(.system(size: Layout.fieldTextSize))
                .foregroundColor(ViewHelper.textImportant)
                .padding(ViewHelper.padding)
                .background(fieldBgColor)
                .cornerRadius(ViewHelper.componentRounding)
        }
    }
    
    private var classNameField: some View {
        VStack(alignment: .leading, spacing: Layout.fieldSpacing) {
            fieldLabel("Class name")
            
            HStack {
                Text("\(course.courseCode) - \(course.courseName)")
                    .font(.system(size: Layout.fieldTextSize))
                    .foregroundColor(ViewHelper.textImportant)
                    .lineLimit(1)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: Layout.chevronSize, weight: .semibold))
                    .foregroundColor(ViewHelper.text)
            }
            .padding(ViewHelper.padding)
            .background(fieldBgColor)
            .cornerRadius(ViewHelper.componentRounding)
        }
    }
    
    private var detailsField: some View {
        VStack(alignment: .leading, spacing: Layout.fieldSpacing) {
            fieldLabel("Details")
            
            TextField("Eg. Read from page 100 to 150", text: $details, axis: .vertical)
                .font(.system(size: Layout.fieldTextSize))
                .foregroundColor(ViewHelper.textImportant)
                .lineLimit(3...6)
                .padding(ViewHelper.padding)
                .background(fieldBgColor)
                .cornerRadius(ViewHelper.componentRounding)
        }
    }
    
    private var priorityToggle: some View {
        Button(action: { isPriority.toggle() }) {
            HStack(spacing: 10) {
                Image(systemName: isPriority ? "checkmark.square.fill" : "square")
                    .font(.system(size: Layout.priorityIconSize))
                    .foregroundColor(isPriority ? accentBlue : ViewHelper.text)
                
                Text("Set as priority")
                    .font(.system(size: Layout.fieldTextSize))
                    .foregroundColor(ViewHelper.textImportant)
            }
        }
        .buttonStyle(.plain)
    }
    
    /// Date and time selection. Both are always editable; date is prefilled with `initialDate`.
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: Layout.toggleSectionSpacing) {
            HStack {
                Text("Date")
                    .font(.system(size: Layout.fieldTextSize, weight: .semibold))
                    .foregroundColor(ViewHelper.textImportant)
                
                Spacer()
                
                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .labelsHidden()
                .tint(accentBlue)
            }
            
            HStack {
                Text("Time")
                    .font(.system(size: Layout.fieldTextSize, weight: .semibold))
                    .foregroundColor(ViewHelper.textImportant)
                
                Spacer()
                
                DatePicker(
                    "",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .tint(accentBlue)
            }
        }
    }
    
    private var alertSection: some View {
        VStack(alignment: .leading, spacing: Layout.toggleSectionSpacing) {
            HStack {
                Text("Alert")
                    .font(.system(size: Layout.fieldTextSize, weight: .semibold))
                    .foregroundColor(ViewHelper.textImportant)
                
                Spacer()
                
                Toggle("", isOn: $alertEnabled)
                    .tint(Layout.toggleTint)
            }
            
            if alertEnabled {
                HStack {
                    Text("Remind me")
                        .font(.system(size: Layout.fieldTextSize, weight: .medium))
                        .foregroundColor(ViewHelper.text)
                    
                    Spacer()
                    
                    Picker("", selection: $alertDaysBefore) {
                        ForEach(0...Layout.maxAlertDaysBefore, id: \.self) { days in
                            Text(alertLabel(for: days)).tag(days)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(accentBlue)
                }
            }
        }
    }
    
    /// Human-readable label shown in the alert picker and stored as the assignment's alertTime.
    private func alertLabel(for daysBefore: Int) -> String {
        switch daysBefore {
        case 0: return "On the day"
        case 1: return "1 day before"
        default: return "\(daysBefore) days before"
        }
    }
    
    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: Layout.fieldLabelTextSize, weight: .medium))
            .foregroundColor(ViewHelper.text)
    }
    
    /// Same as `fieldLabel`, but with a trailing red asterisk to indicate the field is required.
    private func requiredFieldLabel(_ text: String) -> some View {
        HStack(spacing: 3) {
            Text(text)
                .font(.system(size: Layout.fieldLabelTextSize, weight: .medium))
                .foregroundColor(ViewHelper.text)
            Text("*")
                .font(.system(size: Layout.fieldLabelTextSize, weight: .bold))
                .foregroundColor(ViewHelper.accentRed)
        }
    }
    
    // MARK: - Actions
    
    /// Creates a new assignment from the form fields and saves it.
    /// A non-empty title is required; the Save button is disabled until one is provided.
    private func saveAssignment() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let finalDueDate = combine(day: selectedDate, time: selectedTime)
        let alertDescription = alertEnabled ? alertLabel(for: alertDaysBefore) : ""
        
        let newAssignment = Assignment(
            courseId: course.id,
            title: trimmedTitle,
            details: details,
            isPriority: isPriority,
            alertTime: alertDescription,
            dueDate: finalDueDate,
            isAllDay: false
        )
        
        if assignments[course.id] != nil {
            assignments[course.id]?.append(newAssignment)
        } else {
            assignments[course.id] = [newAssignment]
        }
        
        dismiss()
    }
    
    // MARK: - Helpers
    
    /// Combines the day components of `day` with the hour/minute components of `time`.
    private func combine(day: Date, time: Date) -> Date {
        let cal = Calendar.current
        let dayComps = cal.dateComponents([.year, .month, .day], from: day)
        let timeComps = cal.dateComponents([.hour, .minute], from: time)
        var merged = DateComponents()
        merged.year = dayComps.year
        merged.month = dayComps.month
        merged.day = dayComps.day
        merged.hour = timeComps.hour
        merged.minute = timeComps.minute
        return cal.date(from: merged) ?? day
    }
}

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
            date: Date(),
            startMinutes: 540,
            endMinutes: 600,
            colorIndex: 0,
            isMeeting: false,
            course: nil
        ),
        isPresented: .constant(true),
        assignments: .constant([:])
    )
}
