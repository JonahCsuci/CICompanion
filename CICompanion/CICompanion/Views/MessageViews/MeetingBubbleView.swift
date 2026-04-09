//
//  MessageBubbleView.swift
//  CICompanion
//

import SwiftUI

struct MeetingBubbleView: View {
    let message: Message
    let isCurrentUser: Bool
    let meetingScheduler: MeetingScheduler
    let sessionManager : SessionManager
    let messagingRepository : MessagingRepositoryProtocol
    
    init (
        message: Message,
        isCurrentUser: Bool,
        json: String,
        sessionManager : SessionManager,
        messagingRepository : MessagingRepositoryProtocol
    ) {
        self.message = message
        self.isCurrentUser = isCurrentUser
        do {
            try self.meetingScheduler = JSONDecoder().decode(MeetingScheduler.self, from: json.data(using: .utf8)!)
        } catch {
            self.meetingScheduler = MeetingScheduler(availableTimeRanges: [], daysAllowed: [], timeBlockMinutes: 0, startTime: 0, endTime: 0, conversationID: 0)
            exit(EXIT_FAILURE)
        }
        
        self.sessionManager = sessionManager
        self.messagingRepository = messagingRepository
    }

    private let currentUserColor = Color(red: 0.30, green: 0.50, blue: 0.85)
    private let otherUserColor = Color(red: 0.55, green: 0.25, blue: 0.85)

    var body: some View {
        HStack {
            if isCurrentUser { Spacer(minLength: 60) }

            NavigationLink(destination: AddAvailabilityView(viewModel: AddAvailabilityViewModel(meetingScheduler: meetingScheduler, sessionManager: sessionManager, messagingRepository: messagingRepository), messageId: message.id)) {
                VStack {
                    Text("Meeting Scheduler")
                        .font(.system(size: 20).weight(.semibold))
                    Text("Please click to add availability")
                    
                    if (meetingScheduler.bestTimes(studyRoomTimes: []).count <= 0) {
                        Text("No best times available")
                    } else {
                        Text("Best time: " + DateHelper.minutesToTimeString(meetingScheduler.bestTimes(studyRoomTimes: [])[0].startTime) + " to " + DateHelper.minutesToTimeString(meetingScheduler.bestTimes(studyRoomTimes: [])[0].endTime))
                        Text("People availabile: " + String(meetingScheduler.bestTimes(studyRoomTimes: [])[0].peopleAvailable))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isCurrentUser ? currentUserColor : otherUserColor)
                .cornerRadius(16)
            }

            if !isCurrentUser { Spacer(minLength: 60) }
        }
    }
}
