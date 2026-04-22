import SwiftUI

struct ScheduleGridView: View {
    
    // MARK: - Properties
    
    @StateObject var viewModel: AcademicCalendarViewModel
    @ObservedObject var sessionManager: SessionManager
    @State private var showSignIn = false

    /// Anchor date whose Monday–Friday week is displayed. Defaults to today.
    /// Passed in by TodayView's Week mode so the arrows can page through weeks.
    var weekAnchor: Date = Date()
    /// When true, hide the "Schedule" title header — the Today tab shows its own header.
    var showsTitle: Bool = true
    /// Optional callback that returns the count of pending assignments for a given day.
    /// When provided, a red badge is rendered on the day header.
    var assignmentCountForDate: ((Date) -> Int)? = nil

    // MARK: - Layout

    /// Layout constants for the schedule grid. Kept as a nested enum so each magic
    /// number has a name and lives in a single spot.
    private enum Layout {
        static let startHour = 9
        static let endHour = 15
        static let hourHeight: CGFloat = 80
        static let timeColumnWidth: CGFloat = 40
        static let daysPerWeek = 7
        static let gridLineColor = Color(white: 0.18)
        static let gridLineWidth: CGFloat = 0.5
        static let blockHorizontalInset: CGFloat = 2
        static let blockVerticalInset: CGFloat = 2
        static let minBlockHeight: CGFloat = 28
        static let blockCornerRadius: CGFloat = 6
        static let blockTitleSize: CGFloat = 11
        static let blockLocationSize: CGFloat = 9
        static let hourLabelSize: CGFloat = 12
        static let meridiemLabelSize: CGFloat = 9
        static let hourLabelYOffset: CGFloat = 16
        static let dayNumberSize: CGFloat = 20
        static let dayNameSize: CGFloat = 12
        static let dayHeaderCornerRadius: CGFloat = 12
        static let dayHeaderVerticalPadding: CGFloat = 8
        static let gridHorizontalPadding: CGFloat = 8
        static let gridBottomPadding: CGFloat = 20
        static let signInSpacerHeight: CGFloat = 50
        static let signInButtonWidth: CGFloat = 200
        static let signInButtonHeight: CGFloat = 50
        static let signInButtonCornerRadius: CGFloat = 12
        static let signInHeadlineSize: CGFloat = 28
        static let signInButtonTextSize: CGFloat = 18
        static let signInHorizontalPadding: CGFloat = 30
        static let courseNameLengthLimit = 14
        static let firstWordTruncationLimit = 8
        static let firstWordPrefix = 7
        static let unselectedDayOpacity = 0.85
        static let badgeSize: CGFloat = 16
        static let badgeTextSize: CGFloat = 10
    }

    /// The course color palette. Meeting blocks override this via `ViewHelper.accentMeeting`.
    private static let courseColors: [Color] = [
        Color(red: 1.0, green: 0.65, blue: 0.0),
        ViewHelper.accentGreen,
        Color(red: 0.85, green: 0.35, blue: 0.90),
        Color(red: 0.4, green: 0.65, blue: 1.0),
        Color(red: 1.0, green: 0.4, blue: 0.6),
        Color(red: 0.3, green: 0.85, blue: 0.45)
    ]

    // MARK: - Body
    
