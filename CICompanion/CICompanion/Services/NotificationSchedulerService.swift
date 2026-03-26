//
//  NotificationScheduler.swift
//  CICompanion
//
//  Connects course data to NotificationManager to schedule class reminders.
//

import Foundation

class NotificationSchedulerService {
    
    static let shared = NotificationSchedulerService()
    
    private let notificationManager = NotificationManagerService.shared
    
    private init() {}
    
    // Cancel existing notifications and reschedule based on current settings
    func rescheduleNotifications(for courses: [Course]) async {
        notificationManager.cancelAllNotifications()
        
        let enabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        guard enabled else { return }
        
        let granted = await notificationManager.requestPermission()
        guard granted else {
            print("Notification permission not granted — skipping scheduling.")
            return
        }
        
        // UserDefaults returns 0 if never set, so fall back to 15
        let leadTimeMinutes = UserDefaults.standard.integer(forKey: "leadTimeMinutes")
        let leadTime = leadTimeMinutes > 0 ? leadTimeMinutes : 15
        
        for course in courses {
            await scheduleCourseNotifications(
                course: course,
                leadTimeMinutes: leadTime
            )
        }
    }
    
    // Creates one notification per day the course meets. Skips async courses.
    private func scheduleCourseNotifications(
        course: Course,
        leadTimeMinutes: Int
    ) async {
        guard !course.isAsynchronous else { return }
        
        guard let (hour, minute) = parseTime(course.startTime) else {
            print("Could not parse start time '\(course.startTime)' for \(course.courseName)")
            return
        }
        
        // Subtract lead time (e.g. 9:00 AM class with 15 min lead -> notify at 8:45)
        var totalMinutes = hour * 60 + minute - leadTimeMinutes
        
        // Wrap around midnight if needed
        if totalMinutes < 0 {
            totalMinutes += 24 * 60
        }
        
        let notifyHour = totalMinutes / 60
        let notifyMinute = totalMinutes % 60
        
        for day in course.days {
            guard let weekday = weekdayNumber(from: day) else {
                print("Unknown day '\(day)' for \(course.courseName)")
                continue
            }
            
            // weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
            var dateComponents = DateComponents()
            dateComponents.weekday = weekday
            dateComponents.hour = notifyHour
            dateComponents.minute = notifyMinute
            
            // Unique ID per course + day, e.g. "course-1-Monday"
            let notificationId = "course-\(course.id)-\(day)"
            
            let body = "\(course.courseName) starts in \(leadTimeMinutes) minutes — \(course.location)"
            
            await notificationManager.scheduleNotification(
                id: notificationId,
                title: "Upcoming Class: \(course.courseCode)",
                body: body,
                dateComponents: dateComponents,
                repeats: true
            )
        }
    }
    
    // Cached formatter — DateFormatter is expensive to create
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    // Parse "9:00 AM" -> (hour: 9, minute: 0) in 24-hour format
    private func parseTime(_ timeString: String) -> (hour: Int, minute: Int)? {
        guard let date = timeFormatter.date(from: timeString) else {
            return nil
        }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return (hour, minute)
    }
    
    // Convert day name to Calendar weekday number (1 = Sunday ... 7 = Saturday)
    private func weekdayNumber(from day: String) -> Int? {
        switch day.lowercased() {
        case "sunday":    return 1
        case "monday":    return 2
        case "tuesday":   return 3
        case "wednesday": return 4
        case "thursday":  return 5
        case "friday":    return 6
        case "saturday":  return 7
        default:          return nil
        }
    }
}
