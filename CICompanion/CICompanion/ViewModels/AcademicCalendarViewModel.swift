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
                _ = try await studentRepository.loadStudent()
                let studentCourses = try await courseRepository.loadStudentCourses()
                
                buildSchedule(from: studentCourses)
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
    
    private func buildSchedule(from courses: [Course]) {
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
                        colorIndex: colorIndex
                    )
                )
            }
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
}
