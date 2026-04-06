//
//  DaySelectorButton.swift
//  CICompanion
//
//  A single tappable day button used in the TodayView week selector.
//

import SwiftUI

/// A single tappable day button inside the week selector.
///
/// Shows the day number, short name, and a red badge when there
/// are incomplete assignments on that day.
struct DaySelectorButton: View {

    let date: Date
    let isSelected: Bool
    let badgeCount: Int
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: AppTheme.Spacing.selectorCornerRadius)
                        .fill(AppTheme.Colors.actionPrimary)
                }

                VStack(spacing: 4) {
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(AppTheme.Fonts.daySelector)
                        .foregroundColor(isSelected ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary)

                    Text(date.shortDayName)
                        .font(AppTheme.Fonts.microMedium)
                        .foregroundColor(isSelected ? AppTheme.Colors.textPrimary.opacity(0.85) : AppTheme.Colors.textSecondary)
                }
                .padding(.vertical, 10)
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.Spacing.daySelectorHeight)

            badgeOrSpacer
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    /// Shows a red count badge or an invisible spacer to keep alignment consistent.
    @ViewBuilder
    private var badgeOrSpacer: some View {
        if badgeCount > 0 {
            Text("\(badgeCount)")
                .font(AppTheme.Fonts.badge)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .frame(width: AppTheme.Spacing.badgeSize, height: AppTheme.Spacing.badgeSize)
                .background(AppTheme.Colors.error)
                .clipShape(Circle())
        } else {
            Color.clear
                .frame(width: AppTheme.Spacing.badgeSize, height: AppTheme.Spacing.badgeSize)
        }
    }
}
