//
//  CreateMeetingView.swift
//  CICompanion
//
//  Created by Emma on 4/8/26.
//

import SwiftUI

struct CreateMeetingView: View {
    var days : [String] = [
        "Sunday",
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday"
    ]
    
    var times : [String] = [
        "6AM",
        "7AM",
        "8AM",
        "9AM",
        "10AM",
        "11AM",
        "12PM",
        "1PM",
        "2PM",
        "3PM",
        "4PM",
        "5PM",
        "6PM",
        "7PM",
        "8PM",
        "9PM",
        "10PM",
        "11PM",
        "12AM",
        "1AM",
        "2AM",
        "3AM",
        "4AM",
        "5AM"
    ]
    
    @State var startDate: Date = Date()
    @State var endDate: Date = Date().addingTimeInterval(60*60*24*7) // a week from now
    @State var startTime: Date = Date()
    @State var endTime: Date = Date().addingTimeInterval(60*60)
    @State var studyRoomSearch: Bool = true
    
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
                            LaunchLoadingView()
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

#Preview {
    CreateMeetingView()
}
