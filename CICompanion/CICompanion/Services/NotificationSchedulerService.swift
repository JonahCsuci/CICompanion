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
        for occurrence in course.scheduledOccurrences {
            guard let (hour, minute) = parseTime(occurrence.startTime) else {
                print("Could not parse start time '\(occurrence.startTime)' for \(course.courseName)")
                continue
            }

            // Subtract lead time (e.g. 9:00 AM class with 15 min lead -> notify at 8:45)
            var totalMinutes = hour * 60 + minute - leadTimeMinutes

            // Wrap around midnight if needed
            if totalMinutes < 0 {
                totalMinutes += 24 * 60
            }

            let notifyHour = totalMinutes / 60
            let notifyMinute = totalMinutes % 60

            for day in occurrence.days {
                guard let weekday = weekdayNumber(from: day) else {
                    print("Unknown day '\(day)' for \(course.courseName)")
                    continue
                }

                // weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
                var dateComponents = DateComponents()
                dateComponents.weekday = weekday
                dateComponents.hour = notifyHour
                dateComponents.minute = notifyMinute

                let notificationId = "course-\(occurrence.id)-\(day)"
                let body = "\(course.courseName) starts in \(leadTimeMinutes) minutes — \(occurrence.location)"

                await notificationManager.scheduleNotification(
                    id: notificationId,
                    title: "Upcoming Class: \(course.courseCode)",
                    body: body,
                    dateComponents: dateComponents,
                    repeats: true
                )
            }
        }
    }
    
    // Parse "9:00 AM" -> (hour: 9, minute: 0) in 24-hour format
    private func parseTime(_ timeString: String) -> (hour: Int, minute: Int)? {
        guard let totalMinutes = DateHelper.timeStringToMinutes(timeString) else {
            return nil
        }

        return (totalMinutes / 60, totalMinutes % 60)
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
