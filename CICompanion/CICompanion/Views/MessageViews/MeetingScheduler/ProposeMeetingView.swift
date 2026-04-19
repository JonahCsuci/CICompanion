//
//  ProposeMeetingView.swift
//  CICompanion
//
//  Created by Emma on 4/16/26.
//

import SwiftUI

struct ProposeMeetingView: View {
    @Environment(\.dismiss) var dismiss

    @StateObject private var viewModel: ProposeMeetingViewModel
    
    var navigationsActive: [Binding<Bool>]

    var messageId : Int
    
    var meet: MeetingScheduler
    
    @State var bestTimes: [MeetingProposal] = []
    
    var messagingRepository: MessagingRepositoryProtocol
    
    init (
        viewModel: ProposeMeetingViewModel,
        messageId: Int,
        navigationActive: [Binding<Bool>],
        messagingRepository: MessagingRepositoryProtocol
    ) {
        _viewModel = StateObject(wrappedValue: viewModel);
        self.messageId = messageId
        self.navigationsActive = navigationActive
        self.meet = viewModel.meetingScheduler
        self.messagingRepository = messagingRepository
    }
    
    var body: some View {
        CIView {
            CIText(meet.title, fontSize: ViewHelper.titleTextSize, fontWeight: .bold)
            
            if bestTimes.isEmpty {
                CIText("No meeting times available")
                    .padding(ViewHelper.padding)
            } else {
                TabView {
                    ForEach(bestTimes, id: \.self) { time in
                        card(time)
                    }
                }
                .tabViewStyle(.page)
                .padding(ViewHelper.padding)
            }
        }
        .task {
            await loadBestTimes()
        }
    }

    func loadBestTimes() async {
        guard let startDay = meet.daysAllowed.first,
              let endDay = meet.daysAllowed.last else {
            bestTimes = []
            return
        }

        do {
            let studyRooms = try await messagingRepository.fetchStudyRooms(
                start: startDay,
                end: endDay
            )
            bestTimes = meet.bestTimes(studyRooms: studyRooms)
        } catch {
            print("Error loading study rooms: \(error)")
            bestTimes = meet.bestTimes(studyRooms: [:])
        }
    }

    
    func card(_ proposal: MeetingProposal) -> some View {
        var time = proposal.timeRange
        
        return HStack {
            Spacer()
            VStack {
                CIText(DateHelper.dateToDayString(time.day), fontSize: ViewHelper.textSize * 2, fontWeight: .bold)
                CIText("\(DateHelper.minutesToTimeString(time.startTime)) - \(DateHelper.minutesToTimeString(time.endTime))", fontSize: ViewHelper.textSize * 1.5, fontWeight: .semibold)
                
                // Access course information to show where this fits in in the schedule!
                
                CIText("\(proposal.studyRoomID != nil ? "Study room available: \(proposal.studyRoom())" : "Study room not available")")
                
                CIText("\(time.peopleAvailable.count) / \(meet.respondees.count) \((time.peopleAvailable.count == 1) ? "person" : "people") available")
                
                Button {
                    viewModel.proposeMeeting(prop: proposal)
                } label: {
                    HStack {
                        Image(systemName: "calendar").font(.system(size: ViewHelper.textSize, weight: .bold))
                            .foregroundColor(ViewHelper.textImportant)
                        CIText("Propose time", fontWeight: .bold)
                    }
                }
                .padding(ViewHelper.padding)
                .background(ViewHelper.accentBlue)
                .cornerRadius(ViewHelper.componentRounding)
                
                Spacer()
            }
            Spacer()
        }
        .padding(ViewHelper.padding)
        .background(ViewHelper.fieldBgColor)
        .cornerRadius(ViewHelper.componentRounding)
    }
}

#Preview {
    let sessionManager = SessionManager()
    let messagingRepository = APIMessagingRepository(sessionManager: sessionManager)
    
    ProposeMeetingView(
        viewModel: ProposeMeetingViewModel(
            meetingScheduler: MeetingScheduler(
                availableTimeRanges: [
                    TimeRange(
                        startTime: 120,
                        endTime: 150,
                        day: Date()
                    ),
                    TimeRange(
                        startTime: 240,
                        endTime: 900,
                        day: Date()
                    ),
                    TimeRange(
                        startTime: 1000,
                        endTime: 1060,
                        day: Date()
                    )
                ],
                daysAllowed: [Date()],
                startTime: 120,
                endTime: 850,
                conversationID: 12,
                title: "Incredible meeting"
            ),
            sessionManager: sessionManager,
            messagingRepository: messagingRepository
        ),
        messageId: 12,
        navigationActive: [],
        messagingRepository: messagingRepository
    )
}
