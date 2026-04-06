//
//  ScheduleGridView.swift
//  CICompanion
//
//  Displays a weekly schedule grid (Monday–Friday, 9 AM–3 PM) with colored course blocks.
//  Each block shows a shortened course name and room number.
//

import SwiftUI

// MARK: - ScheduleGridView

/// A full-week timetable grid showing the student's courses as colored blocks.
///
/// **Layout:**
/// - A row of day headers (Mon–Fri) with today highlighted
/// - A scrollable grid of hour rows × day columns
/// - Course blocks positioned by their start time and duration
struct ScheduleGridView: View {

    // MARK: - Dependencies

    @StateObject var viewModel: AcademicCalendarViewModel

    // MARK: - Grid Configuration

    /// The first hour visible on the grid (inclusive).
    private let gridStartHour = 9
    /// The last hour visible on the grid (exclusive — 15 means up to 3 PM).
    private let gridEndHour = 15
    /// Number of weekday columns (Mon–Fri).
    private let weekdayCount = 5

    // MARK: - Body

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                screenTitle
                dayHeaderRow
                    .padding(.horizontal, 8)
                    .padding(.bottom, 6)
                scrollableGrid
            }
        }
        .onAppear { viewModel.loadSchedule() }
    }
}

private extension ScheduleGridView {

    /// "Schedule" title at the top of the screen.
    var screenTitle: some View {
        Text("Schedule")
            .font(AppTheme.Fonts.screenTitle)
            .foregroundColor(AppTheme.Colors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppTheme.Spacing.screen)
            .padding(.top, 12)
            .padding(.bottom, 12)
    }

    /// Mon–Fri header row with today's date highlighted.
    var dayHeaderRow: some View {
        let weekDates = Date().weekdayDates()

        return HStack(spacing: 0) {
            Color.clear.frame(width: AppTheme.Spacing.timeColumnWidth, height: 1)

            ForEach(0..<weekdayCount, id: \.self) { index in
                let date = weekDates[index]
                let isToday = Calendar.current.isDateInToday(date)

                VStack(spacing: 2) {
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(AppTheme.Fonts.sectionHeader)
                        .foregroundColor(isToday ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary)
                    Text(date.shortDayName)
                        .font(AppTheme.Fonts.smallMedium)
                        .foregroundColor(isToday ? AppTheme.Colors.textPrimary.opacity(0.85) : AppTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isToday {
                            RoundedRectangle(cornerRadius: AppTheme.Spacing.cardCornerRadius)
                                .fill(AppTheme.Colors.actionPrimary)
                        }
                    }
                )
            }
        }
    }

    /// The vertically scrollable grid area.
    var scrollableGrid: some View {
        ScrollView(.vertical, showsIndicators: false) {
            gridContent
                .padding(.horizontal, 8)
                .padding(.bottom, 20)
        }
    }

    /// The main grid layer: hour lines, time labels, vertical dividers, and course blocks.
    var gridContent: some View {
        let totalHours = gridEndHour - gridStartHour
        let gridHeight = CGFloat(totalHours) * AppTheme.Spacing.hourRowHeight

        return GeometryReader { geometry in
            let gridWidth   = geometry.size.width
            let columnWidth = (gridWidth - AppTheme.Spacing.timeColumnWidth) / CGFloat(weekdayCount)

            ZStack(alignment: .topLeading) {
                horizontalGridLines(totalHours: totalHours, gridWidth: gridWidth)
                verticalGridLines(columnWidth: columnWidth, gridHeight: gridHeight)
                courseBlocks(columnWidth: columnWidth, gridHeight: gridHeight)
            }
        }
        .frame(height: gridHeight)
    }
}

private extension ScheduleGridView {

    /// Horizontal lines and time labels for each hour.
    func horizontalGridLines(totalHours: Int, gridWidth: CGFloat) -> some View {
        ForEach(0...totalHours, id: \.self) { index in
            let yPosition = CGFloat(index) * AppTheme.Spacing.hourRowHeight

            Path { path in
                path.move(to: CGPoint(x: AppTheme.Spacing.timeColumnWidth, y: yPosition))
                path.addLine(to: CGPoint(x: gridWidth, y: yPosition))
            }
            .stroke(AppTheme.Colors.gridLine, lineWidth: 0.5)

            if index < totalHours {
                timeLabel(for: gridStartHour + index, at: yPosition)
            }
        }
    }