    var body: some View {
        ZStack {
            ViewHelper.bgColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                if showsTitle {
                    CIPageTitle("Schedule")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, ViewHelper.biggerSpacing)
                        .padding(.top, ViewHelper.spacing + 4)
                        .padding(.bottom, ViewHelper.spacing + 4)
                }
                
                if !sessionManager.isSignedIn {
                    signInPrompt
                } else {
                    dayHeaders()
                        .padding(.horizontal, Layout.gridHorizontalPadding)
                        .padding(.bottom, ViewHelper.tinyPadding)
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        gridContent()
                            .padding(.horizontal, Layout.gridHorizontalPadding)
                            .padding(.bottom, Layout.gridBottomPadding)
                    }
                }
            }
        }
        .task(id: sessionManager.isSignedIn) {
            if sessionManager.isSignedIn {
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
    
    // MARK: - Day Headers
    
    private func dayHeaders() -> some View {
        let weekDates = currentWeekDates()
        
        return HStack(spacing: 0) {
            Color.clear.frame(width: Layout.timeColumnWidth, height: 1)
            
            ForEach(0..<Layout.daysPerWeek, id: \.self) { i in
                let date = weekDates[i]
                let day = Calendar.current.component(.day, from: date)
                let dayName = shortDayName(for: date)
                let isToday = Calendar.current.isDateInToday(date)
                let badgeCount = assignmentCountForDate?(date) ?? 0
                
                VStack(spacing: 2) {
                    Text("\(day)")
                        .font(.system(size: Layout.dayNumberSize, weight: .bold))
                        .foregroundColor(isToday ? ViewHelper.textImportant : ViewHelper.text)
                    Text(dayName)
                        .font(.system(size: Layout.dayNameSize, weight: .medium))
                        .foregroundColor(isToday
                                         ? ViewHelper.textImportant.opacity(Layout.unselectedDayOpacity)
                                         : ViewHelper.text)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Layout.dayHeaderVerticalPadding)
                .background(
                    Group {
                        if isToday {
                            RoundedRectangle(cornerRadius: Layout.dayHeaderCornerRadius)
                                .fill(ViewHelper.accentBlue)
                        }
                    }
                )
                .overlay(alignment: .topTrailing) {
                    if badgeCount > 0 {
                        Text("\(badgeCount)")
                            .font(.system(size: Layout.badgeTextSize, weight: .bold))
                            .foregroundColor(ViewHelper.textImportant)
                            .frame(minWidth: Layout.badgeSize, minHeight: Layout.badgeSize)
                            .padding(.horizontal, 3)
                            .background(Capsule().fill(ViewHelper.accentDarkBlue))
                            .offset(x: -2, y: 2)
                    }
                }
            }
        }
    }
    
    // MARK: - Grid Content
    
    private func gridContent() -> some View {
        let totalHours = Layout.endHour - Layout.startHour
        let gridHeight = CGFloat(totalHours) * Layout.hourHeight
        
        return GeometryReader { geo in
            let gridWidth = geo.size.width
            let colWidth = (gridWidth - Layout.timeColumnWidth) / CGFloat(Layout.daysPerWeek)
            
            ZStack(alignment: .topLeading) {
                
                ForEach(0...totalHours, id: \.self) { i in
                    let y = CGFloat(i) * Layout.hourHeight
                    
                    Path { path in
                        path.move(to: CGPoint(x: Layout.timeColumnWidth, y: y))
                        path.addLine(to: CGPoint(x: gridWidth, y: y))
                    }
                    .stroke(Layout.gridLineColor, lineWidth: Layout.gridLineWidth)
                    
                    if i < totalHours {
                        let hour = Layout.startHour + i
                        VStack(spacing: 0) {
                            Text(formatHourLabel(hour))
                                .font(.system(size: Layout.hourLabelSize, weight: .medium))
                                .foregroundColor(ViewHelper.text)
                            Text(hour >= 12 ? "PM" : "AM")
                                .font(.system(size: Layout.meridiemLabelSize))
                                .foregroundColor(ViewHelper.text)
                        }
                        .position(x: Layout.timeColumnWidth / 2, y: y + Layout.hourLabelYOffset)
                    }
                }
                
                ForEach(0...Layout.daysPerWeek, id: \.self) { i in
                    let x = Layout.timeColumnWidth + CGFloat(i) * colWidth
                    Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: gridHeight))
                    }
                    .stroke(Layout.gridLineColor, lineWidth: Layout.gridLineWidth)
                }
                
                let weekDates = currentWeekDates()
                ForEach(viewModel.scheduleBlocks) { block in
                    if let col = dayIndex(for: block.day, in: weekDates) {
                        let x = Layout.timeColumnWidth + CGFloat(col) * colWidth + Layout.blockHorizontalInset
                        let y = CGFloat(block.startMinutes - Layout.startHour * 60) / 60.0 * Layout.hourHeight
                        let h = CGFloat(block.endMinutes - block.startMinutes) / 60.0 * Layout.hourHeight
                        
                        if y >= 0 && y < gridHeight {
                            courseBlock(
                                block: block,
                                width: colWidth - Layout.blockHorizontalInset * 2,
                                height: max(h - Layout.blockVerticalInset, Layout.minBlockHeight)
                            )
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
                .font(.system(size: Layout.blockTitleSize, weight: .bold))
                .lineLimit(3)
                .minimumScaleFactor(0.7)
            
            Text(block.location)
                .font(.system(size: Layout.blockLocationSize))
                .lineLimit(1)
        }
        .foregroundColor(ViewHelper.textImportant)
        .padding(.horizontal, ViewHelper.tinyPadding - 1)
        .padding(.vertical, 4)
        .frame(width: width, height: height, alignment: .topLeading)
        .background(courseColor(for: block))
        .cornerRadius(Layout.blockCornerRadius)
    }
    
    // MARK: - Helpers
    
    private func currentWeekDates() -> [Date] {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: weekAnchor)
        let mondayOffset = (weekday == 1) ? -6 : (2 - weekday)
        guard let monday = cal.date(byAdding: .day, value: mondayOffset, to: weekAnchor) else { return [] }
        return (0..<Layout.daysPerWeek).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
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
    
    private func displayName(_ name: String) -> String {
        if name.count <= Layout.courseNameLengthLimit { return name }
        
        let words = name.split(separator: " ")
        if words.count <= 2 { return name }
        
        let line = words.prefix(2).joined(separator: " ")
        if line.count <= Layout.courseNameLengthLimit { return line }
        
        let first = words[0].count > Layout.firstWordTruncationLimit
            ? String(words[0].prefix(Layout.firstWordPrefix)) + "."
            : String(words[0])
        return "\(first) \(words[1])"
    }
    
    private func courseColor(for block: CalendarScheduleBlock) -> Color {
        if block.isMeeting { return ViewHelper.accentMeeting }
        return Self.courseColors[block.colorIndex % Self.courseColors.count]
    }
}

#Preview {
    ScheduleGridView(
        viewModel: AcademicCalendarViewModel(
            courseRepository: CourseRepository(studentRepository: StudentRepository()),
            studentRepository: StudentRepository()
        ),
        sessionManager: SessionManager()
    )
}
