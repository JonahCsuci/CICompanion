//
//  NotificationSettingsView.swift
//  CICompanion
//
//  Settings screen for push notification preferences.
//  The student can toggle notifications on/off and choose
//  how many minutes before class they want to be reminded.
//
//  Both settings are stored in UserDefaults via @AppStorage,
//  so they persist across app launches and are accessible
//  from anywhere using the same key strings.
//

import SwiftUI

struct NotificationSettingsView: View {
    
    // MARK: - Persisted Settings
    // @AppStorage reads/writes to UserDefaults automatically.
    // "notificationsEnabled" defaults to false (opt-in).
    // "leadTimeMinutes" defaults to 15 minutes before class.
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("leadTimeMinutes") private var leadTimeMinutes = 15
    
    // The student's enrolled courses, passed in from the parent view.
    // The scheduler needs these to know which classes to set reminders for.
    let courses: [Course]
    
    // The available lead-time options the student can pick from
    private let leadTimeOptions = [5, 10, 15, 30]
    
    var body: some View {
        Form {
            // MARK: - Notification Toggle Section
            Section {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
            } header: {
                Text("Push Notifications")
            } footer: {
                Text("When enabled, you'll receive reminders before your classes start.")
            }
            
            // MARK: - Lead Time Picker Section
            // Only shown when notifications are turned on
            if notificationsEnabled {
                Section {
                    Picker("Remind me", selection: $leadTimeMinutes) {
                        ForEach(leadTimeOptions, id: \.self) { minutes in
                            Text("\(minutes) minutes before")
                                .tag(minutes)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Reminder Time")
                } footer: {
                    Text("How far in advance you want to be notified before each class.")
                }
            }
        }
        .navigationTitle("Notification Settings")
        // MARK: - Reschedule When Settings Change
        // Whenever the toggle or lead time changes, cancel old notifications
        // and schedule new ones based on the updated preferences.
        .onChange(of: notificationsEnabled) {
            reschedule()
        }
        .onChange(of: leadTimeMinutes) {
            reschedule()
        }
    }
    
    // Triggers the scheduler to cancel and re-create all notifications
    // using the current settings and course list.
    private func reschedule() {
        Task {
            await NotificationScheduler.shared.rescheduleNotifications(for: courses)
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView(courses: [])
    }
}
