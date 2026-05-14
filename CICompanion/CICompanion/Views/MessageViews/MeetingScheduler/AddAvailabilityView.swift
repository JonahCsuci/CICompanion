//
//  AddAvailabilityView.swift
//  CICompanion
//
//  Created by Emma on 4/8/26.
//

import SwiftUI

struct AddAvailabilityView: View {
    @Environment(\.dismiss) var dismiss 

    @StateObject private var viewModel: AddAvailabilityViewModel
    @State private var selectedBlocks: Set<TimeBlock> = []
    var navigationsActive: [Binding<Bool>]

    var messageId : Int
    
    init (
        viewModel: AddAvailabilityViewModel,
        messageId: Int,
        navigationActive: [Binding<Bool>]
    ) {
        _viewModel = StateObject(wrappedValue: viewModel);
        self.messageId = messageId
        self.navigationsActive = navigationActive
    }
    
    var rowHeight: CGFloat = 50
    var columnWidth: CGFloat = 50
    
    func timeRanges() -> [Int] {
        Array(stride(
            from: viewModel.meetingScheduler.startTime,
            to: viewModel.meetingScheduler.endTime,
            by: viewModel.meetingScheduler.timeBlockMinutes
        ))
    }
    
    func dateHeader(date: Date) -> some View {
        let calendar = Calendar.current
        
        let day = calendar.component(.day, from: date)
        let dayName = date.formatted(.dateTime.weekday(.abbreviated))
        let isToday = calendar.isDateInToday(date)
        
        return VStack(spacing: 2) {
            Text("\(day)")
                .font(.system(size: ViewHelper.smallTextSize * 1.5, weight: .bold))
                .foregroundColor(isToday ? ViewHelper.textImportant : ViewHelper.text)
            
            Text(dayName)
                .font(.system(size: ViewHelper.smallTextSize, weight: .medium))
                .foregroundColor(isToday ? ViewHelper.textImportant.opacity(0.85) : ViewHelper.text)
        }
        .frame(maxWidth: .infinity, minHeight: rowHeight)
        .background(
            Group {
                if isToday {
                    RoundedRectangle(cornerRadius: ViewHelper.componentRounding)
                        .fill(ViewHelper.accentBlue)
                }
            }
        )
    }
    

    func grid() -> some View {
        let ranges = timeRanges()
        
        return HStack {
            VStack() {
                Spacer()
                    .frame(minHeight: rowHeight + ViewHelper.padding)
                
                ForEach(ranges, id: \.self) { time in
                    VStack {
                        Text(DateHelper.minutesToTimeString(time))
                            .foregroundColor(ViewHelper.text)
                    }
                    .frame(minHeight: rowHeight)
                }
            }
            
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(viewModel.meetingScheduler.daysAllowed.enumerated()), id: \.offset) { dayI, day in
                    let dayName = day.formatted(.dateTime.weekday(.wide))
                    
                    VStack(spacing: ViewHelper.spacing) {
                        dateHeader(date: day)
                        
                        ForEach(ranges, id: \.self) { range in
                            let block = TimeBlock(
                                day: day,
                                range: TimeRange(
                                    startTime: range,
                                    endTime: range + viewModel.meetingScheduler.timeBlockMinutes,
                                    day: day
                                )
                            )
                            
                            let blockedByCourse = viewModel.courses.first {
                                $0.days.contains(dayName) &&
                                (DateHelper.timeStringToMinutes($0.startTime) ?? 0) < range + viewModel.meetingScheduler.timeBlockMinutes &&
                                (DateHelper.timeStringToMinutes($0.endTime) ?? 0) > range
                            }
                            
                            if let _ = blockedByCourse {
                                Button {
                                    if selectedBlocks.contains(block) {
                                        selectedBlocks.remove(block)
                                    } else {
                                        selectedBlocks.insert(block)
                                    }
                                } label: {
                                    VStack {}
                                        .frame(minWidth: columnWidth, minHeight: rowHeight)
                                        .background(
                                            selectedBlocks.contains(block)
                                                ? ViewHelper.accentBlue
                                                : ViewHelper.accentBlue.opacity(0.4)
                                        )
                                        .cornerRadius(ViewHelper.componentRounding)
                                }
                            } else {
                                Button {
                                    if selectedBlocks.contains(block) {
                                        selectedBlocks.remove(block)
                                    } else {
                                        selectedBlocks.insert(block)
                                    }
                                } label: {
                                    VStack {}
                                        .frame(minWidth: columnWidth, minHeight: rowHeight)
                                        .background(selectedBlocks.contains(block) ? ViewHelper.accentGreen : ViewHelper.fieldBgColor)
                                        .cornerRadius(ViewHelper.componentRounding)
                                }.task {
                                    selectedBlocks.insert(block)
                                }
                            }
                        }
                    }
                    .frame(minWidth: columnWidth)
                    
                    Spacer()
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            CIView {
                HStack(alignment: .top) {
                    CIPageTitle("Share your availabilities")
                    Spacer()
                    legend
                }
                
                CIText("Tap to add or remove availabilities.", color: ViewHelper.accentBlue)
                
                ScrollView([.vertical, .horizontal]) {
                    grid()
                }
                .padding(ViewHelper.padding)
                .background(.black.opacity(ViewHelper.opacity))
                .cornerRadius(ViewHelper.componentRounding)
                
                Spacer()
            }
            
            VStack {
                Spacer()
                HStack {
                    Button {
                        viewModel.send(ranges: selectedBlocks, messageId: messageId)
                        for nav in navigationsActive {
                            nav.wrappedValue = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark")
                                .font(.system(size: ViewHelper.textSize).weight(.bold))
                            CIText("Submit")
                        }
                        .foregroundColor(ViewHelper.textImportant)
                        .padding(ViewHelper.padding * 1.5)
                        .background(ViewHelper.accentBlue)
                        .cornerRadius(ViewHelper.componentRounding * 2)
                        .padding(.trailing, ViewHelper.padding * 2)
                    }
                }
            }
        }
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: ViewHelper.tinyPadding) {
            legendRow(color: ViewHelper.accentGreen, label: "Available")
            legendRow(color: ViewHelper.accentBlue.opacity(0.4), label: "In class")
        }
        .padding(ViewHelper.smallPadding)
        .background(.black.opacity(ViewHelper.opacity))
        .cornerRadius(ViewHelper.componentRounding)
    }

    private func legendRow(color: Color, label: String) -> some View {
        HStack(spacing: ViewHelper.tinyPadding) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: ViewHelper.iconSize, height: ViewHelper.iconSize)
            CIText(label, fontSize: ViewHelper.smallTextSize)
        }
    }
}
