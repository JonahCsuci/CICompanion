//
//  MyAcademicCalendarView.swift
//  CICompanion
//
//  Created by Codex on 3/24/26.
//

import SwiftUI

struct AcademicCalendarView: View {
    
    @StateObject var viewModel: AcademicCalendarViewModel
    @Environment(\.dismiss) private var dismiss
    
    private let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    private let startHour = 8
    private let endHour = 18
    private let hourRowHeight: CGFloat = 72
    private let timeColumnWidth: CGFloat = 74
    private let courseColors: [Color] = [.blue, .green, .orange, .pink, .teal, .indigo]
    
    init(viewModel: AcademicCalendarViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if viewModel.isLoading {
                        ProgressView("Loading schedule...")
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    } else {
                        legendSection
                        
                        if viewModel.scheduleBlocks.isEmpty && viewModel.asyncCourses.isEmpty {
                            Text("No classes in your schedule yet.")
                                .foregroundStyle(.secondary)
                        } else {
                            calendarSection
                        }
                    }
                }
                .padding()
            }
            
            ScheduleBottomBannerView(
                isShowingCalendar: true,
                onScheduleTapped: {
                    dismiss()
                },
                onCalendarTapped: {}
            )
        }
        .navigationTitle("My Academic Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadSchedule()
        }
    }
    
    private var legendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Legend")
                .font(.headline)
            
            ForEach(viewModel.legendItems) { item in
                HStack(alignment: .top, spacing: 10) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color(for: item.colorIndex))
                        .frame(width: 16, height: 16)
                        .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(item.courseCode) • \(item.courseName)")
                            .font(.subheadline.weight(.semibold))
                        Text("\(item.location) • \(item.timeDisplay)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            DisclosureGroup("Asynchronous Classes", isExpanded: $viewModel.isAsyncCoursesExpanded) {
                VStack(alignment: .leading, spacing: 10) {
                    if viewModel.asyncCourses.isEmpty {
                        Text("No asynchronous classes in your current schedule.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.asyncCourses) { course in
                            HStack(alignment: .top, spacing: 10) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(color(for: course.id % courseColors.count))
                                    .frame(width: 12, height: 12)
                                    .padding(.top, 3)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(course.courseCode) • \(course.courseName)")
                                        .font(.subheadline.weight(.semibold))
                                    Text("\(course.location) • Async")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(course.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Schedule")
                .font(.headline)
            
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
    
    private var timeColumn: some View {
        VStack(spacing: 0) {
            Text("")
                .frame(width: timeColumnWidth, height: 36)
            
            ForEach(startHour..<endHour, id: \.self) { hour in
                Text(hourLabel(hour))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: timeColumnWidth, height: hourRowHeight, alignment: .topLeading)
                    .padding(.leading, 4)
                    .overlay(alignment: .top) {
                        Divider()
                    }
            }
        }
    }
    
    private func dayColumn(for day: String) -> some View {
        let dayBlocks = viewModel.scheduleBlocks.filter { $0.day == day }
        let columnHeight = CGFloat(endHour - startHour) * hourRowHeight
        let columnWidth: CGFloat = 150
        
        return VStack(spacing: 0) {
            Text(shortDayLabel(day))
                .font(.subheadline.weight(.semibold))
                .frame(width: columnWidth, height: 36)
            
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    ForEach(startHour..<endHour, id: \.self) { _ in
                        Rectangle()
                            .stroke(Color(.systemGray4), lineWidth: 0.5)
                            .frame(width: columnWidth, height: hourRowHeight)
                    }
                }
                
                ForEach(dayBlocks) { block in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color(for: block.colorIndex).opacity(0.88))
                        .frame(
                            width: columnWidth - 16,
                            height: height(for: block)
                        )
                        .overlay(alignment: .topLeading) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(block.courseCode)
                                    .font(.caption.weight(.bold))
                                    .lineLimit(1)
                                Text(shortenedTitle(block.courseName))
                                    .font(.caption2.weight(.semibold))
                                    .lineLimit(2)
                                Text(block.location)
                                    .font(.caption2)
                                    .lineLimit(1)
                                Text("\(block.startTime) - \(block.endTime)")
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                            .foregroundStyle(.white)
                            .padding(8)
                        }
                        .offset(y: yOffset(for: block))
                }
            }
            .frame(width: columnWidth, height: columnHeight)
        }
    }
    
    private func color(for index: Int) -> Color {
        courseColors[index % courseColors.count]
    }
    
    private func yOffset(for block: CalendarScheduleBlock) -> CGFloat {
        let startMinutes = CGFloat(block.startMinutes - (startHour * 60))
        return max(0, startMinutes / 60 * hourRowHeight)
    }
    
    private func height(for block: CalendarScheduleBlock) -> CGFloat {
        let durationMinutes = max(block.endMinutes - block.startMinutes, 30)
        return CGFloat(durationMinutes) / 60 * hourRowHeight
    }
    
    private func hourLabel(_ hour: Int) -> String {
        let normalizedHour = hour == 12 ? 12 : hour % 12
        let meridiem = hour < 12 ? "AM" : "PM"
        return "\(normalizedHour):00 \(meridiem)"
    }
    
    private func shortDayLabel(_ day: String) -> String {
        String(day.prefix(3))
    }
    
    private func shortenedTitle(_ title: String) -> String {
        if title.count <= 18 {
            return title
        }
        
        return String(title.prefix(18)) + "..."
    }
}

#Preview {
    AcademicCalendarView(
        viewModel: AcademicCalendarViewModel(
            courseRepository: CourseRepository(studentRepository: StudentRepository()),
            studentRepository: StudentRepository()
        )
    )
}
