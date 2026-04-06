//
//  TodayView.swift
//  CICompanion
//
//  The main "Calendar" tab — shows the current date, a week-day selector,
//  expandable course cards, and assignment checklists with swipe-to-delete.
//  A menu in the top-right lets the user switch between Day / Week / Month views.
//

import SwiftUI

// MARK: - CalendarDisplayMode

/// The three calendar layout modes selectable from the top-right menu.
enum CalendarDisplayMode: String, CaseIterable {
    case day   = "Day"
    case week  = "Week"
    case month = "Month"

    /// SF Symbol shown next to each option in the menu.
    var iconName: String {
        switch self {
        case .day:   return "square.grid.2x2"
        case .week:  return "square.grid.3x3"
        case .month: return "calendar"
        }
    }
}

// MARK: - TodayView

/// Displays today's schedule with expandable course cards and an assignment checklist.
///
/// **Layout (top → bottom):**
/// 1. Formatted date header with a view-mode menu (Day / Week / Month)
/// 2. Horizontal Mon–Fri day selector with badge counts (Day mode only)
/// 3. Scrollable list of `CourseCardView` items for the selected day
///
/// Tapping a card expands it to reveal its assignment list and a gear button
/// that opens `NewAssignmentView` as a sheet.
struct TodayView: View {

    // MARK: - Dependencies

    /// The ViewModel that owns the student's schedule data.
    @StateObject var viewModel: AcademicCalendarViewModel

    // MARK: - Local State

    /// The active calendar layout (Day / Week / Month).
    @State private var displayMode: CalendarDisplayMode = .day

    /// The ID of the currently expanded course card (`nil` = all collapsed).
    @State private var expandedCardId: String?

    /// The course block the user tapped the gear icon on — drives the sheet.
    @State private var selectedCourse: CalendarScheduleBlock?

    /// Controls whether the "New Assignment" sheet is presented.
    @State private var showNewAssignment = false

    /// In-memory assignment storage, keyed by course-block ID (e.g. "1-Monday").
    @State private var assignments: [String: [Assignment]] = [:]

    /// The currently selected date in the week selector (defaults to today).
    @State private var selectedDate = Date()

    // MARK: - Body

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                dateHeader

                switch displayMode {
                case .day:
                    dayContent
                case .week:
                    weekContent
                case .month:
                    monthContent
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
        .onAppear { viewModel.loadSchedule() }
    }
}

private extension TodayView {

    /// The formatted date title with a view-mode menu icon on the right.
    var dateHeader: some View {
        HStack {
            Text(selectedDate.formattedWithOrdinal)
                .font(AppTheme.Fonts.title)
                .foregroundColor(AppTheme.Colors.textPrimary)

            Spacer()

            viewModeMenu
        }
        .padding(.horizontal, AppTheme.Spacing.screen)
        .padding(.top, 12)
        .padding(.bottom, AppTheme.Spacing.screen)
    }

