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
    @ObservedObject var sessionManager: SessionManager
    @State private var showSignIn = false
    
    let studentRepository: StudentRepositoryProtocol
    
    init (
        viewModel: AcademicCalendarViewModel,
        studentRepository: StudentRepositoryProtocol,
        sessionManager: SessionManager
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.sessionManager = sessionManager
        self.studentRepository = studentRepository
    }
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

    /// Active calendar mode — Day (existing TodayView), Week (schedule grid), or Month (grid).
    @State private var mode: CalendarMode = .day

    // MARK: - Theme aliases

    /// Aliases into `ViewHelper` for readability at call-sites. Keeping these named
    /// lets the body read like the mockup ("bgColor", "cardBgColor") without hard-coded values.
    private var bgColor: Color { ViewHelper.bgColor }
    private var cardBgColor: Color { ViewHelper.fieldBgColor }

    // MARK: - Body
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                VStack(alignment: .leading, spacing: ViewHelper.biggerSpacing) {
                    HStack {
                        Text(formattedHeader())
                            .font(.system(size: Layout.headerTitleSize, weight: .bold))
                            .foregroundColor(ViewHelper.textImportant)
                        Spacer()
                        if mode != .day && sessionManager.isSignedIn {
                            navButtons
                        }
                    }

                    modePicker

                    if mode == .day {
                        weekSelector()
                    }
                }
                .padding(.horizontal, ViewHelper.biggerSpacing)
                .padding(.top, ViewHelper.spacing + 4)
                .padding(.bottom, ViewHelper.biggerSpacing)
                
                // If session manager object doesn't contain a user,
                // Display to log in
                if !sessionManager.isSignedIn {
                    signInPrompt
                } else {
                    switch mode {
                    case .day:
                        dayContent
                    case .week:
                        ScheduleGridView(
                            viewModel: viewModel,
                            sessionManager: sessionManager,
                            weekAnchor: selectedDate,
                            showsTitle: false,
                            assignmentCountForDate: { assignmentCountForDate($0) }
                        )
                    case .month:
                        monthContent
                    }
                }
            }
        }
        .task(id: sessionManager.isSignedIn) {
            if sessionManager.isSignedIn {
                _ = try? await studentRepository.ensureStudentExists()
                viewModel.loadSchedule()
            } else {
                viewModel.scheduleBlocks = []
                viewModel.legendItems = []
                viewModel.asyncCourses = []
                viewModel.errorMessage = nil
            }
        }
        .sheet(isPresented: $showSignIn) {
            SignInView(sessionManager: sessionManager)
        }
        .sheet(item: $selectedCourse) { course in
            NewAssignmentView(
                course: course,
                isPresented: Binding(
                    get: { selectedCourse != nil },
                    set: { if !$0 { selectedCourse = nil } }
                ),
                assignments: $assignments,
                initialDate: selectedDate
            )
        }
    }

    // MARK: - Mode Picker / Nav

    private enum CalendarMode: String, CaseIterable, Identifiable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
        var id: String { rawValue }
    }

    /// Layout constants for the Day/Week/Month UI. Keeps magic numbers out of the view body.
    private enum Layout {
        // Header + mode picker
        static let headerTitleSize: CGFloat = 26
        static let modePickerHeight: CGFloat = 36
        static let modePickerTextSize: CGFloat = 14
        static let navButtonSize: CGFloat = 32
        static let navIconSize: CGFloat = 16
        static let navSpacing: CGFloat = 14

        // Sign-in prompt
        static let signInSpacerHeight: CGFloat = 50
        static let signInHeadlineSize: CGFloat = 28
        static let signInHorizontalPadding: CGFloat = 30
        static let signInButtonWidth: CGFloat = 200
        static let signInButtonHeight: CGFloat = 50
        static let signInButtonTextSize: CGFloat = 18
        static let signInButtonCornerRadius: CGFloat = 12

        // Week selector (Day mode day chips)
        static let weekChipHeight: CGFloat = 58
        static let weekChipCornerRadius: CGFloat = 14
        static let weekChipDayNumberSize: CGFloat = 18
        static let weekChipDayNameSize: CGFloat = 11
        static let weekChipVerticalPadding: CGFloat = 10
        static let weekBadgeSize: CGFloat = 18
        static let weekBadgeTextSize: CGFloat = 10
        static let selectedChipTextOpacity = 0.85

        // Course card
        static let cardPadding: CGFloat = 14
        static let cardCornerRadius: CGFloat = 12
        static let cardChevronSize: CGFloat = 12
        static let cardChevronFrameWidth: CGFloat = 16
        static let cardChevronTopPadding: CGFloat = 5
        static let cardChevronTrailingPadding: CGFloat = 6
        static let cardTimeColumnWidth: CGFloat = 72
        static let cardTimeTextSize: CGFloat = 13
        static let cardAccentBarWidth: CGFloat = 3
        static let cardAccentBarCornerRadius: CGFloat = 1.5
        static let cardAccentBarTrailingPadding: CGFloat = 10
        static let cardTitleTextSize: CGFloat = 15
        static let cardLocationTextSize: CGFloat = 12
        static let cardMissingTextSize: CGFloat = 11
        static let cardGearIconSize: CGFloat = 14
        static let cardTimeUntilTextSize: CGFloat = 12

        // Expanded assignments section
        static let expandedSpacing: CGFloat = 12
        static let expandedHeadingTextSize: CGFloat = 14
        static let expandedBadgeSize: CGFloat = 18
        static let expandedBadgeTextSize: CGFloat = 10
        static let assignmentCheckboxIconSize: CGFloat = 18
        static let assignmentTitleTextSize: CGFloat = 13
        static let assignmentStarIconSize: CGFloat = 10
        static let assignmentDetailsTextSize: CGFloat = 11
        static let assignmentEmptyTextSize: CGFloat = 12
        static let dividerColor = Color(white: 0.25)

        // Month grid
        static let monthCellMinHeight: CGFloat = 48
        static let monthCellCornerRadius: CGFloat = 8
        static let monthGridSpacing: CGFloat = 6
        static let monthWeekdayTextSize: CGFloat = 11
        static let monthDayTextSize: CGFloat = 14
        static let monthDotSize: CGFloat = 5
        static let monthDotRowHeight: CGFloat = 6
        static let monthDotsShown = 3
        static let monthClassRowBarWidth: CGFloat = 3
        static let monthClassRowBarHeight: CGFloat = 28
        static let monthClassTitleSize: CGFloat = 14
        static let monthClassSubtitleSize: CGFloat = 11
        static let monthAddIconSize: CGFloat = 18

        // Accents that aren't in ViewHelper
        static let nowAccent = Color(red: 0.4, green: 0.85, blue: 0.5)
        static let priorityAccent = Color(red: 1.0, green: 0.85, blue: 0.3)
        static let completedCheckmark = Color(red: 0.2, green: 0.8, blue: 0.4)
    }

    /// Course palette for Day/Month cards. Meeting blocks override this via `ViewHelper.accentMeeting`.
    private static let courseColors: [Color] = [
        Color(red: 1.0, green: 0.65, blue: 0.0),
        ViewHelper.accentGreen,
        Color(red: 0.85, green: 0.35, blue: 0.90),
        Color(red: 0.4, green: 0.65, blue: 1.0),
        Color(red: 1.0, green: 0.4, blue: 0.6),
        Color(red: 0.3, green: 0.85, blue: 0.45)
    ]

    /// Mon–Sun chip count, used by the Day-mode week selector.
    private static let weekdayChipCount = 7

    private var modePicker: some View {
        HStack(spacing: ViewHelper.smallPadding) {
            ForEach(CalendarMode.allCases) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        mode = item
                        expandedCardId = nil
                    }
                } label: {
                    Text(item.rawValue)
                        .font(.system(size: Layout.modePickerTextSize, weight: .semibold))
                        .foregroundColor(mode == item ? ViewHelper.textImportant : ViewHelper.text)
                        .frame(maxWidth: .infinity)
                        .frame(height: Layout.modePickerHeight)
                        .background(
                            RoundedRectangle(cornerRadius: ViewHelper.componentRounding)
                                .fill(mode == item ? ViewHelper.accentBlue : ViewHelper.fieldBgColor)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var navButtons: some View {
        HStack(spacing: Layout.navSpacing) {
            navButton(systemName: "chevron.left")  { shiftDate(by: -1) }
            navButton(systemName: "chevron.right") { shiftDate(by:  1) }
        }
    }

    private func navButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: Layout.navIconSize, weight: .semibold))
                .foregroundColor(ViewHelper.textImportant)
                .frame(width: Layout.navButtonSize, height: Layout.navButtonSize)
                .background(Circle().fill(ViewHelper.fieldBgColor))
        }
    }

    private func shiftDate(by units: Int) {
        let cal = Calendar.current
        let component: Calendar.Component = (mode == .month) ? .month : .weekOfYear
        if let next = cal.date(byAdding: component, value: units, to: selectedDate) {
            selectedDate = next
        }
    }

    // MARK: - Day Content

    private var dayContent: some View {
        ScrollView {
            VStack(spacing: ViewHelper.spacing + 4) {
                if viewModel.isLoading {
                    CILoadingPage()
                } else if let errorMessage = viewModel.errorMessage {
                    CIErrorMessage(errorMessage: errorMessage)
                } else {
                    let todayBlocks = blocksForSelectedDate()
                    let extraDueItems = offDayAssignments(for: selectedDate,
                                                          todayBlockIds: Set(todayBlocks.map { $0.id }))
                    
                    if todayBlocks.isEmpty && extraDueItems.isEmpty {
                        Text("No classes today")
                            .foregroundColor(ViewHelper.text)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else {
                        ForEach(todayBlocks) { block in
                            courseCard(for: block)
                        }
                        
                        if !extraDueItems.isEmpty {
                            otherDueSection(items: extraDueItems)
                        }
                    }
                }
            }
            .padding(.horizontal, ViewHelper.biggerSpacing)
            .padding(.bottom, ViewHelper.biggerSpacing + 4)
        }
    }
    
    // MARK: - Off-day Assignments
    
    /// An assignment due on the selected day whose parent class doesn't meet that day.
    private struct OffDayAssignment: Identifiable {
        let id: String
        let block: CalendarScheduleBlock
        let assignment: Assignment
    }
    
    /// Collects assignments due on `date` that live under a class block not listed in `todayBlockIds`,
    /// so we can show them even when the class isn't meeting that day.
    private func offDayAssignments(for date: Date,
                                   todayBlockIds: Set<String>) -> [OffDayAssignment] {
        let cal = Calendar.current
        var items: [OffDayAssignment] = []
        let blocksById = Dictionary(uniqueKeysWithValues: viewModel.scheduleBlocks.map { ($0.id, $0) })
        
        for (blockId, courseAssignments) in assignments where !todayBlockIds.contains(blockId) {
            guard let block = blocksById[blockId] else { continue }
            for assignment in courseAssignments {
                if cal.isDate(assignment.dueDate, inSameDayAs: date) {
                    items.append(OffDayAssignment(id: assignment.id, block: block, assignment: assignment))
                }
            }
        }
        
        return items.sorted { $0.assignment.dueDate < $1.assignment.dueDate }
    }
    
    /// Renders a card listing assignments due on the selected day.
    /// Used by both Day mode ("Also due today") and Month mode ("Due this day").
    private func otherDueSection(items: [OffDayAssignment], title: String = "Also due today") -> some View {
        VStack(alignment: .leading, spacing: ViewHelper.spacing) {
            Text(title)
                .font(.system(size: Layout.expandedHeadingTextSize, weight: .semibold))
                .foregroundColor(ViewHelper.textImportant)
            
            VStack(spacing: 4) {
                ForEach(items) { item in
                    offDayAssignmentRow(item)
                }
            }
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBgColor)
        .cornerRadius(Layout.cardCornerRadius)
    }
    
    private func offDayAssignmentRow(_ item: OffDayAssignment) -> some View {
        let color = courseColor(for: item.block)
        
        return SwipeToDeleteRow(
            onDelete: { deleteAssignment(item.assignment, blockId: item.block.id) }
        ) {
            HStack(spacing: 10) {
                Button(action: {
                    toggleAssignment(item.assignment, blockId: item.block.id)
                }) {
                    Image(systemName: item.assignment.isCompleted ? "checkmark.square.fill" : "square")
                        .font(.system(size: Layout.assignmentCheckboxIconSize))
                        .foregroundColor(item.assignment.isCompleted ? Layout.completedCheckmark : ViewHelper.text)
                }
                
                RoundedRectangle(cornerRadius: Layout.cardAccentBarCornerRadius)
                    .fill(color)
                    .frame(width: Layout.cardAccentBarWidth, height: Layout.cardAccentBarTrailingPadding + 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(item.assignment.title)
                            .font(.system(size: Layout.assignmentTitleTextSize, weight: .medium))
                            .foregroundColor(item.assignment.isPriority && !item.assignment.isCompleted
                                             ? Layout.priorityAccent
                                             : ViewHelper.textImportant)
                            .strikethrough(item.assignment.isCompleted)
                        
                        if item.assignment.isPriority && !item.assignment.isCompleted {
                            Image(systemName: "star.fill")
                                .font(.system(size: Layout.assignmentStarIconSize))
                                .foregroundColor(Layout.priorityAccent)
                        }
                    }
                    
                    Text("\(item.block.courseCode) - \(item.block.courseName)")
                        .font(.system(size: Layout.assignmentDetailsTextSize))
                        .foregroundColor(color)
                        .lineLimit(1)
                    
                    if !item.assignment.details.isEmpty {
                        Text(item.assignment.details)
                            .font(.system(size: Layout.assignmentDetailsTextSize))
                            .foregroundColor(ViewHelper.text)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, ViewHelper.tinyPadding)
        }
    }

    // MARK: - Month Content

    private var monthContent: some View {
        ScrollView {
            VStack(spacing: ViewHelper.biggerSpacing - 2) {
                monthGrid
                    .padding(.horizontal, ViewHelper.biggerSpacing)

                let dayBlocks = blocksForSelectedDate()
                let dueItems = offDayAssignments(for: selectedDate, todayBlockIds: [])
                
                if !dayBlocks.isEmpty || !dueItems.isEmpty {
                    VStack(alignment: .leading, spacing: ViewHelper.spacing + 2) {
                        Text(formattedDate())
                            .font(.system(size: ViewHelper.textSize, weight: .semibold))
                            .foregroundColor(ViewHelper.textImportant)
                            .padding(.horizontal, ViewHelper.biggerSpacing)

                        if !dayBlocks.isEmpty {
                            VStack(spacing: ViewHelper.smallPadding) {
                                ForEach(dayBlocks) { block in
                                    monthDayClassRow(block)
                                }
                            }
                            .padding(.horizontal, ViewHelper.biggerSpacing)
                        }
                        
                        if !dueItems.isEmpty {
                            otherDueSection(items: dueItems, title: "Due this day")
                                .padding(.horizontal, ViewHelper.biggerSpacing)
                        }
                    }
                    .padding(.top, ViewHelper.tinyPadding)
                }
            }
            .padding(.bottom, ViewHelper.biggerSpacing + 4)
        }
    }

    private var monthGrid: some View {
        let cells = monthGridCells()
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: Layout.monthGridSpacing),
            count: Self.daysPerWeek
        )
        return VStack(spacing: ViewHelper.smallPadding) {
            HStack(spacing: Layout.monthGridSpacing) {
                ForEach(Array(Self.weekdaySymbols.enumerated()), id: \.offset) { _, sym in
                    Text(sym)
                        .font(.system(size: Layout.monthWeekdayTextSize, weight: .semibold))
                        .foregroundColor(ViewHelper.text)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: Layout.monthGridSpacing) {
                ForEach(cells) { cell in
                    monthDayCell(cell)
                }
            }
        }
    }

    private func monthDayCell(_ cell: MonthCell) -> some View {
        let isSelected = cell.date.map { Calendar.current.isDate($0, inSameDayAs: selectedDate) } ?? false
        let isToday = cell.date.map { Calendar.current.isDateInToday($0) } ?? false
        let dayBlocks = cell.date.map { blocks(for: $0) } ?? []
        let assignmentCount = cell.date.map { assignmentCountForDate($0) } ?? 0

        return Button {
            guard let date = cell.date else { return }
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedDate = date
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 4) {
                    if let date = cell.date {
                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.system(size: Layout.monthDayTextSize, weight: isToday ? .bold : .semibold))
                            .foregroundColor(isSelected
                                             ? ViewHelper.textImportant
                                             : (cell.isCurrentMonth ? ViewHelper.textImportant : ViewHelper.text))
                    } else {
                        Text(" ")
                            .font(.system(size: Layout.monthDayTextSize))
                    }

                    HStack(spacing: 2) {
                        ForEach(Array(dayBlocks.prefix(Layout.monthDotsShown).enumerated()), id: \.offset) { _, block in
                            Circle()
                                .fill(courseColor(for: block))
                                .frame(width: Layout.monthDotSize, height: Layout.monthDotSize)
                        }
                    }
                    .frame(height: Layout.monthDotRowHeight)
                }
                .frame(maxWidth: .infinity, minHeight: Layout.monthCellMinHeight)

                if assignmentCount > 0 {
                    assignmentBadge(count: assignmentCount)
                        .padding(3)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: Layout.monthCellCornerRadius)
                    .fill(isSelected
                          ? ViewHelper.accentBlue
                          : ViewHelper.fieldBgColor.opacity(cell.isCurrentMonth ? 1 : ViewHelper.opacity))
            )
        }
        .buttonStyle(.plain)
        .disabled(cell.date == nil)
    }

    /// Small count pill used on month/week day cells to surface pending assignments.
    private func assignmentBadge(count: Int) -> some View {
        Text("\(count)")
            .font(.system(size: Layout.weekBadgeTextSize, weight: .bold))
            .foregroundColor(ViewHelper.textImportant)
            .frame(minWidth: Layout.weekBadgeSize, minHeight: Layout.weekBadgeSize)
            .padding(.horizontal, 4)
            .background(Capsule().fill(ViewHelper.accentDarkBlue))
    }

    private func monthDayClassRow(_ block: CalendarScheduleBlock) -> some View {
        Button {
            selectedCourse = block
        } label: {
            HStack(spacing: ViewHelper.spacing + 2) {
                RoundedRectangle(cornerRadius: ViewHelper.borderWidth)
                    .fill(courseColor(for: block))
                    .frame(width: Layout.monthClassRowBarWidth,
                           height: Layout.monthClassRowBarHeight)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(block.courseCode) - \(block.courseName)")
                        .font(.system(size: Layout.monthClassTitleSize, weight: .semibold))
                        .foregroundColor(ViewHelper.textImportant)
                        .lineLimit(1)
                    Text("\(block.startTime) – \(block.endTime) · \(block.location)")
                        .font(.system(size: Layout.monthClassSubtitleSize))
                        .foregroundColor(ViewHelper.text)
                }
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: Layout.monthAddIconSize))
                    .foregroundColor(ViewHelper.accentBlue)
            }
            .padding(ViewHelper.spacing + 2)
            .background(ViewHelper.fieldBgColor)
            .cornerRadius(ViewHelper.componentRounding)
        }
        .buttonStyle(.plain)
    }

    private struct MonthCell: Identifiable {
        let id = UUID()
        let date: Date?
        let isCurrentMonth: Bool
    }

    /// Sunday-first column headers used by the month grid.
    private static let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]
    private static let daysPerWeek = 7

    private func monthGridCells() -> [MonthCell] {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: selectedDate)
        guard let first = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: first) else { return [] }

        // Pad with blank cells so the 1st lands in the correct weekday column (Sun = 0).
        let firstWeekday = cal.component(.weekday, from: first) // 1 = Sun
        let leadingBlanks = firstWeekday - 1

        var cells: [MonthCell] = Array(
            repeating: MonthCell(date: nil, isCurrentMonth: false),
            count: leadingBlanks
        )
        for day in range {
            if let d = cal.date(byAdding: .day, value: day - 1, to: first) {
                cells.append(MonthCell(date: d, isCurrentMonth: true))
            }
        }
        // Pad trailing blanks so the grid forms complete weeks.
        while cells.count % Self.daysPerWeek != 0 {
            cells.append(MonthCell(date: nil, isCurrentMonth: false))
        }
        return cells
    }

    private func blocks(for date: Date) -> [CalendarScheduleBlock] {
        let dayName = fullDayName(for: date)
        return viewModel.scheduleBlocks
            .filter { $0.day == dayName }
            .sorted { $0.startMinutes < $1.startMinutes }
    }

    /// Mode-aware header: Day shows the full date, Week shows "MMM d – MMM d", Month shows "MMMM yyyy".
    private func formattedHeader() -> String {
        switch mode {
        case .day:
            return formattedDate()
        case .week:
            let cal = Calendar.current
            let weekday = cal.component(.weekday, from: selectedDate)
            let mondayOffset = (weekday == 1) ? -6 : (2 - weekday)
            guard let monday = cal.date(byAdding: .day, value: mondayOffset, to: selectedDate),
                  let sunday = cal.date(byAdding: .day, value: 6, to: monday) else {
                return formattedDate()
            }
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM d"
            return "\(fmt.string(from: monday)) – \(fmt.string(from: sunday))"
        case .month:
            let fmt = DateFormatter()
            fmt.dateFormat = "MMMM yyyy"
            return fmt.string(from: selectedDate)
        }
    }
        
    
    // MARK: - Sign-In Prompt

    private var signInPrompt: some View {
        VStack {
            Spacer()
                .frame(height: Layout.signInSpacerHeight)

            Text("Sign in to view your schedule")
                .font(.system(size: Layout.signInHeadlineSize, weight: .semibold))
                .foregroundColor(ViewHelper.textImportant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.signInHorizontalPadding)

            Button {
                showSignIn = true
            } label: {
                Text("Sign In")
                    .font(.system(size: Layout.signInButtonTextSize, weight: .bold))
                    .foregroundColor(ViewHelper.textImportant)
                    .frame(width: Layout.signInButtonWidth, height: Layout.signInButtonHeight)
                    .background(ViewHelper.accentBlue)
                    .cornerRadius(Layout.signInButtonCornerRadius)
            }
            Spacer()
        }
    }

    // MARK: - Week Selector
    
    /// Builds the row of tappable day buttons (Mon–Fri) with assignment badges.
    private func weekSelector() -> some View {
        let weekDates = currentWeekDates()
        
        return HStack(spacing: ViewHelper.smallPadding) {
            ForEach(weekDates, id: \.self) { date in
                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                let day = Calendar.current.component(.day, from: date)
                let dayName = shortDayName(for: date)
                let badgeCount = assignmentCountForDate(date)
                
                VStack(spacing: 4) {
                    ZStack {
                        // Blue highlight behind the selected day
                        if isSelected {
                            RoundedRectangle(cornerRadius: Layout.weekChipCornerRadius)
                                .fill(ViewHelper.accentBlue)
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(day)")
                                .font(.system(size: Layout.weekChipDayNumberSize, weight: .bold))
                                .foregroundColor(isSelected ? ViewHelper.textImportant : ViewHelper.text)
                            
                            Text(dayName)
                                .font(.system(size: Layout.weekChipDayNameSize, weight: .medium))
                                .foregroundColor(isSelected
                                                 ? ViewHelper.textImportant.opacity(Layout.selectedChipTextOpacity)
                                                 : ViewHelper.text)
                        }
                        .padding(.vertical, Layout.weekChipVerticalPadding)
                    }
                    .frame(maxWidth: .infinity)   // Each day takes equal width
                    .frame(height: Layout.weekChipHeight)
                    
                    // Badge for incomplete assignments
                    if badgeCount > 0 {
                        Text("\(badgeCount)")
                            .font(.system(size: Layout.weekBadgeTextSize, weight: .bold))
                            .foregroundColor(ViewHelper.textImportant)
                            .frame(width: Layout.weekBadgeSize, height: Layout.weekBadgeSize)
                            .background(ViewHelper.accentDarkBlue)
                            .clipShape(Circle())
                    } else {
                        Color.clear.frame(width: Layout.weekBadgeSize, height: Layout.weekBadgeSize)
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
        let color = courseColor(for: block)
        let courseAssignments = assignments[block.id] ?? []
        let missingCount = courseAssignments.filter { !$0.isCompleted }.count
        
        return VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: Layout.cardChevronSize, weight: .semibold))
                    .foregroundColor(ViewHelper.text)
                    .frame(width: Layout.cardChevronFrameWidth)
                    .padding(.top, Layout.cardChevronTopPadding)
                    .padding(.trailing, Layout.cardChevronTrailingPadding)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(block.startTime)
                        .font(.system(size: Layout.cardTimeTextSize, weight: .regular))
                    Text(block.endTime)
                        .font(.system(size: Layout.cardTimeTextSize, weight: .regular))
                }
                .foregroundColor(ViewHelper.text)
                .frame(width: Layout.cardTimeColumnWidth, alignment: .leading)
                
                RoundedRectangle(cornerRadius: Layout.cardAccentBarCornerRadius)
                    .fill(color)
                    .frame(width: Layout.cardAccentBarWidth)
                    .padding(.vertical, 2)
                    .padding(.trailing, Layout.cardAccentBarTrailingPadding)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(block.courseCode) - \(block.courseName)")
                        .font(.system(size: Layout.cardTitleTextSize, weight: .bold))
                        .foregroundColor(color)
                        .lineLimit(2)
                    
                    HStack(spacing: ViewHelper.tinyPadding) {
                        Text(block.location)
                            .font(.system(size: Layout.cardLocationTextSize))
                            .foregroundColor(ViewHelper.text)
                        
                        if !isExpanded && missingCount > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: Layout.cardMissingTextSize))
                                    .foregroundColor(ViewHelper.accentRed)
                                Text("\(missingCount)")
                                    .font(.system(size: Layout.cardMissingTextSize, weight: .bold))
                                    .foregroundColor(ViewHelper.accentRed)
                                Text("Missing assignment")
                                    .font(.system(size: Layout.cardMissingTextSize))
                                    .foregroundColor(ViewHelper.text)
                            }
                        }
                    }
                }
                
                Spacer()
                
                if isExpanded {
                    Button {
                        selectedCourse = block
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: Layout.cardGearIconSize))
                            .foregroundColor(ViewHelper.accentBlue)
                    }
                    .padding(.top, 2)
                } else {
                    let timeLabel = timeUntilClass(for: block)
                    if !timeLabel.isEmpty {
                        Text(timeLabel)
                            .font(.system(size: Layout.cardTimeUntilTextSize, weight: .medium))
                            .foregroundColor(timeLabel == "Now" ? Layout.nowAccent : ViewHelper.text)
                            .padding(.top, 2)
                    }
                }
            }
            .padding(Layout.cardPadding)
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
        .cornerRadius(Layout.cardCornerRadius)
    }
    
    // MARK: - Expanded Content
    
    /// The assignment list shown when a course card is expanded.
    private func expandedContent(for block: CalendarScheduleBlock, color: Color) -> some View {
        let courseAssignments = assignments[block.id] ?? []
        let pendingCount = courseAssignments.filter { !$0.isCompleted }.count
        
        return VStack(alignment: .leading, spacing: Layout.expandedSpacing) {
            Divider()
                .background(Layout.dividerColor)
                .padding(.horizontal, -Layout.cardPadding)
            
            HStack(spacing: ViewHelper.smallPadding) {
                Text("Assignments")
                    .font(.system(size: Layout.expandedHeadingTextSize, weight: .semibold))
                    .foregroundColor(ViewHelper.textImportant)
                
                if pendingCount > 0 {
                    Text("\(pendingCount)")
                        .font(.system(size: Layout.expandedBadgeTextSize, weight: .bold))
                        .foregroundColor(ViewHelper.textImportant)
                        .frame(width: Layout.expandedBadgeSize, height: Layout.expandedBadgeSize)
                        .background(ViewHelper.accentBlue)
                        .clipShape(Circle())
                }
            }
            
            // Assignment list — each row is wrapped in SwipeToDeleteRow for swipe gesture
            if courseAssignments.isEmpty {
                Text("No assignments yet")
                    .font(.system(size: Layout.assignmentEmptyTextSize))
                    .foregroundColor(ViewHelper.text)
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
                                        .font(.system(size: Layout.assignmentCheckboxIconSize))
                                        .foregroundColor(
                                            assignment.isCompleted
                                            ? Layout.completedCheckmark
                                            : ViewHelper.text
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(assignment.title)
                                            .font(.system(size: Layout.assignmentTitleTextSize, weight: .medium))
                                            .foregroundColor(assignment.isPriority && !assignment.isCompleted
                                                             ? Layout.priorityAccent
                                                             : ViewHelper.textImportant)
                                            .strikethrough(assignment.isCompleted)
                                        
                                        if assignment.isPriority && !assignment.isCompleted {
                                            Image(systemName: "star.fill")
                                                .font(.system(size: Layout.assignmentStarIconSize))
                                                .foregroundColor(Layout.priorityAccent)
                                        }
                                    }
                                    
                                    if !assignment.details.isEmpty {
                                        Text(assignment.details)
                                            .font(.system(size: Layout.assignmentDetailsTextSize))
                                            .foregroundColor(ViewHelper.text)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, ViewHelper.tinyPadding)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, Layout.cardPadding)
        .padding(.bottom, Layout.cardPadding)
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
        return (0..<Self.weekdayChipCount).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }
    
    /// Counts incomplete assignments whose due date falls on the given calendar day.
    private func assignmentCountForDate(_ date: Date) -> Int {
        let cal = Calendar.current
        var count = 0
        for (_, courseAssignments) in assignments {
            for assignment in courseAssignments where !assignment.isCompleted {
                if cal.isDate(assignment.dueDate, inSameDayAs: date) {
                    count += 1
                }
            }
        }
        return count
    }
    
    private func courseColor(for block: CalendarScheduleBlock) -> Color {
        if block.isMeeting { return ViewHelper.accentMeeting }
        return Self.courseColors[block.colorIndex % Self.courseColors.count]
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
            // Only render the delete affordance once the user begins swiping,
            // otherwise its rounded edges peek out past short content rows.
            if offset < 0 {
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
                            .foregroundColor(ViewHelper.textImportant)
                            .frame(width: 50, height: 36)
                            .background(ViewHelper.accentRed)
                            .cornerRadius(8)
                    }
                }
            }
            
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ViewHelper.fieldBgColor)
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
        ), studentRepository: StudentRepository(), sessionManager: SessionManager()
    )
}

