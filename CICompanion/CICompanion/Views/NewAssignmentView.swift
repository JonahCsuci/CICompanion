//
//  NewAssignmentView.swift
//  CICompanion
//
//  A modal form for creating a new assignment for a specific course.
//

import SwiftUI

struct NewAssignmentView: View {
    
    // MARK: - Input Properties
    
    var course: CalendarScheduleBlock
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
    @State private var selectedClassIndex: Int = 0
    
    // MARK: - Theme Colors
    
    private let bgColor = Color(red: 0.08, green: 0.10, blue: 0.15)
    private let fieldBgColor = Color(red: 0.12, green: 0.14, blue: 0.20)
    private let accentBlue = Color(red: 0.35, green: 0.55, blue: 0.95)
    
    // MARK: - Body
    
    var body: some View {
        CIView() {
            CIHeader() {
                HStack {
                    CITextButton(text: "Cancel", action: { dismiss() })
                    
                    Spacer()
                    
                    CITextButton(text: "Save", action: { saveAssignment() })
                    
                }
                .padding(ViewHelper.padding)
            }
            CIScrollView() {
                
                CIPageTitle("New assignment")
                CIItem(name: "Title", content: {
                    CITextField(placeholder: "Eg. Read Book", text: $title, lines: 1)
                })
                
                CIItem(name: "Class name", content: {
                    CIDropDown(
                        options: ["500", "Class2"],
                        selected: "500"
                    )
                })
                
                CIItem(name: "Details", content: {
                    CITextField(placeholder: "Eg. Read from page 100 to 150", text: $details, lines: 3...6)
                })
                
                CICheckBoxToggle(label: "Set as priority", toggleBool: isPriority, toggleAction: {isPriority.toggle()})
                
                Divider()
                    .background(Color(white: 0.5))
                
                VStack(alignment: .leading, spacing: 10) {
                    CISliderToggle(label: "All day", toggleBool: $isAllDay, toggleAction: {print("Augh")})
                    
                    Text(formattedSelectedDate())
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(accentBlue)
                }
                
                VStack(alignment: .leading, spacing: ViewHelper.spacing) {
                    HStack {
                        Text("Alert")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Toggle("", isOn: $alertEnabled)
                            .tint(ViewHelper.accentGreen)
                    }
                    
                    if alertEnabled {
                        Text(alertTime)
                            .font(.system(size: ViewHelper.textSize, weight: .medium))
                            .foregroundColor(accentBlue)
                    }
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
        formatter.dateFormat = "EEEE"
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
        
        return "\(base), \(month) \(day)\(suffix)"
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

