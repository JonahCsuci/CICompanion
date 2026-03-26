//
//  TodayView.swift
//  CICompanion
//
//  The main "Today" tab — shows the current date, a week-day selector,
//  expandable course cards, and assignment checklists with swipe-to-delete.
//

import SwiftUI

/// Displays today's schedule with expandable course cards and an assignment checklist.
struct TodayView: View {
    
    // MARK: - Properties
    
    /// The ViewModel that fetches and holds the student's schedule data.
    /// `@StateObject` means THIS view creates and owns the ViewModel.
    /// Use `@StateObject` when a view is the *source of truth* for an object.
    /// Use `@ObservedObject` when a view *receives* an already-created object from a parent.
    @StateObject var viewModel: AcademicCalendarViewModel
    
    /// Tracks which course card is currently expanded (by its unique ID).
    /// `nil` means no card is expanded. Only one card can be expanded at a time.
    @State private var expandedCardId: String?
    
    /// Controls whether the "New Assignment" sheet is presented.
    @State private var showNewAssignment = false
    
    /// The course the user tapped the gear icon on — triggers the assignment sheet.
    /// `sheet(item:)` watches this: when it becomes non-nil, the sheet appears.
    /// When the sheet is dismissed, SwiftUI automatically sets this back to nil.
    @State private var selectedCourse: CalendarScheduleBlock?
    
    /// In-memory storage for assignments, keyed by course block ID (e.g., "1-Monday").
    /// Each key maps to an array of Assignment objects for that course.
    @State private var assignments: [String: [Assignment]] = [:]
    
    /// The currently selected date in the week selector. Defaults to today.
    @State private var selectedDate: Date = Date()
    
    /// App-wide dark background color, used consistently across all views.
    private let bgColor = Color(red: 0.08, green: 0.10, blue: 0.15)
    
