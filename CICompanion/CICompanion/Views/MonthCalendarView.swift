//
//  MonthCalendarView.swift
//  CICompanion
//
//  A month-grid calendar component with assignment-dot indicators.
//  Tapping a date selects it — the parent uses the selection to show
//  that day's assignments and an "add" button.
//

import SwiftUI

// MARK: - MonthCalendarView

/// Displays a traditional month-view calendar grid (Sun–Sat).
///
/// **Features:**
/// - Previous / Next month navigation arrows
/// - "Month Year" title centred between the arrows
/// - Weekday header row (S M T W T F S)
/// - Date cells with today-highlight and selection ring
/// - Colored dots under dates that have assignments
///
/// This view is *stateless* with respect to data — the parent provides
/// `assignments` and receives the selected date through a binding.
struct MonthCalendarView: View {

    // MARK: - Bindings

    /// The month currently being displayed (any date within that month).
    @Binding var displayedMonth: Date

    /// The date the user has tapped (drives the assignment list below).
    @Binding var selectedDate: Date

    // MARK: - Data

    /// All assignments across every course, used to place dots on dates.
    let assignments: [String: [Assignment]]

    /// The schedule blocks for looking up course colors by `courseId`.
    let scheduleBlocks: [CalendarScheduleBlock]

    // MARK: - Constants

    /// Number of columns in the calendar grid (Sun through Sat).
    private let columnCount = 7

    /// Abbreviated weekday labels shown at the top of the grid.
    private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]

    // MARK: - Body

    var body: some View {
        VStack(spacing: AppTheme.Spacing.monthHeaderSpacing) {
            monthNavigationHeader
            weekdayHeaderRow
            dateGrid
        }
        .padding(.horizontal, AppTheme.Spacing.screen)
    }
}

// MARK: - Header & Navigation

private extension MonthCalendarView {

    /// "< April 2026 >" — month title with left/right arrow buttons.
    var monthNavigationHeader: some View {
        HStack {
            Button { changeMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(AppTheme.Fonts.monthNavArrow)
                    .foregroundColor(AppTheme.Colors.actionPrimary)
            }

            Spacer()

            Text(displayedMonth.monthYearLabel)
                .font(AppTheme.Fonts.sectionHeader)
                .foregroundColor(AppTheme.Colors.textPrimary)

            Spacer()

            Button { changeMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(AppTheme.Fonts.monthNavArrow)
                    .foregroundColor(AppTheme.Colors.actionPrimary)
            }
        }
    }

    /// S M T W T F S header row.
    var weekdayHeaderRow: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols.indices, id: \.self) { index in
                Text(weekdaySymbols[index])
                    .font(AppTheme.Fonts.monthWeekdayLabel)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Date Grid

private extension MonthCalendarView {

    /// The rows × columns grid of day cells for the displayed month.
    var dateGrid: some View {
        let gridDates = displayedMonth.monthGridDates()
        let rows = gridDates.chunked(into: columnCount)

        return VStack(spacing: AppTheme.Spacing.monthGridRowSpacing) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 0) {
                    ForEach(rows[rowIndex].indices, id: \.self) { colIndex in
                        let date = rows[rowIndex][colIndex]
                        dayCell(for: date)
                    }
                }
            }
        }
    }

    /// A single day cell: number, optional today-highlight, selection ring, and dots.
    func dayCell(for date: Date) -> some View {
        let calendar = Calendar.current
        let isCurrentMonth = date.isSameMonth(as: displayedMonth)
        let isToday = calendar.isDateInToday(date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let dots = assignmentDots(for: date)

        return Button {
            withAnimation(.easeInOut(duration: AppTheme.defaultAnimationDuration)) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: AppTheme.Spacing.monthDotSpacing) {
                Text("\(calendar.component(.day, from: date))")
                    .font(AppTheme.Fonts.monthDay)
                    .foregroundColor(dayNumberColor(
                        isCurrentMonth: isCurrentMonth,
                        isToday: isToday
                    ))
                    .frame(
                        width: AppTheme.Spacing.monthCellSize,
                        height: AppTheme.Spacing.monthCellSize
                    )
                    .background(todayBackground(isToday: isToday))
                    .overlay(selectionRing(isSelected: isSelected))

                dotRow(colors: dots)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Cell Decorations

private extension MonthCalendarView {

    /// Foreground color for a day number based on context.
    func dayNumberColor(isCurrentMonth: Bool, isToday: Bool) -> Color {
        if isToday        { return AppTheme.Colors.textPrimary }
        if isCurrentMonth { return AppTheme.Colors.textPrimary }
        return AppTheme.Colors.textSecondary
    }

    /// Filled circle behind today's number.
    func todayBackground(isToday: Bool) -> some View {
        Group {
            if isToday {
                Circle()
                    .fill(AppTheme.Colors.actionPrimary)
            }
        }
    }

    /// Thin ring around the selected date.
    func selectionRing(isSelected: Bool) -> some View {
        Group {
            if isSelected {
                Circle()
                    .stroke(AppTheme.Colors.actionPrimary, lineWidth: 2)
            }
        }
    }

    /// Row of colored dots (one per assignment due that date, max 3).
    func dotRow(colors: [Color]) -> some View {
        HStack(spacing: AppTheme.Spacing.monthDotSpacing) {
            if colors.isEmpty {
                // Invisible dot preserves row height so cells don't jump.
                Circle()
                    .fill(Color.clear)
                    .frame(
                        width: AppTheme.Spacing.monthDotSize,
                        height: AppTheme.Spacing.monthDotSize
                    )
            } else {
                ForEach(colors.indices, id: \.self) { index in
                    Circle()
                        .fill(colors[index])
                        .frame(
                            width: AppTheme.Spacing.monthDotSize,
                            height: AppTheme.Spacing.monthDotSize
                        )
                }
            }
        }
    }
}

// MARK: - Data Helpers

private extension MonthCalendarView {

    /// The course-palette colors for assignments due on a given date (max 3 dots).
    func assignmentDots(for date: Date) -> [Color] {
        let maxDots = 3
        let calendar = Calendar.current

        let dueThatDay = assignments.values
            .flatMap { $0 }
            .filter { assignment in
                guard let due = assignment.dueDate else { return false }
                return calendar.isDate(due, inSameDayAs: date)
            }

        // Map each assignment to its course's color via scheduleBlocks.
        return Array(
            dueThatDay.compactMap { assignment in
                scheduleBlocks
                    .first { "\($0.courseId)" == assignment.courseId }
                    .map { AppTheme.Colors.courseColor(for: $0.colorIndex) }
            }
            .prefix(maxDots)
        )
    }

    /// Advances or retreats the displayed month by `delta` months.
    func changeMonth(by delta: Int) {
        withAnimation(.easeInOut(duration: AppTheme.defaultAnimationDuration)) {
            if let newMonth = Calendar.current.date(
                byAdding: .month, value: delta, to: displayedMonth
            ) {
                displayedMonth = newMonth
            }
        }
    }
}

// MARK: - Array Chunking Helper

private extension Array {
    /// Splits an array into sub-arrays of `size` elements each.
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
