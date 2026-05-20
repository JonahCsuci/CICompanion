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
    let date: Date?
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
    
    func buildSchedule(courses: [Course], meetings: [MeetingProposal], events: [Event]) {
        var nextBlocks: [CalendarScheduleBlock] = []
        var nextLegendItems: [CalendarLegendItem] = []
        var nextAsyncCourses: [AsyncCourseItem] = []
        
        for course in courses {
            let colorIndex = course.id % colorCount
            let scheduledOccurrences = course.scheduledOccurrences
            
            if scheduledOccurrences.isEmpty {
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

            nextLegendItems.append(
                CalendarLegendItem(
                    id: course.id,
                    courseName: course.courseName,
                    courseCode: course.courseCode,
                    location: course.location,
                    timeDisplay: course.scheduleSummary,
                    colorIndex: colorIndex
                )
            )
            
            for occurrence in scheduledOccurrences {
                guard
                    let startMinutes = DateHelper.timeStringToMinutes(occurrence.startTime),
                    let endMinutes = DateHelper.timeStringToMinutes(occurrence.endTime)
                else {
                    continue
                }

                for day in occurrence.days {
                    nextBlocks.append(
                        CalendarScheduleBlock(
                            id: "\(occurrence.id)-\(day)",
                            courseId: course.id,
                            courseName: course.courseName,
                            courseCode: course.courseCode,
                            location: occurrence.location,
                            startTime: occurrence.startTime,
                            endTime: occurrence.endTime,
                            day: day,
                            date: nil,
                            startMinutes: startMinutes,
                            endMinutes: endMinutes,
                            colorIndex: colorIndex,
                            isMeeting: false
                        )
                    )
                }
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
                date: proposal.timeRange.day,
                startMinutes: proposal.timeRange.startTime,
                endMinutes: proposal.timeRange.endTime,
                colorIndex: -1,
                isMeeting: true
            ))
        }

        for (index, event) in events.enumerated() {
            let dayName = formatter.string(from: event.timeRange.day)
            nextBlocks.append(
                CalendarScheduleBlock(
                    id: "event-\(index)-\(event.timeRange.day)-\(event.timeRange.startTime)",
                    courseId: -2,
                    courseName: event.name,
                    courseCode: "[EVENT]",
                    location: event.location,
                    startTime: DateHelper.minutesToTimeString(event.timeRange.startTime),
                    endTime: DateHelper.minutesToTimeString(event.timeRange.endTime),
                    day: dayName,
                    date: event.timeRange.day,
                    startMinutes: event.timeRange.startTime,
                    endMinutes: event.timeRange.endTime,
                    colorIndex: 0,
                    isMeeting: false
                )
            )
        }
        
        scheduleBlocks = nextBlocks
        legendItems = nextLegendItems.sorted { $0.courseCode < $1.courseCode }
        asyncCourses = nextAsyncCourses.sorted { $0.courseCode < $1.courseCode }
    }
    
}
