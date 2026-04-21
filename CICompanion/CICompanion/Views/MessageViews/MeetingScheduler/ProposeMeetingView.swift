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
    
    var courseRepository: CourseRepositoryProtocol
    
    init (
        viewModel: ProposeMeetingViewModel,
        messageId: Int,
        navigationActive: [Binding<Bool>],
        messagingRepository: MessagingRepositoryProtocol,
        courseRepository: CourseRepositoryProtocol
    ) {
        _viewModel = StateObject(wrappedValue: viewModel);
        self.messageId = messageId
        self.navigationsActive = navigationActive
        self.meet = viewModel.meetingScheduler
        self.messagingRepository = messagingRepository
        self.courseRepository = courseRepository
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
                        MeetingProposalCardView(
                            proposal: time,
                            meet: meet,
                            viewModel: viewModel,
                            courseRepository: courseRepository,
                            navigationsActive: navigationsActive
                        )
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
}

struct MeetingProposalCardView: View {
    @State var proposal: MeetingProposal
    let meet: MeetingScheduler
    let viewModel: ProposeMeetingViewModel
    let courseRepository: CourseRepositoryProtocol
    let navigationsActive: [Binding<Bool>]
    
    @State var startTime : Date = Date()
    @State var endTime : Date = Date()
    
    @State private var coursesBeforeAfter: ProposeMeetingViewModel.CoursesBeforeAfter? = nil
    
    var body: some View {
        let time = proposal.timeRange
        HStack {
            Spacer()
            VStack {
                CIText(DateHelper.dateToDayString(time.day), fontSize: ViewHelper.textSize * 2, fontWeight: .bold)
                
                HStack(spacing: ViewHelper.spacing*2) {
                    CITimeField(time: $startTime)
                        .onSubmit {
                            proposal.timeRange.startTime = DateHelper.timeStringToMinutes(DateHelper.dateToTimeString(startTime)) ?? 0
                        }
                    
                    CIText("to", color: ViewHelper.text)
                        .fixedSize()
                    
                    CITimeField(time: $endTime)
                        .onSubmit {
                            proposal.timeRange.endTime = DateHelper.timeStringToMinutes(DateHelper.dateToTimeString(endTime)) ?? 0
                        }
                }
                
                // Access course information to show where this fits in in the schedule!
                
                CIText("\(proposal.studyRoomID != nil ? "Study room available: \(proposal.studyRoom())" : "Study room not available")")
                
                if (proposal.studyRoomID != nil) {
                    Link(destination: URL(string: "https://csuci.libcal.com/space/\(proposal.studyRoomID!)")!) {
                        HStack {
                            Image(systemName: "link").font(.system(size: ViewHelper.textSize, weight: .bold))
                                .foregroundColor(ViewHelper.textImportant)
                            CIText("Book study room", fontWeight: .bold)
                        }
                    }
                    .padding(ViewHelper.padding)
                    .background(ViewHelper.accentBlue)
                    .cornerRadius(ViewHelper.componentRounding)
                }
                
                CIText("\(time.peopleAvailable.count) / \(meet.respondees.count) \((meet.respondees.count == 1) ? "person" : "people") available")
                
                if coursesBeforeAfter != nil {
                    Divider()
                        .background(ViewHelper.textImportant)
                    
                    CIText("How does this fit into your schedule?", color: ViewHelper.text)
                    
                    Spacer()
                    
                    VStack {
                        if (coursesBeforeAfter!.before != nil) {
                            let course = coursesBeforeAfter!.before!
                            timeRangeCard(name: course.courseName, start: DateHelper.timeStringToMinutes(course.startTime) ?? 0, end: DateHelper.timeStringToMinutes(course.endTime) ?? 0, overlap: coursesBeforeAfter!.overlapBefore)
                        } else {
                            CIText("No events before...", color: ViewHelper.text)
                        }
                        
                        timeRangeCard(name: proposal.title, start: proposal.timeRange.startTime, end: proposal.timeRange.endTime, overlap: coursesBeforeAfter!.overlapBefore || coursesBeforeAfter!.overlapAfter, meeting: true)
                        
                        if (coursesBeforeAfter!.after != nil) {
                            let course = coursesBeforeAfter!.after!
                            timeRangeCard(name: course.courseName, start: DateHelper.timeStringToMinutes(course.startTime) ?? 0, end: DateHelper.timeStringToMinutes(course.endTime) ?? 0, overlap: coursesBeforeAfter!.overlapAfter)
                        } else {
                            CIText("No events after...", color: ViewHelper.text)
                        }
                    }
                    
                    Spacer()
                
                    Divider()
                        .background(ViewHelper.textImportant)
                }
                
                Button {
                    proposal.timeRange.startTime =  DateHelper.timeStringToMinutes(DateHelper.dateToTimeString(startTime)) ?? 0
                    
                    proposal.timeRange.endTime =  DateHelper.timeStringToMinutes(DateHelper.dateToTimeString(endTime)) ?? 0
                    
                    viewModel.proposeMeeting(prop: proposal)
                    
                    for nav in navigationsActive {
                        nav.wrappedValue = false
                    }
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
        .task {
            do {
                coursesBeforeAfter = try await viewModel.getCoursesBeforeAndAfter(
                    prop: proposal,
                    courseRepository: courseRepository
                )
            } catch {
                print("Error loading courses: \(error)")
            }
        }.task {
            startTime = DateHelper.minutesToDate(proposal.timeRange.startTime)
            endTime = DateHelper.minutesToDate(proposal.timeRange.endTime)
        }
    }
    
    func timeRangeCard(name: String, start: Int, end: Int, overlap: Bool = false, meeting: Bool = false) -> some View {
        HStack {
            VStack {
                CIText(name, fontWeight: .medium)
                if meeting {
                    CIText("[MEETING]", color: overlap ? ViewHelper.textImportant : ViewHelper.text)
                }
            }
            Spacer()
            VStack {
                CIText(DateHelper.minutesToTimeString(start), color: overlap ? ViewHelper.textImportant : ViewHelper.text)
                CIText(DateHelper.minutesToTimeString(end), color: overlap ? ViewHelper.textImportant : ViewHelper.text)
            }
        }
        .padding(ViewHelper.padding)
        .background(overlap ? (meeting ? ViewHelper.accentRed : ViewHelper.accentRed.opacity(0.75)) : ViewHelper.cardBgColor)
        .cornerRadius(ViewHelper.componentRounding)
    }
}
