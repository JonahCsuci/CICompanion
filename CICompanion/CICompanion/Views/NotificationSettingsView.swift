//
//  NotificationSettingsView.swift
//  CICompanion
//
//  Settings screen for notification preferences (toggle + lead time).
//

import SwiftUI

struct NotificationSettingsView: View {
    
    // Stored in UserDefaults, persists across app launches
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("leadTimeMinutes") private var leadTimeMinutes = 15
    
    // Courses passed in from parent view for rescheduling
    let courses: [Course]
    
    private let leadTimeOptions = [5, 10, 15, 30]
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
            } header: {
                Text("Push Notifications")
            } footer: {
                Text("When enabled, you'll receive reminders before your classes start.")
            }
            
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
        // Reschedule notifications whenever settings change
        .onChange(of: notificationsEnabled) {
            reschedule()
        }
        .onChange(of: leadTimeMinutes) {
            reschedule()
        }
    }
    
    // Cancel and re-create all notifications with current settings
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
