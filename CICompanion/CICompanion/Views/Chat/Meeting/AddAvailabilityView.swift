//
//  AddAvailabilityView.swift
//  CICompanion
//
//  Created by Emma on 3/29/26.
//

import SwiftUI

struct AddAvailabilityView: View {
    @StateObject private var viewModel: AddAvailabilityViewModel

    private let timeColumnWidth: CGFloat = 56
    private let dayColumnWidth: CGFloat = 92
    private let rowHeight: CGFloat = 44
    private let headerHeight: CGFloat = 58

    private let gridCornerRadius: CGFloat = 18
    private let cellCornerRadius: CGFloat = 8
    private let headerCornerRadius: CGFloat = 12
    private let buttonCornerRadiusMultiplier: CGFloat = 1.5

    private let headerDayNumberFontSize: CGFloat = 20
    private let headerDayNameFontSize: CGFloat = 12
    private let timeLabelFontSize: CGFloat = 11

    private let timeLabelYOffset: CGFloat = 14
    private let timeLabelTrailingPadding: CGFloat = 8

    private let headerHorizontalPadding: CGFloat = 6
    private let headerVerticalPadding: CGFloat = 6

    private let cellHorizontalInset: CGFloat = 5
    private let cellVerticalInset: CGFloat = 4
    private let cellWidthInset: CGFloat = 10
    private let cellHeightInset: CGFloat = 8

    private let gridLineWidth: CGFloat = 0.5
    private let borderLineWidth: CGFloat = 1
    private let dividerWidth: CGFloat = 0.5

    private let gridBackgroundColor: Color = ViewHelper.fieldBgColor

    private let gridLineOpacity: CGFloat = 0.08
    private let borderOpacity: CGFloat = 0.06
    private let timeLabelOpacity: CGFloat = 0.5
    private let headerDayNameOpacity: CGFloat = 0.7
    private let todayHeaderOpacity: CGFloat = 0.8
    private let selectedCellFillOpacity: CGFloat = 0.85
    private let selectedCellStrokeOpacity: CGFloat = 0.95
    private let unselectedCellFillOpacity: CGFloat = 0.5
    private let unselectedCellStrokeOpacity: CGFloat = 0.08
    private let blockedCellFillOpacity: CGFloat = 0.85
    private let blockedCellStrokeOpacity: CGFloat = 0.95

    private let selectedCellColor: Color = .green
    private let unselectedCellColor: Color = .red
    private let blockedCellColor: Color = .blue
    private let todayHeaderColor: Color = .blue
    private let gridLineColor: Color = .white
    private let backgroundBorderColor: Color = .white
    private let timeLabelColor: Color = .white
    private let headerTextColor: Color = .white

    @State private var dragVisited: Set<TimeRange.ID> = []
    @State private var dragMode: DragMode?

    private enum DragMode {
        case select
        case deselect
    }

