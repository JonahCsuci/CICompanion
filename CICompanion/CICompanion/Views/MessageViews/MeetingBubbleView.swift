//
//  MessageBubbleView.swift
//  CICompanion
//

import SwiftUI

struct ProposalHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct MeetingBubbleView: View {
    let message: Message
    let isCurrentUser: Bool
    let meetingScheduler: MeetingScheduler
    let sessionManager : SessionManager
    let messagingRepository : MessagingRepositoryProtocol
    let courseRepository : CourseRepositoryProtocol
    let conversation: Conversation
    let studentRepository : StudentRepositoryProtocol
    
    @State var navigationActiveA = false
    @State var navigationActiveB = false
    @State private var selectedProposalIndex = 0
    @State private var proposalHeight: CGFloat = 0
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer(minLength: 60) }
            
            VStack(spacing: ViewHelper.spacing) {
                CIText("\(meetingScheduler.title)", fontSize: 20, fontWeight: .semibold)
                
                if let startDate = meetingScheduler.daysAllowed.first {
                    if let endDate = meetingScheduler.daysAllowed.last {
                        CIText("Scheduling from \(DateHelper.dateToDayString(startDate, true)) to \(DateHelper.dateToDayString(endDate, true))")
                    }
                }
                
                if sessionManager.userId != nil && meetingScheduler.respondees.contains(sessionManager.userId!) {
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
                                CIText("Details", color: .black, fontWeight: .semibold)
                            }
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.white)
                        .cornerRadius(16)
                        
                        NavigationLink(destination: ProposeMeetingView(viewModel: ProposeMeetingViewModel(meetingScheduler: meetingScheduler, sessionManager: sessionManager, messagingRepository: messagingRepository), messageId: message.id, navigationActive: [$navigationActiveB], messagingRepository: messagingRepository, courseRepository: courseRepository), isActive: $navigationActiveB) {
                            HStack{
                                Image(systemName: "calendar")
                                CIText("Propose a time", color: .black, fontWeight: .semibold)
                            }
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.white)
                        .cornerRadius(16)
                    }
                    var proposals = Array(meetingScheduler.proposals).sorted(by: {return ($0.respondees.count > $1.respondees.count)})

                    if !proposals.isEmpty {
                        VStack(spacing: 10) {
                            GeometryReader { geo in
                                HStack(spacing: 0) {
                                    ForEach(proposals.indices, id: \.self) { index in
                                        MeetingProposalBubbleView(
                                            message: message,
                                            isCurrentUser: isCurrentUser,
                                            proposal: proposals[index],
                                            sessionManager: sessionManager,
                                            messagingRepository: messagingRepository,
                                            courseRepository: courseRepository,
                                            conversation: conversation,
                                            studentRepository: studentRepository,
                                            meetingScheduler: meetingScheduler,
                                            messageID: message.id
                                        )
                                            .frame(width: geo.size.width)
                                            .background(
                                                GeometryReader { innerGeo in
                                                    Color.clear
                                                        .preference(key: ProposalHeightKey.self, value: innerGeo.size.height)
                                                }
                                            )
                                    }
                                }
                                .offset(x: -CGFloat(selectedProposalIndex) * geo.size.width)
                                .animation(.easeInOut(duration: 0.25), value: selectedProposalIndex)
                            }
                            .frame(height: proposalHeight)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .onPreferenceChange(ProposalHeightKey.self) { height in
                                proposalHeight = height
                            }

                            if proposals.count > 1 {
                                HStack {
                                    Button {
                                        selectedProposalIndex = max(selectedProposalIndex - 1, 0)
                                    } label: {
                                        Image(systemName: "chevron.left.circle.fill")
                                            .font(.system(size: 26))
                                    }
                                    .disabled(selectedProposalIndex == 0)

                                    Text("\(selectedProposalIndex + 1) of \(proposals.count)")

                                    Button {
                                        selectedProposalIndex = min(selectedProposalIndex + 1, proposals.count - 1)
                                    } label: {
                                        Image(systemName: "chevron.right.circle.fill")
                                            .font(.system(size: 26))
                                    }
                                    .disabled(selectedProposalIndex == proposals.count - 1)
                                }
                            }
                        }
                    }
                } else {
                    NavigationLink(destination: AddAvailabilityView(viewModel: AddAvailabilityViewModel(meetingScheduler: meetingScheduler, sessionManager: sessionManager, messagingRepository: messagingRepository, courseRepository: courseRepository), messageId: message.id, navigationActive: [$navigationActiveA]), isActive: $navigationActiveA) {
                        HStack{
                            Image(systemName: "plus")
                            CIText("Add your availabilities", color: .black, fontWeight: .semibold)
                        }
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.white)
                    .cornerRadius(16)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isCurrentUser ? ViewHelper.currentUserColor : ViewHelper.otherUserColor)
            .cornerRadius(16)
            .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
            .onPreferenceChange(ProposalHeightKey.self) { height in
                proposalHeight = height
            }

             if !isCurrentUser { Spacer(minLength: 60) }
        }.id(meetingScheduler.id)
    }
}
