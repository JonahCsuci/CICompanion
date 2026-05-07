//
//  AcademicCalendarViewModel.swift
//  CICompanion
//
//

import Foundation
import Combine

struct CalendarScheduleBlock: Identifiable {
    let id: String
    let courseId: Int
    let courseName: String
    let courseCode: String
    let location: String
    let startTime: String
    let endTime: String
    let day: String
    let startMinutes: Int
    let endMinutes: Int
    let colorIndex: Int
    let isMeeting: Bool
}

struct CalendarLegendItem: Identifiable {
    let id: Int
    let courseName: String
    let courseCode: String
    let location: String
    let timeDisplay: String
    let colorIndex: Int
}

struct AsyncCourseItem: Identifiable {
    let id: Int
    let courseName: String
    let courseCode: String
    let location: String
    let description: String
}

@MainActor
class AcademicCalendarViewModel: ObservableObject {
    
    @Published var scheduleBlocks: [CalendarScheduleBlock] = []
    @Published var legendItems: [CalendarLegendItem] = []
    @Published var asyncCourses: [AsyncCourseItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAsyncCoursesExpanded = true
    
    let courseRepository: CourseRepositoryProtocol
    let studentRepository: StudentRepositoryProtocol
    
    private let colorCount = 6
    
    init(
        courseRepository: CourseRepositoryProtocol,
        studentRepository: StudentRepositoryProtocol
    ) {
        self.courseRepository = courseRepository
        self.studentRepository = studentRepository
    }
    
    // Load the student's current schedule and project it into calendar display items.
    func loadSchedule() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let student = try await studentRepository.loadStudent()
                let studentCourses = try await courseRepository.loadStudentCourses()
                
                buildSchedule(courses: studentCourses, meetings: student.meetings, events: student.events)
                isLoading = false
            } catch {
                scheduleBlocks = []
                legendItems = []
                asyncCourses = []
                errorMessage = "Unable to load your schedule right now."
                isLoading = false
                print("Error loading academic calendar:", error)
            }
        }
    }
    
    private func buildSchedule(courses: [Course], meetings: [MeetingProposal], events: [String]) {
        var nextBlocks: [CalendarScheduleBlock] = []
        var nextLegendItems: [CalendarLegendItem] = []
        var nextAsyncCourses: [AsyncCourseItem] = []
        
        for course in courses {
            let colorIndex = course.id % colorCount
            
            if course.isAsynchronous {
                nextAsyncCourses.append(
                    AsyncCourseItem(
                        id: course.id,
                        courseName: course.courseName,
                        courseCode: course.courseCode,
                        location: course.location,
                        description: course.courseDescription
                    )
                )
                nextLegendItems.append(
                    CalendarLegendItem(
                        id: course.id,
                        courseName: course.courseName,
                        courseCode: course.courseCode,
                        location: course.location,
                        timeDisplay: "Asynchronous",
                        colorIndex: colorIndex
                    )
                )
                continue
            }
            
            guard
                let startMinutes = timeStringToMinutes(course.startTime),
                let endMinutes = timeStringToMinutes(course.endTime)
            else {
                continue
            }
            
            nextLegendItems.append(
                CalendarLegendItem(
                    id: course.id,
                    courseName: course.courseName,
                    courseCode: course.courseCode,
                    location: course.location,
                    timeDisplay: "\(course.startTime) - \(course.endTime)",
                    colorIndex: colorIndex
                )
            )
            
            for day in course.days {
                nextBlocks.append(
                    CalendarScheduleBlock(
                        id: "\(course.id)-\(day)",
                        courseId: course.id,
                        courseName: course.courseName,
                        courseCode: course.courseCode,
                        location: course.location,
                        startTime: course.startTime,
                        endTime: course.endTime,
                        day: day,
                        startMinutes: startMinutes,
                        endMinutes: endMinutes,
                        colorIndex: colorIndex,
                        isMeeting: false
                    )
                )
            }
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        
        for proposal in meetings {
            let dayName = formatter.string(from: proposal.timeRange.day)
            nextBlocks.append(CalendarScheduleBlock(
                id: "meeting-\(proposal.conversationID)-\(proposal.timeRange.startTime)",
                courseId: -1,
                courseName: proposal.title,
                courseCode: "[MEETING]",
                location: proposal.studyRoomID != nil ? proposal.studyRoom() : "",
                startTime: DateHelper.minutesToTimeString(proposal.timeRange.startTime),
                endTime: DateHelper.minutesToTimeString(proposal.timeRange.endTime),
                day: dayName,
                startMinutes: proposal.timeRange.startTime,
                endMinutes: proposal.timeRange.endTime,
                colorIndex: -1,
                isMeeting: true
            ))
        }

        for (index, event) in events.enumerated() {
            guard let parsed = parseDiscoveryEvent(event) else { continue }
            nextBlocks.append(
                CalendarScheduleBlock(
                    id: "event-\(index)-\(parsed.day)-\(parsed.startMinutes)",
                    courseId: -2,
                    courseName: parsed.title,
                    courseCode: "[EVENT]",
                    location: parsed.location,
                    startTime: parsed.startTime,
                    endTime: parsed.endTime,
                    day: parsed.day,
                    startMinutes: parsed.startMinutes,
                    endMinutes: parsed.endMinutes,
                    colorIndex: 0,
                    isMeeting: false
                )
            )
        }
        
        scheduleBlocks = nextBlocks
        legendItems = nextLegendItems.sorted { $0.courseCode < $1.courseCode }
        asyncCourses = nextAsyncCourses.sorted { $0.courseCode < $1.courseCode }
    }
    
    private func timeStringToMinutes(_ timeString: String) -> Int? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        
        guard let date = formatter.date(from: timeString) else {
            return nil
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else {
            return nil
        }
        
        return hour * 60 + minute
    }

    private func parseDiscoveryEvent(_ value: String) -> (title: String, day: String, startTime: String, endTime: String, startMinutes: Int, endMinutes: Int, location: String)? {
        let parts = value.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 4 else { return nil }

        let title = parts[0]
        let dayAndTime = parts[1]
        let location = parts[2]
        let fallbackDuration = max(Int(parts[3]) ?? 60, 30)

        let chunks = dayAndTime.components(separatedBy: "•").map { $0.trimmingCharacters(in: .whitespaces) }
        guard chunks.count == 2 else { return nil }
        let day = chunks[0]

        let timeParts = chunks[1].components(separatedBy: "-").map { $0.trimmingCharacters(in: .whitespaces) }
        guard let start = timeParts.first, let startMinutes = timeStringToMinutes(start) else { return nil }
        let endMinutes = timeParts.count > 1 ? (timeStringToMinutes(timeParts[1]) ?? (startMinutes + fallbackDuration)) : (startMinutes + fallbackDuration)
        let endTime = DateHelper.minutesToTimeString(endMinutes)

        return (
            title: title,
            day: day,
            startTime: start,
            endTime: endTime,
            startMinutes: startMinutes,
            endMinutes: endMinutes,
            location: location
        )
    }
}