    /// Top-right filter icon that opens a Day / Week / Month picker.
    var viewModeMenu: some View {
        Menu {
            ForEach(CalendarDisplayMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: AppTheme.defaultAnimationDuration)) {
                        displayMode = mode
                    }
                } label: {
                    Label(mode.rawValue, systemImage: mode.iconName)
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
                .font(AppTheme.Fonts.sectionHeader)
                .foregroundColor(AppTheme.Colors.actionPrimary)
        }
    }

    /// Day-mode content: week selector + course card list.
    var dayContent: some View {
        VStack(spacing: 0) {
            weekSelector
            courseList
        }
    }

    /// Week-mode content: embeds the weekly schedule grid without its own title / background.
    var weekContent: some View {
        ScheduleGridView(viewModel: viewModel, isEmbedded: true)
    }

    /// Month-mode placeholder (not yet designed).
    var monthContent: some View {
        VStack(spacing: AppTheme.Spacing.sectionGap) {
            Spacer()
            Image(systemName: "calendar")
                .font(AppTheme.Fonts.iconHero)
                .foregroundColor(AppTheme.Colors.actionPrimary)
            Text("Month View Coming Soon")
                .font(AppTheme.Fonts.toolbarActionBold)
                .foregroundColor(AppTheme.Colors.textPrimary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    /// Horizontal row of tappable Mon–Fri day buttons with assignment badges.
    var weekSelector: some View {
        let weekDates = selectedDate.weekdayDates()

        return HStack(spacing: AppTheme.Spacing.daySelectorSpacing) {
            ForEach(weekDates, id: \.self) { date in
                DaySelectorButton(
                    date: date,
                    isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                    badgeCount: incompleteAssignmentCount(for: date)
                ) {
                    withAnimation(.easeInOut(duration: AppTheme.defaultAnimationDuration)) {
                        selectedDate = date
                        expandedCardId = nil
                    }
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.screen)
        .padding(.bottom, AppTheme.Spacing.screen)
    }
}

private extension TodayView {

    /// The scrollable list of course cards (or a status message).
    var courseList: some View {
        ScrollView {
            VStack(spacing: 12) {
                if viewModel.isLoading {
                    loadingIndicator
                } else if let errorMessage = viewModel.errorMessage {
                    errorLabel(errorMessage)
                } else {
                    courseCards
                }
            }
            .padding(.horizontal, AppTheme.Spacing.screen)
            .padding(.bottom, 20)
        }
    }

    /// A centered spinner shown while data loads.
    var loadingIndicator: some View {
        ProgressView()
            .tint(AppTheme.Colors.textPrimary)
            .padding(.top, 40)
    }

    /// Red error text shown when loading fails.
    func errorLabel(_ message: String) -> some View {
        Text(message)
            .foregroundColor(AppTheme.Colors.error)
            .padding(.top, 40)
    }

    /// Either a list of `CourseCardView` items or a "No classes" placeholder.
    @ViewBuilder
    var courseCards: some View {
        let todayBlocks = blocksForSelectedDate()

        if todayBlocks.isEmpty {
            Text("No classes today")
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
        } else {
            ForEach(todayBlocks) { block in
                CourseCardView(
                    block: block,
                    isExpanded: expandedCardId == block.id,
                    assignments: assignments[block.id] ?? [],
                    timeLabel: timeUntilClass(for: block),
                    onToggleExpand: { toggleExpanded(block.id) },
                    onGearTapped: { selectedCourse = block },
                    onToggleAssignment: { toggleAssignment($0, blockId: block.id) },
                    onDeleteAssignment: { deleteAssignment($0, blockId: block.id) }
                )
            }
        }
    }
}

private extension TodayView {

    /// Expands or collapses a course card. Only one can be open at a time.
    func toggleExpanded(_ blockId: String) {
        withAnimation(.easeInOut(duration: AppTheme.defaultAnimationDuration)) {
            expandedCardId = (expandedCardId == blockId) ? nil : blockId
        }
    }

    /// Toggles an assignment's completion status.
    func toggleAssignment(_ assignment: Assignment, blockId: String) {
        guard var list = assignments[blockId],
              let index = list.firstIndex(where: { $0.id == assignment.id }) else { return }
        list[index].isCompleted.toggle()
        assignments[blockId] = list
    }

    /// Removes an assignment from its course.
    func deleteAssignment(_ assignment: Assignment, blockId: String) {
        assignments[blockId]?.removeAll { $0.id == assignment.id }
    }
}

private extension TodayView {

    /// Filters and sorts schedule blocks for the currently selected day.
    func blocksForSelectedDate() -> [CalendarScheduleBlock] {
        let dayName = selectedDate.fullDayName
        return viewModel.scheduleBlocks
            .filter { $0.day == dayName }
            .sorted { $0.startMinutes < $1.startMinutes }
    }

    /// Counts all *incomplete* assignments for a given calendar date.
    func incompleteAssignmentCount(for date: Date) -> Int {
        let dayName = date.fullDayName
        return viewModel.scheduleBlocks
            .filter { $0.day == dayName }
            .reduce(0) { total, block in
                total + (assignments[block.id] ?? []).filter { !$0.isCompleted }.count
            }
    }

    /// Returns a human-readable label for how long until a class starts.
    ///
    /// - "Now" if the class is in progress
    /// - "in 30min", "in 1h 15m" if upcoming
    /// - `""` if the class is in the past or on a different day
    func timeUntilClass(for block: CalendarScheduleBlock) -> String {
        let now = Date()
        let calendar = Calendar.current
        guard calendar.isDate(selectedDate, inSameDayAs: now) else { return "" }

        var startComponents = calendar.dateComponents([.year, .month, .day], from: now)
        startComponents.hour   = block.startMinutes / 60
        startComponents.minute = block.startMinutes % 60

        var endComponents = calendar.dateComponents([.year, .month, .day], from: now)
        endComponents.hour   = block.endMinutes / 60
        endComponents.minute = block.endMinutes % 60

        guard let classStart = calendar.date(from: startComponents),
              let classEnd   = calendar.date(from: endComponents) else { return "" }

        if now >= classStart && now <= classEnd { return "Now" }

        let secondsUntil = classStart.timeIntervalSince(now)
        guard secondsUntil > 0 else { return "" }

        let secondsPerHour: Double = 3600
        if secondsUntil < secondsPerHour {
            return "in \(Int(secondsUntil / 60))min"
        }
        let hours   = Int(secondsUntil / secondsPerHour)
        let minutes = Int(secondsUntil.truncatingRemainder(dividingBy: secondsPerHour) / 60)
        return minutes > 0 ? "in \(hours)h \(minutes)m" : "in \(hours)h"
    }
}

// MARK: - Preview

#Preview {
    TodayView(
        viewModel: AcademicCalendarViewModel(
            courseRepository: CourseRepository(studentRepository: StudentRepository()),
            studentRepository: StudentRepository()
        )
    )
}