    /// The hour number + AM/PM label shown at the start of each row.
    func timeLabel(for hour: Int, at yPosition: CGFloat) -> some View {
        VStack(spacing: 0) {
            Text(formattedHour(hour))
                .font(AppTheme.Fonts.smallMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            Text(hour >= 12 ? "PM" : "AM")
                .font(AppTheme.Fonts.gridBlockDetail)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .position(x: AppTheme.Spacing.timeColumnWidth / 2, y: yPosition + 16)
    }

    /// Vertical dividers between day columns.
    func verticalGridLines(columnWidth: CGFloat, gridHeight: CGFloat) -> some View {
        ForEach(0...weekdayCount, id: \.self) { index in
            let xPosition = AppTheme.Spacing.timeColumnWidth + CGFloat(index) * columnWidth

            Path { path in
                path.move(to: CGPoint(x: xPosition, y: 0))
                path.addLine(to: CGPoint(x: xPosition, y: gridHeight))
            }
            .stroke(AppTheme.Colors.gridLine, lineWidth: 0.5)
        }
    }

    /// Positions every `CalendarScheduleBlock` on the grid.
    func courseBlocks(columnWidth: CGFloat, gridHeight: CGFloat) -> some View {
        let weekDates = Date().weekdayDates()

        return ForEach(viewModel.scheduleBlocks) { block in
            if let column = dayColumnIndex(for: block.day, in: weekDates) {
                let xOffset  = AppTheme.Spacing.timeColumnWidth + CGFloat(column) * columnWidth + 2
                let yOffset  = CGFloat(block.startMinutes - gridStartHour * 60) / 60.0 * AppTheme.Spacing.hourRowHeight
                let height   = CGFloat(block.endMinutes - block.startMinutes) / 60.0 * AppTheme.Spacing.hourRowHeight
                let blockPadding: CGFloat = 4

                if yOffset >= 0 && yOffset < gridHeight {
                    courseBlockCell(
                        block: block,
                        width: columnWidth - blockPadding,
                        height: max(height - 2, 28)
                    )
                    .offset(x: xOffset, y: yOffset)
                }
            }
        }
    }

    /// A single colored rectangle for one course block inside the grid.
    func courseBlockCell(block: CalendarScheduleBlock, width: CGFloat, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(shortenedDisplayName(block.courseName))
                .font(AppTheme.Fonts.gridBlockTitle)
                .lineLimit(3)
                .minimumScaleFactor(0.7)

            Text(block.location)
                .font(AppTheme.Fonts.gridBlockDetail)
                .lineLimit(1)
        }
        .foregroundColor(AppTheme.Colors.textPrimary)
        .padding(.horizontal, 5)
        .padding(.vertical, 4)
        .frame(width: width, height: height, alignment: .topLeading)
        .background(AppTheme.Colors.courseColor(for: block.colorIndex))
        .cornerRadius(AppTheme.Spacing.gridBlockCornerRadius)
    }
}

private extension ScheduleGridView {

    /// Finds which column (0-based) a day name belongs to.
    func dayColumnIndex(for dayName: String, in dates: [Date]) -> Int? {
        dates.firstIndex { $0.fullDayName == dayName }
    }

    /// Converts a 24-hour integer to a zero-padded 12-hour string (e.g. 13 → "01").
    func formattedHour(_ hour: Int) -> String {
        let displayHour = hour > 12 ? hour - 12 : hour
        return String(format: "%02d", displayHour)
    }

    /// Shortens long course names so they fit inside narrow grid cells.
    ///
    /// - Names ≤ 14 chars are returned as-is.
    /// - Longer names are truncated to the first two words.
    func shortenedDisplayName(_ name: String) -> String {
        let maxLength = 14
        guard name.count > maxLength else { return name }

        let words = name.split(separator: " ")
        guard words.count > 2 else { return name }

        let twoWords = words.prefix(2).joined(separator: " ")
        if twoWords.count <= maxLength { return twoWords }

        let first = words[0].count > 8 ? String(words[0].prefix(7)) + "." : String(words[0])
        return "\(first) \(words[1])"
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
