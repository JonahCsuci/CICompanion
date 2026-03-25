//
//  NotificationManager.swift
//  CICompanion
//
//  Handles scheduling and cancelling local push notifications.
//

import Foundation
import UserNotifications

class NotificationManager {
    
    static let shared = NotificationManager()
    
    private let center = UNUserNotificationCenter.current()
    
    private init() {}
    
    // Ask user for notification permission, returns true if granted
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
    
    // Schedule a local notification with a calendar-based trigger
    func scheduleNotification(
        id: String,
        title: String,
        body: String,
        dateComponents: DateComponents,
        repeats: Bool = true
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Fires weekly on the matching weekday/time when repeats is true
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: repeats
        )
        
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Error scheduling notification \(id): \(error)")
        }
    }
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }
    
    func cancelNotifications(withIds ids: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
