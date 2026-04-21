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
    let courseRepository : CourseRepositoryProtocol
    let conversation: Conversation
    
    @State var navigationActiveA = false
    @State var navigationActiveB = false

    var alreadyResponded: some View {
        VStack {
            Divider()
                .background(ViewHelper.textImportant)
            CIText("You have responded already")
            HStack {
                NavigationLink(
                    destination: MeetingDetailsView(
                        navigationsActive: [$navigationActiveA],
                        messageId: message.id,
                        meetingScheduler: meetingScheduler,
                        sessionManager: sessionManager,
                        messagingRepository: messagingRepository,
                        conversation: conversation
                    ),
                    isActive: $navigationActiveA
                ) {
                    HStack{
                        Image(systemName: "text.page")
                        CIText("Details", fontWeight: .semibold)
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(ViewHelper.cardBgColor)
                .cornerRadius(16)
                NavigationLink(destination: ProposeMeetingView(viewModel: ProposeMeetingViewModel(meetingScheduler: meetingScheduler, sessionManager: sessionManager, messagingRepository: messagingRepository), messageId: message.id, navigationActive: [$navigationActiveB], messagingRepository: messagingRepository, courseRepository: courseRepository), isActive: $navigationActiveB) {
                    HStack{
                        Image(systemName: "calendar")
                        CIText("Propose a time", fontWeight: .semibold)
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(ViewHelper.cardBgColor)
                .cornerRadius(16)
            }
        }
    }
    
    var noResponse: some View {
        NavigationLink(destination: AddAvailabilityView(viewModel: AddAvailabilityViewModel(meetingScheduler: meetingScheduler, sessionManager: sessionManager, messagingRepository: messagingRepository, courseRepository: courseRepository), messageId: message.id, navigationActive: [$navigationActiveA]), isActive: $navigationActiveA) {
            HStack{
                Image(systemName: "plus")
                CIText("Add your availabilities", fontWeight: .semibold)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(ViewHelper.cardBgColor)
        .cornerRadius(16)
    }
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer(minLength: 60) }
            
            VStack {
                CIText("\(meetingScheduler.title)", fontSize: 20, fontWeight: .semibold)
                
                if let startDate = meetingScheduler.daysAllowed.first {
                    if let endDate = meetingScheduler.daysAllowed.last {
                        CIText("Scheduling from \(DateHelper.dateToDayString(startDate, true)) to \(DateHelper.dateToDayString(endDate, true))")
                    }
                }
                
                if sessionManager.userId != nil && meetingScheduler.respondees.contains(sessionManager.userId!) {
                    alreadyResponded
                } else {
                    noResponse
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isCurrentUser ? ViewHelper.currentUserColor : ViewHelper.otherUserColor)
            .cornerRadius(16)

             if !isCurrentUser { Spacer(minLength: 60) }
        }.id(meetingScheduler.id)
    }
}
