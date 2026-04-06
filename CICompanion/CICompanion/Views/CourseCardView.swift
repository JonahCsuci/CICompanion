//
//  CourseCardView.swift
//  CICompanion
//
//  An expandable card that shows one course's time, name, room,
//  and (when expanded) its assignment checklist.
//

import SwiftUI

/// An expandable card that shows one course's time, name, room,
/// and (when expanded) its assignment checklist.
struct CourseCardView: View {

    let block: CalendarScheduleBlock
    let isExpanded: Bool
    let assignments: [Assignment]
    let timeLabel: String

    // Callbacks — keeps this view stateless.
    let onToggleExpand: () -> Void
    let onGearTapped: () -> Void
    let onToggleAssignment: (Assignment) -> Void
    let onDeleteAssignment: (Assignment) -> Void

    /// The color for this course from the shared palette.
    private var color: Color { AppTheme.Colors.courseColor(for: block.colorIndex) }

    /// Number of incomplete assignments.
    private var missingCount: Int { assignments.filter { !$0.isCompleted }.count }

    var body: some View {
        VStack(spacing: 0) {
            collapsedHeader
            if isExpanded { expandedAssignmentList }
        }
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.Spacing.cardCornerRadius)
    }
}

// MARK: - Collapsed Header

private extension CourseCardView {

    /// The always-visible top row: chevron, times, color bar, course name, trailing info.
    var collapsedHeader: some View {
        HStack(alignment: .top, spacing: 0) {
            chevronIcon
            timeColumn
            colorBar
            courseInfo
            Spacer()
            trailingContent
        }
        .padding(AppTheme.Spacing.cardInternal)
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggleExpand)
    }

    var chevronIcon: some View {
        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            .font(AppTheme.Fonts.iconChevron)
            .foregroundColor(AppTheme.Colors.textSecondary)
            .frame(width: 16)
            .padding(.top, 5)
            .padding(.trailing, 6)
    }

    var timeColumn: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(block.startTime).font(AppTheme.Fonts.caption)
            Text(block.endTime).font(AppTheme.Fonts.caption)
        }
        .foregroundColor(AppTheme.Colors.textSecondary)
        .frame(width: AppTheme.Spacing.courseTimeColumnWidth, alignment: .leading)
    }

    var colorBar: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(color)
            .frame(width: AppTheme.Spacing.courseBarWidth)
            .padding(.vertical, 2)
            .padding(.trailing, 10)
    }

    var courseInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(block.courseCode) - \(block.courseName)")
                .font(AppTheme.Fonts.courseName)
                .foregroundColor(color)
                .lineLimit(2)

            HStack(spacing: 6) {
                Text(block.location)
                    .font(AppTheme.Fonts.smallCaption)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                if !isExpanded && missingCount > 0 {
                    missingAssignmentBadge
                }
            }
        }
    }

    /// Inline "⚠ N Missing assignment" indicator.
    var missingAssignmentBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(AppTheme.Fonts.micro)
                .foregroundColor(AppTheme.Colors.error)
            Text("\(missingCount)")
                .font(AppTheme.Fonts.gridBlockTitle)
                .foregroundColor(AppTheme.Colors.error)
            Text("Missing assignment")
                .font(AppTheme.Fonts.micro)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }

    /// Gear button (expanded) or time-until label (collapsed).
    @ViewBuilder
    var trailingContent: some View {
        if isExpanded {
            Button(action: onGearTapped) {
                Image(systemName: "gearshape.fill")
                    .font(AppTheme.Fonts.iconAction)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(.top, 2)
        } else if !timeLabel.isEmpty {
            Text(timeLabel)
                .font(AppTheme.Fonts.smallMedium)
                .foregroundColor(timeLabel == "Now" ? AppTheme.Colors.success : AppTheme.Colors.textSecondary)
                .padding(.top, 2)
        }
    }
}

// MARK: - Expanded Assignment List

private extension CourseCardView {

    /// The assignment checklist revealed when the card is expanded.
    var expandedAssignmentList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .background(AppTheme.Colors.gridLine)
                .padding(.horizontal, -AppTheme.Spacing.cardInternal)

            HStack(spacing: 8) {
                Text("Assignments")
                    .font(AppTheme.Fonts.subheadline)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                if missingCount > 0 {
                    Text("\(missingCount)")
                        .font(AppTheme.Fonts.badge)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .frame(width: AppTheme.Spacing.badgeSize, height: AppTheme.Spacing.badgeSize)
                        .background(AppTheme.Colors.actionPrimary)
                        .clipShape(Circle())
                }
            }

            if assignments.isEmpty {
                Text("No assignments yet")
                    .font(AppTheme.Fonts.smallCaption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            } else {
                VStack(spacing: 4) {
                    ForEach(assignments) { assignment in
                        SwipeToDeleteRow(onDelete: { onDeleteAssignment(assignment) }) {
                            AssignmentRow(
                                assignment: assignment,
                                onToggle: { onToggleAssignment(assignment) }
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.cardInternal)
        .padding(.bottom, AppTheme.Spacing.cardInternal)
    }
}
