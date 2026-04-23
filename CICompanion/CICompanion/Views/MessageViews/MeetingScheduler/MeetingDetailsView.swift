//
//  MeetingDetailsView.swift
//  CICompanion
//
//  Created by Emma on 4/16/26.
//

import SwiftUI

struct MeetingDetailsView: View {
    @Environment(\.dismiss) var dismiss
    
    var navigationsActive: [Binding<Bool>]
    var messageId: Int
    var meetingScheduler: MeetingScheduler
    var sessionManager: SessionManager
    var messagingRepository: MessagingRepositoryProtocol
    var conversation: Conversation
    
    var respondeesString: String
    var nonRespondeesString: String
    
    init(
        navigationsActive: [Binding<Bool>],
        messageId: Int,
        meetingScheduler: MeetingScheduler,
        sessionManager: SessionManager,
        messagingRepository: MessagingRepositoryProtocol,
        conversation: Conversation
    ) {
        self.navigationsActive = navigationsActive
        self.messageId = messageId
        self.meetingScheduler = meetingScheduler
        self.sessionManager = sessionManager
        self.messagingRepository = messagingRepository
        self.conversation = conversation
        
        respondeesString = ""
        nonRespondeesString = ""
        if conversation.participants != nil {
            var i = 0
            for participant in conversation.participants! {
                if meetingScheduler.respondees.contains(participant.id) {
                    if i != 0 && conversation.participants!.count > 1 {
                        if (i + 1) == conversation.participants!.count {
                            respondeesString.append(" and ")
                        } else {
                            respondeesString.append(", ")
                        }
                    }
                    respondeesString.append(participant.name)
                    i += 1
                } else {
                    if i != 0 && conversation.participants!.count > 1 {
                        respondeesString.append(", ")
                    }
                    respondeesString.append(participant.name)
                    i += 1
                }
            }
        }
    }
    
    var body: some View {
        CIView {
            CIPageTitle("\(meetingScheduler.title) Details")
            
            if respondeesString != "" {
                Text(respondeesString + " responded with their availabilities.")
                    .foregroundColor(ViewHelper.textImportant)
            }
            
            if nonRespondeesString != "" {
                Text(nonRespondeesString + " have not responded yet.")
                    .foregroundColor(ViewHelper.accentRed)
            }
            
            Spacer()
        
            ScrollView([.vertical, .horizontal]) {
                heatmapGrid()
            }
            .padding(ViewHelper.padding)
            .background(.black.opacity(ViewHelper.opacity))
            .cornerRadius(ViewHelper.componentRounding)
            
            Spacer()
        }
    }

    func timeRanges() -> [Int] {
        Array(stride(
            from: meetingScheduler.startTime,
            to: meetingScheduler.endTime,
            by: meetingScheduler.timeBlockMinutes
        ))
    }

    func heatAvailability(day: Date, range: Int) -> Double {
        let slotEnd = range + meetingScheduler.timeBlockMinutes
        let respondeeCount = meetingScheduler.respondees.count
        if (respondeeCount <= 0) { return 0 }
        
        let available = meetingScheduler.availableTimeRanges.filter {
            Calendar.current.isDate($0.day, inSameDayAs: day) &&
            $0.startTime <= range &&
            $0.endTime >= slotEnd
        }
        
        let uniquePeople = available.reduce(into: Set<String>()) { $0.formUnion($1.peopleAvailable) }
        return Double(uniquePeople.count) / Double(respondeeCount)
    }

    func heatmapGrid() -> some View {
        let ranges = timeRanges()
        let rowHeight: CGFloat = 50
        let columnWidth: CGFloat = 50

        return HStack {
            VStack {
                Spacer().frame(minHeight: rowHeight + ViewHelper.padding)
                ForEach(ranges, id: \.self) { time in
                    VStack {
                        Text(DateHelper.minutesToTimeString(time))
                            .foregroundColor(ViewHelper.text)
                    }
                    .frame(minHeight: rowHeight)
                }
            }

            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(meetingScheduler.daysAllowed.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: ViewHelper.spacing) {
                        dateHeader(date: day, rowHeight: rowHeight)

                        ForEach(ranges, id: \.self) { range in
                            let heat = heatAvailability(day: day, range: range)

                            VStack {}
                                .frame(minWidth: columnWidth, minHeight: rowHeight)
                                .background(
                                    ZStack {
                                        ViewHelper.fieldBgColor
                                        ViewHelper.accentBigGreen.opacity(heat)
                                    }
                                )
                                .cornerRadius(ViewHelper.componentRounding)
                        }
                    }
                    .frame(minWidth: columnWidth)

                    Spacer()
                }
            }
        }
    }

    func dateHeader(date: Date, rowHeight: CGFloat) -> some View {
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
}
