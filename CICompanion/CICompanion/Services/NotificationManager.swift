//
//  NotificationManager.swift
//  CICompanion
//
//  Manages local push notifications for class reminders.
//  This is a standalone service — it doesn't depend on any specific
//  model or repository. Other parts of the app call its methods
//  with the data they already have (e.g. course name, time).
//
//  Responsibilities:
//  1. Request notification permissions from the user
//  2. Schedule a local notification for a specific date/time
//  3. Cancel all pending notifications (used when rescheduling)
//

import Foundation
import UserNotifications

class NotificationManager {
    
    // Shared singleton so any part of the app can access
    // the same notification manager instance
    static let shared = NotificationManager()
    
    // Reference to the system notification center
    private let center = UNUserNotificationCenter.current()
    
    private init() {}
    
    // MARK: - Request Permission
    // Asks the user for permission to show notifications.
    // Must be called before scheduling any notifications.
    // Returns true if permission was granted, false otherwise.
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }
    
    // MARK: - Schedule a Notification
    // Schedules a single local notification that fires at a specific time.
    //
    // Parameters:
    //   - id: A unique string identifier for this notification (used to cancel it later)
    //   - title: The bold headline shown in the notification (e.g. "Calculus I")
    //   - body: The detail text (e.g. "Starts in 15 minutes in Room 204")
    //   - dateComponents: The date/time components for when the notification should fire
    //                     (e.g. weekday + hour + minute for a weekly repeating reminder)
    //   - repeats: Whether this notification should repeat weekly (default: true)
    func scheduleNotification(
        id: String,
        title: String,
        body: String,
        dateComponents: DateComponents,
        repeats: Bool = true
    ) async {
        // Build the notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Calendar trigger fires at the specified date components
        // When repeats is true, it fires every week on the same day/time
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: repeats
        )
        
        // Create the request with the unique ID
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )
        
        // Add the request to the notification center
        do {
            try await center.add(request)
        } catch {
            print("Error scheduling notification \(id): \(error)")
        }
    }
    
    // MARK: - Cancel All Notifications
    // Removes all pending (not-yet-delivered) notifications.
    // Called before rescheduling so we don't get duplicates.
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }
    
    // MARK: - Cancel Specific Notifications
    // Removes only the notifications whose IDs match the given list.
    // Useful if you want to cancel notifications for a single course.
    func cancelNotifications(withIds ids: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
