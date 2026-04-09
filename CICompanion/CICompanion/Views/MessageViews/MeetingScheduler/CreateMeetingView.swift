//
//  CreateMeetingView.swift
//  CICompanion
//
//  Created by Emma on 4/8/26.
//

import SwiftUI

struct CreateMeetingView: View {
    @State var startDate: Date = Date()
    @State var endDate: Date = Date().addingTimeInterval(60*60*24*7) // a week from now
    @State var startTime: Date = Date()
    @State var endTime: Date = Date().addingTimeInterval(60*60)
    @State var studyRoomSearch: Bool = true
    
    var sessionManager : SessionManager
    var conversationID : Int
    var messagingRepository : MessagingRepositoryProtocol
    
    var body: some View {
        CIView(heading: {
            CIHeader {
                CIPageTitle("Set up meeting times")
            }
        }) {
            VStack(alignment: .leading, spacing: ViewHelper.spacing * 2) {
                Divider()
                
                HStack(spacing:0) {
                    CIText("What range of ", ViewHelper.text)
                    CIText("days", ViewHelper.accentBlue)
                        .bold()
                    CIText(" will the scheduler allow?", ViewHelper.text)
                }
                HStack(spacing: ViewHelper.spacing*2) {
                    CIDateField(date: $startDate)
                    
                    CIText("to", ViewHelper.text)
                        .fixedSize()
                    
                    CIDateField(date: $endDate)
                }
                
                HStack(spacing: 0) {
                    CIText("What range of ", ViewHelper.text)
                    CIText("times", ViewHelper.accentBlue)
                        .bold()
                    CIText(" will the scheduler allow?", ViewHelper.text)
                }
                
                HStack(spacing: ViewHelper.spacing*2) {
                    CITimeField(time: $startTime)
                    
                    CIText("to", ViewHelper.text)
                    
                    CITimeField(time: $endTime)
                }
                
                CISliderToggle(label: "Search for study rooms", toggleBool: $studyRoomSearch, toggleAction: {
                    
                })
                
                Spacer()
                
                HStack {
                    Spacer()
                    VStack {
                        NavigationLink {
                            AddAvailabilityView(
                                viewModel: AddAvailabilityViewModel(
                                    meetingScheduler: MeetingScheduler(
                                        daysAllowed: DateHelper.datesFromNowToThen(startDate, endDate), startTime: DateHelper.timeStringToMinutes(DateHelper.dateToTimeString(startTime)) ?? 0, endTime: DateHelper.timeStringToMinutes(DateHelper.dateToTimeString(endTime)) ?? 0, conversationID: conversationID
                                    ),
                                    sessionManager: sessionManager,
                                    messagingRepository: messagingRepository
                                ),
                                messageId: -1
                            )
                        } label: {
                            Text("Send the Meeting Scheduler")
                                .font(.system(size: ViewHelper.textSize, weight: .bold))
                                .foregroundColor(ViewHelper.textImportant)
                                .padding(ViewHelper.padding * 1.5)
                                .background(ViewHelper.accentBlue)
                                .cornerRadius(ViewHelper.componentRounding * 1.5)
                        }
                    }
                    Spacer()
                }
            }
        }
    }
}
