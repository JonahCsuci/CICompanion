//
//  MeetingProposalBubbleView.swift
//  CICompanion
//
//  Created by Emma on 4/17/26.
//

import SwiftUI

struct MeetingProposalBubbleView: View {
    let message: Message
    let isCurrentUser: Bool
    let proposal: MeetingProposal
    let sessionManager : SessionManager
    let messagingRepository : MessagingRepositoryProtocol
    let courseRepository : CourseRepositoryProtocol
    let conversation : Conversation
    
    @State var navigationActive = false
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer(minLength: 60) }
            
            VStack {
                CIText("\(proposal.title)", fontSize: 20, fontWeight: .semibold)
                
                let date = proposal.timeRange.day
                
                HStack(spacing: 0) {
                    CIText("[Proposed] ", color: ViewHelper.textImportant.opacity(0.75))
                    CIText("\(DateHelper.dateToDayString(date, true)) · \(DateHelper.minutesToTimeString(proposal.timeRange.startTime))-\(DateHelper.minutesToTimeString(proposal.timeRange.endTime))")
                }
                
                CIText("\(proposal.respondees.count)/\(conversation.participants != nil ? conversation.participants!.count : 2) people added to calendar", color: ViewHelper.textImportant.opacity(0.75))
                
                
                if sessionManager.userId != nil && proposal.respondees.contains(sessionManager.userId!) {
                    
                } else {
                    HStack(spacing: 12) {
                        Button {
                            
                        } label: {
                            Spacer()
                            Image(systemName: "calendar").font(.system(size: ViewHelper.textSize, weight: .semibold))
                            CIText("Add to calendar")
                            Spacer()
                        }
                        .padding(10).background(ViewHelper.cardBgColor)
                        .cornerRadius(16)
                    }.padding(10)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isCurrentUser ? ViewHelper.currentUserColor : ViewHelper.otherUserColor)
            .cornerRadius(16)

            if !isCurrentUser { Spacer(minLength: 60) }
        }
    }
}
