//
//  CreateMeetingView.swift
//  CICompanion
//
//  Created by Emma on 4/8/26.
//

import SwiftUI

struct CreateMeetingView: View {
    @State var startDate: Date = Date()
    @State var endDate: Date = Date().addingTimeInterval(60*60*24*5) // 5 days from now
    @State var startTime: Date = DateHelper.minutesToDate(60*9)
    @State var endTime: Date = DateHelper.minutesToDate(60*17)
    //@State var studyRoomSearch: Bool = true
    var navigationActive: Binding<Bool>
    @State var subNavActive: Bool = false
    
    var sessionManager : SessionManager
    var conversationID : Int
    var messagingRepository : MessagingRepositoryProtocol
    var courseRepository: CourseRepositoryProtocol
    
    @State var title : String = ""
    
    var body: some View {
        CIView(heading: {
            CIHeader {
                CIPageTitle("Set up meeting times")
            }
        }) {
            VStack(alignment: .leading, spacing: ViewHelper.spacing * 2) {
                Divider()
                
                CITextField(placeholder: "Title of meeting", text: $title, lines: 1)
                
                HStack(spacing:0) {
                    CIText("What range of ", color: ViewHelper.text)
                    CIText("days", color: ViewHelper.accentBlue)
                        .bold()
                    CIText(" will the scheduler allow?", color: ViewHelper.text)
                }
                HStack(spacing: ViewHelper.spacing*2) {
                    CIDateField(date: $startDate)
                    
                    CIText("to", color: ViewHelper.text)
                        .fixedSize()
                    
                    CIDateField(date: $endDate)
                }
                
                HStack(spacing: 0) {
                    CIText("What range of ", color: ViewHelper.text)
                    CIText("times", color: ViewHelper.accentBlue)
                        .bold()
                    CIText(" will the scheduler allow?", color: ViewHelper.text)
                }
                
                HStack(spacing: ViewHelper.spacing*2) {
                    CITimeField(time: $startTime)
                    
                    CIText("to", color: ViewHelper.text)
                    
                    CITimeField(time: $endTime)
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    VStack {
                        NavigationLink(destination:
                            AddAvailabilityView(
                                viewModel: AddAvailabilityViewModel(
                                    meetingScheduler: MeetingScheduler(
                                        daysAllowed: DateHelper.datesFromNowToThen(startDate, endDate),
                                        startTime: DateHelper.timeStringToMinutes(DateHelper.dateToTimeString(startTime)) ?? 0,
                                        endTime: DateHelper.timeStringToMinutes(DateHelper.dateToTimeString(endTime)) ?? 0,
                                        conversationID: conversationID,
                                        title: title
                                    ),
                                    sessionManager: sessionManager,
                                    messagingRepository: messagingRepository,
                                    courseRepository: courseRepository
                                ),
                                messageId: -1,
                                navigationActive: [$subNavActive, navigationActive]
                            ),
                            isActive: $subNavActive
                        ) {
                            Text("Continue")
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
