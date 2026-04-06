//
//  NotificationSettingsView.swift
//  CICompanion
//
//  Settings screen for notification preferences.
//  Users can toggle push notifications and choose how far in advance
//  they want to be reminded before each class.
//

import SwiftUI

// MARK: - NotificationSettingsView

/// A form-based settings screen for notification preferences.
///
/// Persists the user's choices in `UserDefaults` via `@AppStorage`
/// and triggers a reschedule whenever a value changes.
struct NotificationSettingsView: View {

    // MARK: - Persisted State

    /// Whether push notifications are enabled globally.
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false

    /// How many minutes before class the reminder should fire.
    @AppStorage("leadTimeMinutes") private var leadTimeMinutes = 15

    // MARK: - Input

    /// The student's courses — used to reschedule notifications on change.
    let courses: [Course]

    // MARK: - Constants

    /// Available lead-time options (in minutes).
    private let leadTimeOptions = [5, 10, 15, 30]

    // MARK: - Body

    var body: some View {
        Form {
            notificationToggleSection
            if notificationsEnabled { reminderTimeSection }
        }
        .navigationTitle("Notification Settings")
        .onChange(of: notificationsEnabled) { reschedule() }
        .onChange(of: leadTimeMinutes)      { reschedule() }
    }
}

private extension NotificationSettingsView {

    /// Toggle for enabling / disabling push notifications.
    var notificationToggleSection: some View {
        Section {
            Toggle("Enable Notifications", isOn: $notificationsEnabled)
        } header: {
            Text("Push Notifications")
        } footer: {
            Text("When enabled, you'll receive reminders before your classes start.")
        }
    }

    /// Picker for selecting how far in advance reminders fire.
    var reminderTimeSection: some View {
        Section {
            Picker("Remind me", selection: $leadTimeMinutes) {
                ForEach(leadTimeOptions, id: \.self) { minutes in
                    Text("\(minutes) minutes before").tag(minutes)
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

private extension NotificationSettingsView {

    /// Cancels existing notifications and re-creates them with current settings.
    func reschedule() {
        Task {
            await NotificationSchedulerService.shared.rescheduleNotifications(for: courses)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NotificationSettingsView(courses: [])
    }
}
