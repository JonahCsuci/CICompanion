//
//  NotificationScheduler.swift
//  CICompanion
//
//  Bridges course data and the NotificationManager.
//  Takes the student's courses, reads notification preferences,
//  and schedules (or cancels) weekly reminders for each class.
//
//  This class works with the existing Course model from the project.
//  When teammates swap mock data for a real API, the only change
//  needed is where the [Course] array comes from — this scheduler
//  doesn't care about the data source, just the Course objects.
//

import Foundation

class NotificationScheduler {
    
    // Shared singleton so it can be called from anywhere
    static let shared = NotificationScheduler()
    
    private let notificationManager = NotificationManager.shared
    
    private init() {}
    
    // MARK: - Reschedule All Notifications
    // This is the main entry point. Call this whenever:
    //   - The user changes notification settings (toggle or lead time)
    //   - The user's course list changes
    //
    // It cancels all existing notifications, then schedules fresh ones
    // based on current settings and courses.
    //
    // Parameters:
    //   - courses: The student's enrolled courses (from CourseRepository)
    func rescheduleNotifications(for courses: [Course]) async {
        // Step 1: Cancel all existing class notifications
        notificationManager.cancelAllNotifications()
        
        // Step 2: Check if notifications are enabled in settings
        let enabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        guard enabled else {
            // User turned notifications off — just cancel and stop
            return
        }
        
        // Step 3: Request permission (no-op if already granted)
        let granted = await notificationManager.requestPermission()
        guard granted else {
            print("Notification permission not granted — skipping scheduling.")
            return
        }
        
        // Step 4: Read the lead time from settings (default 15 minutes)
        let leadTimeMinutes = UserDefaults.standard.integer(forKey: "leadTimeMinutes")
        // If the value was never set, UserDefaults returns 0 — use 15 as fallback
        let leadTime = leadTimeMinutes > 0 ? leadTimeMinutes : 15
        
        // Step 5: Schedule a notification for each course + day combination
        for course in courses {
            await scheduleCourseNotifications(
                course: course,
                leadTimeMinutes: leadTime
            )
        }
        
    }
    
    // MARK: - Schedule Notifications for a Single Course
    // Creates one notification per day the course meets.
    // Skips asynchronous courses since they have no set time.
    private func scheduleCourseNotifications(
        course: Course,
        leadTimeMinutes: Int
    ) async {
        // Skip async courses — they have no scheduled start time
        guard !course.isAsynchronous else { return }
        
        // Parse the start time string (e.g. "9:00 AM") into hour and minute
        guard let (hour, minute) = parseTime(course.startTime) else {
            print("Could not parse start time '\(course.startTime)' for \(course.courseName)")
            return
        }
        
        // Subtract the lead time to get the notification time
        // e.g. class at 9:00 AM with 15 min lead -> notify at 8:45 AM
        var totalMinutes = hour * 60 + minute - leadTimeMinutes
        
        // Handle underflow (e.g. class at 12:05 AM with 10 min lead)
        if totalMinutes < 0 {
            totalMinutes += 24 * 60
        }
        
        let notifyHour = totalMinutes / 60
        let notifyMinute = totalMinutes % 60
        
        // Schedule one notification per day the course meets
        for day in course.days {
            guard let weekday = weekdayNumber(from: day) else {
                print("Unknown day '\(day)' for \(course.courseName)")
                continue
            }
            
            // Build date components for a weekly repeating trigger
            // weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
            var dateComponents = DateComponents()
            dateComponents.weekday = weekday
            dateComponents.hour = notifyHour
            dateComponents.minute = notifyMinute
            
            // Create a unique ID so we can identify/cancel individual notifications
            // Format: "course-{courseId}-{day}" e.g. "course-1-Monday"
            let notificationId = "course-\(course.id)-\(day)"
            
            // Build the notification body with location and time info
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
    
    // MARK: - Time Parsing Helper
    // Cached DateFormatter — these are expensive to create, so we reuse one instance.
    // Uses en_US_POSIX locale to reliably parse "h:mm a" format (e.g. "9:00 AM").
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    // Converts a time string like "9:00 AM" or "1:30 PM" into (hour, minute)
    // using 24-hour format. Returns nil if the string can't be parsed.
    private func parseTime(_ timeString: String) -> (hour: Int, minute: Int)? {
        guard let date = timeFormatter.date(from: timeString) else {
            return nil
        }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return (hour, minute)
    }
    
    // MARK: - Weekday Mapping Helper
    // Converts a day name string to its Calendar weekday number.
    // Calendar uses: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
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
