//
//  AsyncCoursesSectionView.swift
//  CICompanion
//

import SwiftUI

struct AsyncCoursesSectionView: View {
    let courses: [AsyncCourseItem]
    var title = "Asynchronous Courses"
    @Binding var assignments: [String: [Assignment]]
    var onAddAssignment: ((AsyncCourseItem) -> Void)? = nil
    @State private var expandedCourseID: Int?

    init(
        courses: [AsyncCourseItem],
        title: String = "Asynchronous Courses",
        assignments: Binding<[String: [Assignment]]> = .constant([:]),
        onAddAssignment: ((AsyncCourseItem) -> Void)? = nil
    ) {
        self.courses = courses
        self.title = title
        self._assignments = assignments
        self.onAddAssignment = onAddAssignment
    }

    var body: some View {
        if !courses.isEmpty {
            VStack(alignment: .leading, spacing: ViewHelper.spacing) {
                Text(title)
                    .font(.system(size: ViewHelper.textSize, weight: .semibold))
                    .foregroundColor(ViewHelper.textImportant)

                LazyVStack(spacing: ViewHelper.spacing) {
                    ForEach(courses) { course in
                        asyncCourseRow(course)
                    }
                }
            }
            .padding(ViewHelper.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ViewHelper.fieldBgColor)
            .cornerRadius(ViewHelper.componentRounding)
        }
    }

    private func asyncCourseRow(_ course: AsyncCourseItem) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: ViewHelper.spacing) {
                Image(systemName: expandedCourseID == course.id ? "chevron.down" : "chevron.right")
                    .font(.system(size: ViewHelper.iconSize, weight: .semibold))
                    .foregroundColor(ViewHelper.text)
                    .frame(width: 16)
                    .padding(.top, 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(ViewHelper.accentGreen)
                    .frame(width: 3, height: 42)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(course.courseCode) - \(course.courseName)")
                        .font(.system(size: ViewHelper.smallTextSize + 2, weight: .bold))
                        .foregroundColor(ViewHelper.textImportant)
                        .lineLimit(2)

                    Text(course.location)
                        .font(.system(size: ViewHelper.smallTextSize))
                        .foregroundColor(ViewHelper.text)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(ViewHelper.smallPadding)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedCourseID = expandedCourseID == course.id ? nil : course.id
                }
            }

            if expandedCourseID == course.id {
                Divider()
                    .background(ViewHelper.text.opacity(0.2))

                asyncAssignments(for: course)
                    .padding(.horizontal, ViewHelper.padding)
                    .padding(.top, ViewHelper.padding)

                Divider()
                    .background(ViewHelper.text.opacity(0.2))
                    .padding(.top, ViewHelper.smallPadding)

                CourseDetailsDropDown(course: course.course)
                    .padding(ViewHelper.padding)
            }
        }
        .background(ViewHelper.cardBgColor.opacity(0.55))
        .cornerRadius(ViewHelper.componentRounding)
    }

    private func asyncAssignments(for course: AsyncCourseItem) -> some View {
        let assignmentKey = Self.assignmentKey(for: course)
        let courseAssignments = assignments[assignmentKey] ?? []
        let pendingCount = courseAssignments.filter { !$0.isCompleted }.count

        return VStack(alignment: .leading, spacing: ViewHelper.spacing) {
            HStack(spacing: ViewHelper.smallPadding) {
                Text("Assignments")
                    .font(.system(size: ViewHelper.smallTextSize + 2, weight: .semibold))
                    .foregroundColor(ViewHelper.textImportant)

                if pendingCount > 0 {
                    Text("\(pendingCount)")
                        .font(.system(size: ViewHelper.smallTextSize - 2, weight: .bold))
                        .foregroundColor(ViewHelper.textImportant)
                        .frame(width: 18, height: 18)
                        .background(ViewHelper.accentBlue)
                        .clipShape(Circle())
                }

                Spacer()

                if let onAddAssignment {
                    Button {
                        onAddAssignment(course)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: ViewHelper.navIconSize, weight: .semibold))
                            .foregroundColor(ViewHelper.accentBlue)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add assignment")
                }
            }

            if courseAssignments.isEmpty {
                Text("No assignments yet")
                    .font(.system(size: ViewHelper.smallTextSize))
                    .foregroundColor(ViewHelper.text)
            } else {
                VStack(spacing: ViewHelper.tinyPadding) {
                    ForEach(courseAssignments) { assignment in
                        asyncAssignmentRow(assignment, assignmentKey: assignmentKey)
                    }
                }
            }
        }
    }

    private func asyncAssignmentRow(_ assignment: Assignment, assignmentKey: String) -> some View {
        HStack(spacing: ViewHelper.spacing) {
            Button {
                toggleAssignment(assignment, assignmentKey: assignmentKey)
            } label: {
                Image(systemName: assignment.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.system(size: ViewHelper.bigIconSize))
                    .foregroundColor(assignment.isCompleted ? ViewHelper.accentBigGreen : ViewHelper.text)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(assignment.title)
                        .font(.system(size: ViewHelper.smallTextSize + 1, weight: .medium))
                        .foregroundColor(assignment.isPriority && !assignment.isCompleted ? ViewHelper.accentOrange : ViewHelper.textImportant)
                        .strikethrough(assignment.isCompleted)

                    if assignment.isPriority && !assignment.isCompleted {
                        Image(systemName: "star.fill")
                            .font(.system(size: ViewHelper.smallTextSize - 2))
                            .foregroundColor(ViewHelper.accentOrange)
                    }
                }

                if !assignment.details.isEmpty {
                    Text(assignment.details)
                        .font(.system(size: ViewHelper.smallTextSize))
                        .foregroundColor(ViewHelper.text)
                        .lineLimit(2)
                }
            }

            Spacer()

            Button {
                deleteAssignment(assignment, assignmentKey: assignmentKey)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: ViewHelper.navIconSize, weight: .semibold))
                    .foregroundColor(ViewHelper.accentRed)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete assignment")
        }
        .padding(.vertical, ViewHelper.tinyPadding)
    }

    private func toggleAssignment(_ assignment: Assignment, assignmentKey: String) {
        guard var updated = assignments[assignmentKey],
              let index = updated.firstIndex(where: { $0.id == assignment.id }) else {
            return
        }

        updated[index].isCompleted.toggle()
        assignments[assignmentKey] = updated
    }

    private func deleteAssignment(_ assignment: Assignment, assignmentKey: String) {
        guard var updated = assignments[assignmentKey] else { return }
        updated.removeAll { $0.id == assignment.id }
        assignments[assignmentKey] = updated
    }

    static func assignmentKey(for course: AsyncCourseItem) -> String {
        "async-\(course.id)"
    }
}
