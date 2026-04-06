//
//  AcademicCalendarView.swift
//  CICompanion
//
//  Full-week academic calendar with a colour-coded legend,
//  an asynchronous-courses disclosure group, and a scrollable
//  time-grid showing each day's course blocks.
//

import SwiftUI

/// Renders the student's weekly course schedule as a colour-coded calendar grid.
///
/// Data is loaded via `AcademicCalendarViewModel` which converts raw `Course`
/// models into positioned `CalendarScheduleBlock` items.
struct AcademicCalendarView: View {

    @StateObject var viewModel: AcademicCalendarViewModel
    @ObservedObject var sessionManager: SessionManager
    @Environment(\.dismiss) private var dismiss

    init(viewModel: AcademicCalendarViewModel, sessionManager: SessionManager) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.sessionManager = sessionManager
    }

    /// Weekday names displayed as column headers.
    private let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]

    /// Hour range for the visible grid rows.
    private let startHour = 8
    private let endHour   = 18

    /// Convenience aliases to keep layout code concise.
    private var hourRowHeight: CGFloat  { AppTheme.Spacing.calendarHourRowHeight }
    private var timeColumnWidth: CGFloat { AppTheme.Spacing.calendarTimeColumnWidth }
    private var dayColumnWidth: CGFloat  { AppTheme.Spacing.calendarDayColumnWidth }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    contentBody
                }
                .padding()
            }

            ScheduleBottomBannerView(
                isShowingCalendar: true,
                onScheduleTapped: { dismiss() },
                onCalendarTapped: {}
            )
        }
        .navigationTitle("My Academic Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.loadSchedule() }
    }
}

private extension AcademicCalendarView {

    /// Picks the appropriate content state: loading, error, empty, or populated.
    @ViewBuilder
    var contentBody: some View {
        if viewModel.isLoading {
            ProgressView("Loading schedule...")
                .frame(maxWidth: .infinity, alignment: .center)
        } else if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .foregroundStyle(AppTheme.Colors.error)
        } else if viewModel.scheduleBlocks.isEmpty && viewModel.asyncCourses.isEmpty {
            Text("No classes in your schedule yet.")
                .foregroundStyle(AppTheme.Colors.textSecondary)
        } else {
            legendSection
            calendarSection
        }
    }
}

private extension AcademicCalendarView {

    var legendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Legend")
                .font(AppTheme.Fonts.headline)

            ForEach(viewModel.legendItems) { item in
                legendRow(for: item)
            }

            asyncDisclosureGroup
        }
        .padding(AppTheme.Spacing.screen)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    func legendRow(for item: CalendarLegendItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 4)
                .fill(AppTheme.Colors.courseColor(for: item.colorIndex))
                .frame(width: 16, height: 16)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(item.courseCode) • \(item.courseName)")
                    .font(AppTheme.Fonts.subheadline)
                Text("\(item.location) • \(item.timeDisplay)")
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
    }

    var asyncDisclosureGroup: some View {
        DisclosureGroup("Asynchronous Classes", isExpanded: $viewModel.isAsyncCoursesExpanded) {
            VStack(alignment: .leading, spacing: 10) {
                if viewModel.asyncCourses.isEmpty {
                    Text("No asynchronous classes in your current schedule.")
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                } else {
                    ForEach(viewModel.asyncCourses) { course in
                        asyncCourseRow(for: course)
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    func asyncCourseRow(for course: AsyncCourseItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 4)
                .fill(AppTheme.Colors.courseColor(for: course.id % AppTheme.Colors.coursePalette.count))
                .frame(width: 12, height: 12)
                .padding(.top, 3)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(course.courseCode) • \(course.courseName)")
                    .font(AppTheme.Fonts.subheadline)
                Text("\(course.location) • Async")
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                Text(course.description)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .lineLimit(2)
            }
        }
    }
}

private extension AcademicCalendarView {

    var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Schedule")
                .font(AppTheme.Fonts.headline)

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 0) {
                    timeColumn
                    ForEach(days, id: \.self) { day in
                        dayColumn(for: day)
                    }
                }
            }
        }
    }

    var timeColumn: some View {
        VStack(spacing: 0) {
            Text("")
                .frame(width: timeColumnWidth, height: 36)

            ForEach(startHour..<endHour, id: \.self) { hour in
                Text(formattedHourLabel(hour))
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .frame(width: timeColumnWidth, height: hourRowHeight, alignment: .topLeading)
                    .padding(.leading, 4)
                    .overlay(alignment: .top) { Divider() }
            }
        }
    }

    func dayColumn(for day: String) -> some View {
        let dayBlocks    = viewModel.scheduleBlocks.filter { $0.day == day }
        let columnHeight = CGFloat(endHour - startHour) * hourRowHeight

        return VStack(spacing: 0) {
            Text(String(day.prefix(3)))
                .font(AppTheme.Fonts.subheadline)
                .frame(width: dayColumnWidth, height: 36)

            ZStack(alignment: .top) {
                gridLines
                courseBlocksOverlay(dayBlocks)
            }
            .frame(width: dayColumnWidth, height: columnHeight)
        }
    }

    var gridLines: some View {
        VStack(spacing: 0) {
            ForEach(startHour..<endHour, id: \.self) { _ in
                Rectangle()
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
                    .frame(width: dayColumnWidth, height: hourRowHeight)
            }
        }
    }

    func courseBlocksOverlay(_ blocks: [CalendarScheduleBlock]) -> some View {
        ForEach(blocks) { block in
            courseBlockCell(block)
                .offset(y: yOffset(for: block))
        }
    }

    func courseBlockCell(_ block: CalendarScheduleBlock) -> some View {
        RoundedRectangle(cornerRadius: AppTheme.Spacing.cardCornerRadius)
            .fill(AppTheme.Colors.courseColor(for: block.colorIndex).opacity(0.88))
            .frame(width: dayColumnWidth - AppTheme.Spacing.screen, height: blockHeight(for: block))
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(block.courseCode)
                        .font(AppTheme.Fonts.calendarCaptionBold)
                        .lineLimit(1)
                    Text(shortenedTitle(block.courseName))
                        .font(AppTheme.Fonts.calendarDetail)
                        .lineLimit(2)
                    Text(block.location)
                        .font(AppTheme.Fonts.calendarDetail)
                        .lineLimit(1)
                    Text("\(block.startTime) - \(block.endTime)")
                        .font(AppTheme.Fonts.calendarDetail)
                        .lineLimit(1)
                }
                .foregroundStyle(.white)
                .padding(8)
            }
    }
}

private extension AcademicCalendarView {

    func yOffset(for block: CalendarScheduleBlock) -> CGFloat {
        let startMinutes = CGFloat(block.startMinutes - (startHour * 60))
        return max(0, startMinutes / 60 * hourRowHeight)
    }

    func blockHeight(for block: CalendarScheduleBlock) -> CGFloat {
        let duration = max(block.endMinutes - block.startMinutes, 30)
        return CGFloat(duration) / 60 * hourRowHeight
    }

    func formattedHourLabel(_ hour: Int) -> String {
        let displayHour = hour == 12 ? 12 : hour % 12
        let meridiem    = hour < 12 ? "AM" : "PM"
        return "\(displayHour):00 \(meridiem)"
    }

    func shortenedTitle(_ title: String) -> String {
        title.count <= 18 ? title : String(title.prefix(18)) + "..."
    }
}

#Preview {
    AcademicCalendarView(
        viewModel: AcademicCalendarViewModel(
            courseRepository: CourseRepository(studentRepository: StudentRepository()),
            studentRepository: StudentRepository()
        ), sessionManager: SessionManager()
    )
}
