//
//  ScheduleBottomBannerView.swift
//  CICompanion
//
//  A two-button toggle bar pinned to the bottom of the schedule screen.
//  Lets users switch between "My Schedule" (list) and "Calendar" (grid).
//

import SwiftUI

// MARK: - ScheduleBottomBannerView

/// A bottom bar with two mutually exclusive buttons for switching views.
///
/// The selected button is highlighted; calling the corresponding
/// action closure is the parent's responsibility.
struct ScheduleBottomBannerView: View {

    /// Whether the calendar (grid) view is currently visible.
    let isShowingCalendar: Bool

    /// Called when the user taps "My Schedule".
    let onScheduleTapped: () -> Void

    /// Called when the user taps "Calendar".
    let onCalendarTapped: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            bannerButton(
                title: "My Schedule",
                systemImage: "list.bullet.rectangle",
                isSelected: !isShowingCalendar,
                action: onScheduleTapped
            )

            bannerButton(
                title: "Calendar",
                systemImage: "calendar",
                isSelected: isShowingCalendar,
                action: onCalendarTapped
            )
        }
        .padding(.horizontal, AppTheme.Spacing.screen)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }

    // MARK: - Private Helpers

    /// Builds a single banner toggle button.
    private func bannerButton(
        title: String,
        systemImage: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(isSelected ? Color.accentColor : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Spacing.selectorCornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(isSelected)
    }
}