    /// Slightly lighter background for card surfaces (creates depth/contrast).
    private let cardBgColor = Color(red: 0.12, green: 0.14, blue: 0.20)
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Header (date + week selector)
                VStack(alignment: .leading, spacing: 16) {
                    Text(formattedDate())
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Interactive week-day selector (Mon-Fri buttons)
                    weekSelector()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
                
                ScrollView {
                    VStack(spacing: 12) {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                                .padding(.top, 40)
                        } else if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding(.top, 40)
                        } else {
                            let todayBlocks = blocksForSelectedDate()
                            if todayBlocks.isEmpty {
                                Text("No classes today")
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 40)
                            } else {
                                ForEach(todayBlocks) { block in
                                    courseCard(for: block)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(item: $selectedCourse) { course in
            NewAssignmentView(
                course: course,
                isPresented: $showNewAssignment,
                assignments: $assignments
            )
        }
        .onAppear {
            viewModel.loadSchedule()
        }
    }
    
    // MARK: - Week Selector
    
    /// Builds the row of tappable day buttons (Mon–Fri) with assignment badges.
    private func weekSelector() -> some View {
        let weekDates = currentWeekDates()
        
        return HStack(spacing: 8) {
            ForEach(weekDates, id: \.self) { date in
                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                let day = Calendar.current.component(.day, from: date)
                let dayName = shortDayName(for: date)
                let badgeCount = assignmentCountForDate(date)
                
                VStack(spacing: 4) {
                    ZStack {
                        // Blue highlight behind the selected day
                        if isSelected {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(red: 0.30, green: 0.50, blue: 0.90))
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(day)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(isSelected ? .white : .gray)
                            
                            Text(dayName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(isSelected ? .white.opacity(0.85) : .gray)
                        }
                        .padding(.vertical, 10)
                    }
                    .frame(maxWidth: .infinity)   // Each day takes equal width
                    .frame(height: 58)
                    
                    // Badge for incomplete assignments
                    if badgeCount > 0 {
                        Text("\(badgeCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(Color.red)
                            .clipShape(Circle())
                    } else {
                        Color.clear.frame(width: 18, height: 18)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedDate = date
                        expandedCardId = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Course Card
    
    /// Builds a single expandable course card with time, course info, and assignments.
    private func courseCard(for block: CalendarScheduleBlock) -> some View {
        let isExpanded = expandedCardId == block.id
        let color = courseColor(for: block.colorIndex)
        let courseAssignments = assignments[block.id] ?? []
        let missingCount = courseAssignments.filter { !$0.isCompleted }.count
        
        return VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
                    .frame(width: 16)
                    .padding(.top, 5)
                    .padding(.trailing, 6)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(block.startTime)
                        .font(.system(size: 13, weight: .regular))
                    Text(block.endTime)
                        .font(.system(size: 13, weight: .regular))
                }
                .foregroundColor(.gray)
                .frame(width: 72, alignment: .leading)
                
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(color)
                    .frame(width: 3)
                    .padding(.vertical, 2)
                    .padding(.trailing, 10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(block.courseCode) - \(block.courseName)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(color)
                        .lineLimit(2)
                    
                    HStack(spacing: 6) {
                        Text(block.location)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        if !isExpanded && missingCount > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.red)
                                Text("\(missingCount)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.red)
                                Text("Missing assignment")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                Spacer()
                
                if isExpanded {
                    Button {
                        selectedCourse = block
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 2)
                } else {
                    let timeLabel = timeUntilClass(for: block)
                    if !timeLabel.isEmpty {
                        Text(timeLabel)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(timeLabel == "Now" ? Color(red: 0.4, green: 0.85, blue: 0.5) : .gray)
                            .padding(.top, 2)
                    }
                }
            }
            .padding(14)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedCardId = isExpanded ? nil : block.id
                }
            }
            
            if isExpanded {
                expandedContent(for: block, color: color)
            }
        }
        .background(cardBgColor)
        .cornerRadius(12)
    }
    
    // MARK: - Expanded Content
    
    /// The assignment list shown when a course card is expanded.
    private func expandedContent(for block: CalendarScheduleBlock, color: Color) -> some View {
        let courseAssignments = assignments[block.id] ?? []
        let pendingCount = courseAssignments.filter { !$0.isCompleted }.count
        
        return VStack(alignment: .leading, spacing: 12) {
            Divider()
                .background(Color(white: 0.25))
                .padding(.horizontal, -14)
            
            HStack(spacing: 8) {
                Text("Assignments")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                if pendingCount > 0 {
                    Text("\(pendingCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 18, height: 18)
                        .background(Color(red: 0.30, green: 0.50, blue: 0.90))
                        .clipShape(Circle())
                }
            }
            
            // Assignment list — each row is wrapped in SwipeToDeleteRow for swipe gesture
            if courseAssignments.isEmpty {
                Text("No assignments yet")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            } else {
                VStack(spacing: 4) {
                    ForEach(courseAssignments) { assignment in
                        SwipeToDeleteRow(
                            onDelete: {
                                deleteAssignment(assignment, blockId: block.id)
                            }
                        ) {
                            HStack(spacing: 10) {
                                Button(action: {
                                    toggleAssignment(assignment, blockId: block.id)
                                }) {
                                    Image(systemName: assignment.isCompleted ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 18))
                                        .foregroundColor(
                                            assignment.isCompleted
                                            ? Color(red: 0.2, green: 0.8, blue: 0.4)
                                            : .gray
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(assignment.title)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(assignment.isPriority && !assignment.isCompleted ? Color(red: 1.0, green: 0.85, blue: 0.3) : .white)
                                            .strikethrough(assignment.isCompleted)
                                        
                                        if assignment.isPriority && !assignment.isCompleted {
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 10))
                                                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.3))
                                        }
                                    }
                                    
                                    if !assignment.details.isEmpty {
                                        Text(assignment.details)
                                            .font(.system(size: 11))
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
    }
    
    // MARK: - Assignment Actions
    
    /// Toggles an assignment's completion status.
    private func toggleAssignment(_ assignment: Assignment, blockId: String) {
        if var updated = assignments[blockId],
           let idx = updated.firstIndex(where: { $0.id == assignment.id }) {
            updated[idx].isCompleted.toggle()
            assignments[blockId] = updated
        }
    }
    
    private func deleteAssignment(_ assignment: Assignment, blockId: String) {
        if var updated = assignments[blockId] {
            updated.removeAll { $0.id == assignment.id }
            assignments[blockId] = updated
        }
    }
    
    // MARK: - Date & Schedule Helpers
    
    /// Returns schedule blocks for the selected day, sorted by start time.
    private func blocksForSelectedDate() -> [CalendarScheduleBlock] {
        let dayName = fullDayName(for: selectedDate)
        return viewModel.scheduleBlocks
            .filter { $0.day == dayName }
            .sorted { $0.startMinutes < $1.startMinutes }
    }
    
    /// Returns the Monday–Friday dates for the current week.
    private func currentWeekDates() -> [Date] {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: selectedDate)
        let mondayOffset = (weekday == 1) ? -6 : (2 - weekday)
        guard let monday = cal.date(byAdding: .day, value: mondayOffset, to: selectedDate) else {
            return []
        }
        return (0..<5).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }
    
    /// Counts incomplete assignments for a given date.
    private func assignmentCountForDate(_ date: Date) -> Int {
        let dayName = fullDayName(for: date)
        let dayBlocks = viewModel.scheduleBlocks.filter { $0.day == dayName }
        var count = 0
        for block in dayBlocks {
            count += (assignments[block.id] ?? []).filter { !$0.isCompleted }.count
        }
        return count
    }
    
    private func courseColor(for index: Int) -> Color {
        let colors: [Color] = [
            Color(red: 1.0, green: 0.65, blue: 0.0),
            Color(red: 0.2, green: 0.85, blue: 0.8),
            Color(red: 0.85, green: 0.35, blue: 0.90),
            Color(red: 0.4, green: 0.65, blue: 1.0),
            Color(red: 1.0, green: 0.4, blue: 0.6),
            Color(red: 0.3, green: 0.85, blue: 0.45)
        ]
        return colors[index % colors.count]
    }
    
    // MARK: - Date Formatting Helpers
    
    /// Formats the selected date as "March 25th, 2026".
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let month = formatter.string(from: selectedDate)
        
        let day = Calendar.current.component(.day, from: selectedDate)
        let suffix = daySuffix(for: day)
        
        formatter.dateFormat = "yyyy"
        let year = formatter.string(from: selectedDate)
        
        return "\(month) \(day)\(suffix), \(year)"
    }
    
    private func daySuffix(for day: Int) -> String {
        switch day {
        case 1, 21, 31: return "st"
        case 2, 22: return "nd"
        case 3, 23: return "rd"
        default: return "th"
        }
    }
    
    private func shortDayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func fullDayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    /// Returns relative time until class ("Now", "in 30min", etc.) or "" if past.
    private func timeUntilClass(for block: CalendarScheduleBlock) -> String {
        let now = Date()
        let cal = Calendar.current
        
        guard cal.isDate(selectedDate, inSameDayAs: now) else { return "" }
        
        let startHour = block.startMinutes / 60
        let startMin = block.startMinutes % 60
        let endHour = block.endMinutes / 60
        let endMin = block.endMinutes % 60
        
        var startComps = cal.dateComponents([.year, .month, .day], from: now)
        startComps.hour = startHour
        startComps.minute = startMin
        
        var endComps = cal.dateComponents([.year, .month, .day], from: now)
        endComps.hour = endHour
        endComps.minute = endMin
        
        guard let classStart = cal.date(from: startComps),
              let classEnd = cal.date(from: endComps) else { return "" }
        
        if now >= classStart && now <= classEnd {
            return "Now"
        }
        
        let diff = classStart.timeIntervalSince(now)
        if diff < 0 {
            return ""
        } else if diff < 3600 {
            return "in \(Int(diff / 60))min"
        } else {
            let hours = Int(diff / 3600)
            let mins = Int((diff.truncatingRemainder(dividingBy: 3600)) / 60)
            return mins > 0 ? "in \(hours)h \(mins)m" : "in \(hours)h"
        }
    }
}

// MARK: - SwipeToDeleteRow

/// A reusable wrapper that adds swipe-to-delete behavior to any content.
private struct SwipeToDeleteRow<Content: View>: View {
    let onDelete: () -> Void
    @ViewBuilder let content: Content
    
    @State private var offset: CGFloat = 0
    @State private var showDelete = false
    private let deleteThreshold: CGFloat = -60
    
    var body: some View {
        ZStack(alignment: .trailing) {
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onDelete()
                        offset = 0
                        showDelete = false
                    }
                }) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 36)
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
            
            content
                .background(Color(red: 0.12, green: 0.14, blue: 0.20))
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onChanged { value in
                            if value.translation.width < 0 {
                                offset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if value.translation.width < deleteThreshold {
                                    offset = deleteThreshold
                                    showDelete = true
                                } else {
                                    offset = 0
                                    showDelete = false
                                }
                            }
                        }
                )
        }
        .clipped()
    }
}

#Preview {
    TodayView(
        viewModel: AcademicCalendarViewModel(
            courseRepository: CourseRepository(studentRepository: StudentRepository()),
            studentRepository: StudentRepository()
        )
    )
}
