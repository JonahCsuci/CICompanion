//
//  AddAvailabilityView.swift
//  CICompanion
//
//  Created by Emma on 4/8/26.
//

import SwiftUI

struct AddAvailabilityView: View {
    @StateObject private var viewModel: AddAvailabilityViewModel
    @State private var edit = false
    
    init (
        viewModel: AddAvailabilityViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel);
    }
    
    var rowHeight: CGFloat = 50
    var columnWidth: CGFloat = 50
    
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
    
    var body : some View {
        ZStack {
            CIView {
                CIPageTitle("Share your availabilities")
                CIText("Swipe to add or remove availabilities.", ViewHelper.accentBlue)
                
                ScrollView([.vertical, .horizontal]) {
                    HStack {
                        VStack {
                            Spacer()
                                .frame(minHeight: rowHeight)
                            
                            ForEach(Array(stride(from: viewModel.meetingScheduler.startTime, to: viewModel.meetingScheduler.endTime, by: viewModel.meetingScheduler.timeBlockMinutes)), id: \.self) { time in
                                
                                VStack {
                                    Text(DateHelper.minutesToTimeString(time))
                                        .foregroundColor(ViewHelper.text)
                                        
                                }.frame(minHeight: rowHeight)
                            }
                            Spacer()
                        }
                        ForEach(viewModel.meetingScheduler.daysAllowed.indices) {dayI in
                            VStack {
                                dateHeader(date: viewModel.meetingScheduler.daysAllowed[dayI])
                                
                                ForEach(viewModel.meetingScheduler.timeRangesForDay(date: viewModel.meetingScheduler.daysAllowed[dayI])) {range in
                                    
                                }
                                
                                Spacer()
                            }
                            .frame(minWidth: columnWidth)
                            Spacer()
                        }
                    }
                }.padding(ViewHelper.padding)
            }
            
            HStack() {
                Spacer()
                VStack() {
                    Spacer()
                    if (!edit) {
                        Button {
                            edit = true
                        } label: {
                            HStack {
                                Image(systemName: "pencil")
                                    .font(.system(size: ViewHelper.textSize))
                                
                                CIText("Edit Mode", ViewHelper.textImportant)
                            }
                            .foregroundColor(ViewHelper.textImportant)
                            .padding(ViewHelper.padding)
                            .background(ViewHelper.accentBlue)
                            .cornerRadius(32)
                            .padding(.bottom, ViewHelper.padding)
                            .padding(.trailing, ViewHelper.padding * 2)
                        }
                    } else {
                        Button {
                            edit = false
                        } label: {
                            HStack {
                                Image(systemName: "eye")
                                    .font(.system(size: ViewHelper.textSize))
                                
                                CIText("View Availabilities", ViewHelper.textImportant)
                            }
                            .foregroundColor(ViewHelper.textImportant)
                            .padding(ViewHelper.padding)
                            .background(ViewHelper.accentBlue)
                            .cornerRadius(32)
                            .padding(.bottom, ViewHelper.padding)
                            .padding(.trailing, ViewHelper.padding * 2)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    AddAvailabilityView(
        viewModel: AddAvailabilityViewModel(
            meetingScheduler: MeetingScheduler(
                daysAllowed: [
                    Date(),
                    Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
                    Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
                    Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
                    Calendar.current.date(byAdding: .day, value: 4, to: Date())!,
                    Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
                    Calendar.current.date(byAdding: .day, value: 6, to: Date())!,
                    Calendar.current.date(byAdding: .day, value: 7, to: Date())!
                ],
                timeBlockMinutes: 60,
                id: UUID(),
                startTime: 480,
                endTime: 1200
            ),
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