    init(viewModel: AddAvailabilityViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var totalGridWidth: CGFloat {
        timeColumnWidth + CGFloat(viewModel.days.count) * dayColumnWidth
    }

    private var totalGridHeight: CGFloat {
        CGFloat(viewModel.timeSlots.count) * rowHeight
    }

    var body: some View {
        CIView() {
            CIPageTitle("Add your availabilities")

            Text("Swipe across the grid to add or remove time blocks.")
                .foregroundColor(ViewHelper.text)
                .lineLimit(2)

            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    dayHeaderRow()

                    ScrollView(.vertical, showsIndicators: false) {
                        ZStack(alignment: .topLeading) {
                            gridBackground()
                            selectionOverlay()
                        }
                        .frame(width: totalGridWidth, height: totalGridHeight)
                        .contentShape(Rectangle())
                        .coordinateSpace(name: "availability-grid")
                        .simultaneousGesture(gridDragGesture())
                    }
                }
                .frame(width: totalGridWidth)
                .background(
                    RoundedRectangle(cornerRadius: gridCornerRadius)
                        .fill(gridBackgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: gridCornerRadius)
                        .stroke(backgroundBorderColor.opacity(borderOpacity), lineWidth: borderLineWidth)
                )
            }

            Spacer()

            VStack {
                HStack {
                    Spacer()
                    NavigationLink {
                        LaunchLoadingView()
                    } label: {
                        Text("Update with your availabilities")
                            .font(.system(size: ViewHelper.textSize, weight: .bold))
                            .foregroundColor(ViewHelper.textImportant)
                            .padding(ViewHelper.padding * buttonCornerRadiusMultiplier)
                            .background(ViewHelper.accentBlue)
                            .cornerRadius(ViewHelper.componentRounding * buttonCornerRadiusMultiplier)
                    }
                    Spacer()
                }
            }
        }
    }

    private func dayHeaderRow() -> some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(width: timeColumnWidth, height: headerHeight)

            ForEach(viewModel.days.indices, id: \.self) { index in
                let date = viewModel.days[index]
                let isToday = Calendar.current.isDateInToday(date)

                VStack(spacing: 4) {
                    Text(dayNumber(for: date))
                        .font(.system(size: headerDayNumberFontSize, weight: .bold))
                        .foregroundColor(headerTextColor)

                    Text(shortDayName(for: date))
                        .font(.system(size: headerDayNameFontSize, weight: .medium))
                        .foregroundColor(headerTextColor.opacity(headerDayNameOpacity))
                }
                .frame(width: dayColumnWidth, height: headerHeight)
                .background(
                    RoundedRectangle(cornerRadius: headerCornerRadius)
                        .fill(isToday ? todayHeaderColor.opacity(todayHeaderOpacity) : Color.clear)
                        .padding(.horizontal, headerHorizontalPadding)
                        .padding(.vertical, headerVerticalPadding)
                )
            }
        }
    }

    private func gridBackground() -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(viewModel.timeSlots.indices, id: \.self) { row in
                let y = CGFloat(row) * rowHeight

                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: totalGridWidth, y: y))
                }
                .stroke(gridLineColor.opacity(gridLineOpacity), lineWidth: gridLineWidth)

                let slot = viewModel.timeSlots[row]
                Text(formatTime(slot))
                    .font(.system(size: timeLabelFontSize, weight: .medium))
                    .foregroundColor(timeLabelColor.opacity(timeLabelOpacity))
                    .frame(width: timeColumnWidth - timeLabelTrailingPadding, alignment: .trailing)
                    .position(x: timeColumnWidth / 2, y: y + timeLabelYOffset)
            }

            Path { path in
                path.move(to: CGPoint(x: 0, y: totalGridHeight))
                path.addLine(to: CGPoint(x: totalGridWidth, y: totalGridHeight))
            }
            .stroke(gridLineColor.opacity(gridLineOpacity), lineWidth: gridLineWidth)

            ForEach(0...viewModel.days.count, id: \.self) { col in
                let x = timeColumnWidth + CGFloat(col) * dayColumnWidth

                Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: totalGridHeight))
                }
                .stroke(gridLineColor.opacity(gridLineOpacity), lineWidth: gridLineWidth)
            }

            Rectangle()
                .fill(gridLineColor.opacity(gridLineOpacity))
                .frame(width: dividerWidth, height: totalGridHeight)
                .offset(x: timeColumnWidth)
        }
    }

    private func selectionOverlay() -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(viewModel.timeSlots.enumerated()), id: \.offset) { row, _ in
                ForEach(Array(viewModel.days.enumerated()), id: \.offset) { col, _ in
                    let range = viewModel.rangeFor(row: row, col: col)
                    let isCourse = viewModel.isCourse(range)
                    let isSelected = viewModel.isSelected(range)

                    RoundedRectangle(cornerRadius: cellCornerRadius)
                        .fill(cellFillColor(isCourse: isCourse, isSelected: isSelected))
                        .overlay(
                            RoundedRectangle(cornerRadius: cellCornerRadius)
                                .stroke(
                                    cellStrokeColor(isBlocked: isCourse, isSelected: isSelected),
                                    lineWidth: borderLineWidth
                                )
                        )
                        .frame(width: dayColumnWidth - cellWidthInset, height: rowHeight - cellHeightInset)
                        .offset(
                            x: timeColumnWidth + CGFloat(col) * dayColumnWidth + cellHorizontalInset,
                            y: CGFloat(row) * rowHeight + cellVerticalInset
                        )
                }
            }
        }
    }

    private func cellFillColor(isCourse: Bool, isSelected: Bool) -> Color {
        if isSelected {
            return selectedCellColor.opacity(selectedCellFillOpacity)
        }
        if isCourse {
            return blockedCellColor.opacity(blockedCellFillOpacity)
        }
        return unselectedCellColor.opacity(unselectedCellFillOpacity)
    }

    private func cellStrokeColor(isBlocked: Bool, isSelected: Bool) -> Color {
        if isBlocked {
            return blockedCellColor.opacity(blockedCellStrokeOpacity)
        }
        if isSelected {
            return selectedCellColor.opacity(selectedCellStrokeOpacity)
        }
        return gridLineColor.opacity(unselectedCellStrokeOpacity)
    }

    private func gridDragGesture() -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("availability-grid"))
            .onChanged { value in
                guard let cell = cellAt(location: value.location) else { return }
                let range = viewModel.rangeFor(row: cell.row, col: cell.col)

                if dragMode == nil {
                    dragMode = viewModel.isSelected(range) ? .deselect : .select
                }

                guard !dragVisited.contains(range.id) else { return }
                dragVisited.insert(range.id)

                switch dragMode {
                case .select:
                    viewModel.setSelected(range, isSelected: true)
                case .deselect:
                    viewModel.setSelected(range, isSelected: false)
                case .none:
                    break
                }
            }
            .onEnded { _ in
                dragVisited.removeAll()
                dragMode = nil
            }
    }

    private func cellAt(location: CGPoint) -> (row: Int, col: Int)? {
        guard location.x >= timeColumnWidth else { return nil }
        guard location.y >= 0 else { return nil }

        let col = Int((location.x - timeColumnWidth) / dayColumnWidth)
        let row = Int(location.y / rowHeight)

        guard viewModel.days.indices.contains(col) else { return nil }
        guard viewModel.timeSlots.indices.contains(row) else { return nil }

        return (row, col)
    }

    private func shortDayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func dayNumber(for date: Date) -> String {
        String(Calendar.current.component(.day, from: date))
    }

    private func formatTime(_ minutes: Int) -> String {
        let hour24 = minutes / 60
        let minute = minutes % 60
        let isPM = hour24 >= 12
        let hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24)
        return String(format: "%d:%02d %@", hour12, minute, isPM ? "PM" : "AM")
    }
}

#Preview {
    AddAvailabilityView(
        viewModel: AddAvailabilityViewModel(
            days: [
                Date(),
                Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
                Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
                Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
                Calendar.current.date(byAdding: .day, value: 4, to: Date())!
            ],
            timeBlockSize: 60,
            startTime: 480,
            endTime: 1200,
            courses: [
                Course(
                    id: 12,
                    courseName: "Course Name",
                    courseCode: "MATH 101",
                    instructor: "Dr. Loran",
                    location: "Bell Tower",
                    startTime: "12:00PM",
                    endTime: "3:00PM",
                    days: ["Monday", "Tuesday", "Wednesday"],
                    isAsynchronous: false,
                    courseDescription: "Incredible course description"
                ),
                Course(
                    id: 12,
                    courseName: "Course Name",
                    courseCode: "MATH 101",
                    instructor: "Dr. Loran",
                    location: "Bell Tower",
                    startTime: "9:00AM",
                    endTime: "11:00AM",
                    days: ["Tuesday", "Friday"],
                    isAsynchronous: false,
                    courseDescription: "Incredible course description"
                )
            ]
        )
    )
}
