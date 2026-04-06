//
//  AssignmentRow.swift
//  CICompanion
//
//  A single row in the assignment checklist — checkbox, title,
//  optional priority star, and subtitle.
//

import SwiftUI

/// A single row in the assignment checklist — checkbox, title, optional star, subtitle.
struct AssignmentRow: View {

    let assignment: Assignment
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggle) {
                Image(systemName: assignment.isCompleted ? "checkmark.square.fill" : "square")
                    .font(AppTheme.Fonts.iconCheckboxSmall)
                    .foregroundColor(assignment.isCompleted ? AppTheme.Colors.success : AppTheme.Colors.textSecondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(assignment.title)
                        .font(AppTheme.Fonts.captionMedium)
                        .foregroundColor(priorityTextColor)
                        .strikethrough(assignment.isCompleted)

                    if assignment.isPriority && !assignment.isCompleted {
                        Image(systemName: "star.fill")
                            .font(AppTheme.Fonts.badge)
                            .foregroundColor(AppTheme.Colors.warning)
                    }
                }

                if !assignment.details.isEmpty {
                    Text(assignment.details)
                        .font(AppTheme.Fonts.micro)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }

    /// Priority items are gold; completed or normal items are white.
    private var priorityTextColor: Color {
        (assignment.isPriority && !assignment.isCompleted) ? AppTheme.Colors.warning : AppTheme.Colors.textPrimary
    }
}
