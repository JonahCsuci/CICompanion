//
//  ScheduleGridView.swift
//  CICompanion
//
//  Displays a weekly schedule grid (Monday–Friday, 9 AM–3 PM) with colored course blocks.
//

import SwiftUI

struct ScheduleGridView: View {
    
    // MARK: - Properties
    
    @StateObject var viewModel: AcademicCalendarViewModel
    
    // Grid configuration
    private let startHour = 9
    private let endHour = 15
    private let hourHeight: CGFloat = 80
    private let timeColumnWidth: CGFloat = 40
    private let bgColor = Color(red: 0.08, green: 0.10, blue: 0.15)
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Text("Schedule")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                
                dayHeaders()
                    .padding(.horizontal, 8)
                    .padding(.bottom, 6)
                
                ScrollView(.vertical, showsIndicators: false) {
                    gridContent()
                        .padding(.horizontal, 8)
                        .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            viewModel.loadSchedule()
        }
    }
    
    // MARK: - Day Headers
    
    /// Day headers row (Mon–Fri) with today highlighted.
    private func dayHeaders() -> some View {
        let weekDates = currentWeekDates()
        
        return HStack(spacing: 0) {
            Color.clear.frame(width: timeColumnWidth, height: 1)
            
            ForEach(0..<5, id: \.self) { i in
                let date = weekDates[i]
                let day = Calendar.current.component(.day, from: date)
                let dayName = shortDayName(for: date)
                let isToday = Calendar.current.isDateInToday(date)
                
                VStack(spacing: 2) {
                    Text("\(day)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(isToday ? .white : .gray)
                    Text(dayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isToday ? .white.opacity(0.85) : .gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isToday {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.30, green: 0.50, blue: 0.90))
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Grid Content
    
    /// Builds the main grid area with time labels, grid lines, and course blocks.
    private func gridContent() -> some View {
        let totalHours = endHour - startHour
        let gridHeight = CGFloat(totalHours) * hourHeight
        
        return GeometryReader { geo in
            let gridWidth = geo.size.width
            let colWidth = (gridWidth - timeColumnWidth) / 5
            
            ZStack(alignment: .topLeading) {
                
                // Horizontal grid lines + time labels
                ForEach(0...totalHours, id: \.self) { i in
                    let y = CGFloat(i) * hourHeight
                    
                    Path { path in
                        path.move(to: CGPoint(x: timeColumnWidth, y: y))
                        path.addLine(to: CGPoint(x: gridWidth, y: y))
                    }
                    .stroke(Color(white: 0.18), lineWidth: 0.5)
                    
                    if i < totalHours {
                        let hour = startHour + i
                        VStack(spacing: 0) {
                            Text(formatHourLabel(hour))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                            Text(hour >= 12 ? "PM" : "AM")
                                .font(.system(size: 9))
                                .foregroundColor(.gray)
                        }
                        .position(x: timeColumnWidth / 2, y: y + 16)
                    }
                }
                
                // Vertical grid lines
                ForEach(0...5, id: \.self) { i in
                    let x = timeColumnWidth + CGFloat(i) * colWidth
                    Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: gridHeight))
                    }
                    .stroke(Color(white: 0.18), lineWidth: 0.5)
                }
                
                // Course blocks
                let weekDates = currentWeekDates()
                ForEach(viewModel.scheduleBlocks) { block in
                    if let col = dayIndex(for: block.day, in: weekDates) {
                        let x = timeColumnWidth + CGFloat(col) * colWidth + 2
                        let y = CGFloat(block.startMinutes - startHour * 60) / 60.0 * hourHeight
                        let h = CGFloat(block.endMinutes - block.startMinutes) / 60.0 * hourHeight
                        
                        if y >= 0 && y < gridHeight {
                            courseBlock(block: block, width: colWidth - 4, height: max(h - 2, 28))
                                .offset(x: x, y: y)
                        }
                    }
                }
            }
        }
        .frame(height: gridHeight)
    }
    
    // MARK: - Course Block
    
    private func courseBlock(block: CalendarScheduleBlock, width: CGFloat, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(displayName(block.courseName))
                .font(.system(size: 11, weight: .bold))
                .lineLimit(3)
                .minimumScaleFactor(0.7)
            
            Text(block.location)
                .font(.system(size: 9))
                .lineLimit(1)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 5)
        .padding(.vertical, 4)
        .frame(width: width, height: height, alignment: .topLeading)
        .background(courseColor(for: block.colorIndex))
        .cornerRadius(6)
    }
    
    // MARK: - Helpers
    
    private func currentWeekDates() -> [Date] {
        let cal = Calendar.current
        let today = Date()
        let weekday = cal.component(.weekday, from: today)
        let mondayOffset = (weekday == 1) ? -6 : (2 - weekday)
        guard let monday = cal.date(byAdding: .day, value: mondayOffset, to: today) else { return [] }
        return (0..<5).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }
    
    private func dayIndex(for dayName: String, in dates: [Date]) -> Int? {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return dates.firstIndex { formatter.string(from: $0) == dayName }
    }
    
    private func shortDayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func formatHourLabel(_ hour: Int) -> String {
        let h = hour > 12 ? hour - 12 : hour
        return String(format: "%02d", h)
    }
    
    /// Shortens long course names to fit inside grid blocks.
    private func displayName(_ name: String) -> String {
        if name.count <= 14 { return name }
        
        let words = name.split(separator: " ")
        if words.count <= 2 { return name }
        
        let line = words.prefix(2).joined(separator: " ")
        if line.count <= 14 { return line }
        
        let first = words[0].count > 8 ? String(words[0].prefix(7)) + "." : String(words[0])
        return "\(first) \(words[1])"
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
}

// MARK: - Preview

#Preview {
    ScheduleGridView(
        viewModel: AcademicCalendarViewModel(
            courseRepository: CourseRepository(studentRepository: StudentRepository()),
            studentRepository: StudentRepository()
        )
    )
}
