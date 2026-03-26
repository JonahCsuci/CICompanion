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
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Local Form State
    
    @State private var title: String = ""
    @State private var details: String = ""
    @State private var isPriority: Bool = false
    @State private var isAllDay: Bool = true
    @State private var alertEnabled: Bool = true
    @State private var alertTime: String = "1 day before class"
    @State private var selectedDate: Date = Date()
    
    // MARK: - Theme Colors
    
    private let bgColor = Color(red: 0.08, green: 0.10, blue: 0.15)
    private let fieldBgColor = Color(red: 0.12, green: 0.14, blue: 0.20)
    private let accentBlue = Color(red: 0.35, green: 0.55, blue: 0.95)
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(accentBlue)
                    }
                    
                    Spacer()
                    
                    Button(action: saveAssignment) {
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(accentBlue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Page title
                        Text("New assignment")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                            
                            TextField("Eg. Read Book", text: $title)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .padding(14)
                                .background(fieldBgColor)
                                .cornerRadius(10)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Class name")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                            
                            HStack {
                                Text("\(course.courseCode) - \(course.courseName)")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.gray)
                            }
                            .padding(14)
                            .background(fieldBgColor)
                            .cornerRadius(10)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Details")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                            
                            TextField("Eg. Read from page 100 to 150", text: $details, axis: .vertical)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .lineLimit(3...6)
                                .padding(14)
                                .background(fieldBgColor)
                                .cornerRadius(10)
                        }
                        
                        Button(action: { isPriority.toggle() }) {
                            HStack(spacing: 10) {
                                Image(systemName: isPriority ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 20))
                                    .foregroundColor(isPriority ? accentBlue : .gray)
                                
                                Text("Set as priority")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                            .background(Color(white: 0.25))
                        
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("All day")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Toggle("", isOn: $isAllDay)
                                    .tint(Color(red: 0.2, green: 0.85, blue: 0.8))
                            }
                            
                            Text(formattedSelectedDate())
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(accentBlue)
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Alert")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Toggle("", isOn: $alertEnabled)
                                    .tint(Color(red: 0.2, green: 0.85, blue: 0.8))
                            }
                            
                            if alertEnabled {
                                Text(alertTime)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(accentBlue)
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    /// Creates a new assignment from the form fields and saves it.
    private func saveAssignment() {
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
    
    // MARK: - Helpers
    
    private func formattedSelectedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d"
        let base = formatter.string(from: selectedDate)
        
        let day = Calendar.current.component(.day, from: selectedDate)
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        let month = monthFormatter.string(from: selectedDate)
        
        return "\(base)\(suffix) \(month)"
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
            startMinutes: 540,
            endMinutes: 600,
            colorIndex: 0
        ),
        isPresented: .constant(true),
        assignments: .constant([:])
    )
}
