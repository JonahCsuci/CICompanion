//
//  AddAvailabilityView.swift
//  CICompanion
//
//  Created by Emma on 4/8/26.
//

import SwiftUI

struct AddAvailabilityView: View {
    @StateObject private var viewModel: AddAvailabilityViewModel
    @State private var selectedBlocks: Set<TimeBlock> = []

    var newMeeting : Bool
    
    init (
        viewModel: AddAvailabilityViewModel,
        newMeeting: Bool
    ) {
        _viewModel = StateObject(wrappedValue: viewModel);
        self.newMeeting = newMeeting
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
    

    func grid() -> some View{
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
                    VStack(spacing: ViewHelper.spacing) {
                        dateHeader(date: day)
                        
                        ForEach(ranges, id: \.self) { range in
                            let block = TimeBlock(
                                day: day,
                                range: TimeRange(
                                    startTime: range,
                                    endTime: range + viewModel.meetingScheduler.timeBlockMinutes,
                                    userID: viewModel.sessionManager.userId ?? "",
                                    day: day
                                )
                            )
                            
                            Button {
                                print("hi")
                                if (selectedBlocks.contains(block)) {
                                    selectedBlocks.remove(block)
                                } else {
                                    selectedBlocks.insert(block)
                                }
                            } label: {
                                VStack {}
                                    .frame(minWidth: columnWidth, minHeight: rowHeight)
                                    .background(selectedBlocks.contains(block) ? ViewHelper.accentGreen : ViewHelper.fieldBgColor)
                                    .cornerRadius(ViewHelper.componentRounding)
                            }
                        }
                    }
                    .frame(minWidth: columnWidth)
                    
                    Spacer()
                }
            }
        }
    }
    
    var body : some View {
        ZStack {
            CIView {
                CIPageTitle("Share your availabilities")
                CIText("Swipe to add or remove availabilities.", ViewHelper.accentBlue)
                
                ScrollView([.vertical, .horizontal]) {
                    grid()
                }.padding(ViewHelper.padding).background(.black.opacity(0.1))
                    .cornerRadius(ViewHelper.componentRounding)
                
                Spacer()
            }
            
            VStack {
                Spacer()
                HStack() {
                    Button {
                        viewModel.send(ranges: selectedBlocks, isNew: newMeeting)
                    } label: {
                        HStack {
                            Image(systemName: "checkmark")
                                .font(.system(size: ViewHelper.textSize).weight(.bold))
                            
                            Text("Submit")
                                .foregroundColor(ViewHelper.textImportant)
                                .font(.system(size: ViewHelper.textSize * 1.25))
                        }
                        .foregroundColor(ViewHelper.textImportant)
                        .padding(ViewHelper.padding * 1.5)
                        .background(ViewHelper.accentBlue)
                        .cornerRadius(32)
                        .padding(.trailing, ViewHelper.padding * 2)
                    }
                }
            }
        }
    }
}
