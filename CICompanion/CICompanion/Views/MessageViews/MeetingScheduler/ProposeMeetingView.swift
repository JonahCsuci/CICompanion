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
    
    @State var loading = true
    
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
            if loading {
                CILoadingPage()
            } else {
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
                            .padding(ViewHelper.padding)
                        }
                    }
                    .tabViewStyle(.page)
                }
                
                Spacer()
            }
        }
        .task {
            await loadBestTimes()
            loading = false
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
            VStack(spacing: ViewHelper.spacing) {
                CIText(DateHelper.dateToDayString(time.day, true), fontSize: ViewHelper.textSize * 2, fontWeight: .bold)
                
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
                
                HStack(spacing: ViewHelper.padding) {
                    HStack(spacing: ViewHelper.tinyPadding) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(proposal.studyRoomID != nil ? ViewHelper.accentGreen : ViewHelper.text)
                        CIText("\(time.peopleAvailable.count)/\(meet.respondees.count) available", color: ((time.peopleAvailable.count > 0) ? ViewHelper.accentGreen : ViewHelper.text))
                    }
                    
                    HStack(spacing: ViewHelper.tinyPadding) {
                        Image(systemName: "building.2.fill")
                            .foregroundColor(proposal.studyRoomID != nil ? ViewHelper.accentGreen : ViewHelper.text)
                        CIText(proposal.studyRoomID != nil ? proposal.studyRoom() : "No room", color: (proposal.studyRoomID != nil ? ViewHelper.accentGreen : ViewHelper.text))
                    }
                }
                
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
                
                if coursesBeforeAfter != nil {
                    Divider()
                        .background(ViewHelper.textImportant)
                    
                    VStack(alignment: .leading, spacing: ViewHelper.tinyPadding) {
                    
                        CIText("Your day", color: ViewHelper.text, fontSize: ViewHelper.smallTextSize)
                    
                        if (coursesBeforeAfter!.before != nil) {
                            let course = coursesBeforeAfter!.before!
                            timeRangeCard(name: course.courseName, start: DateHelper.timeStringToMinutes(course.startTime) ?? 0, end: DateHelper.timeStringToMinutes(course.endTime) ?? 0, overlap: coursesBeforeAfter!.conflicts.contains(course))
                        } else {
                            emptyDaySlot(label: "Nothing before meeting...")
                        }
                        
                        timeRangeCard(name: proposal.title, start: proposal.timeRange.startTime, end: proposal.timeRange.endTime, overlap: false, meeting: true)
                        
                        if (coursesBeforeAfter!.after != nil) {
                            let course = coursesBeforeAfter!.after!
                            timeRangeCard(name: course.courseName, start: DateHelper.timeStringToMinutes(course.startTime) ?? 0, end: DateHelper.timeStringToMinutes(course.endTime) ?? 0, overlap: coursesBeforeAfter!.conflicts.contains(course))
                        } else {
                            emptyDaySlot(label: "Nothing after meeting")
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
                coursesBeforeAfter = try await ProposeMeetingViewModel.getCoursesBeforeAndAfter(
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
        let color : Color = meeting ? ViewHelper.accentPurple : (overlap ? ViewHelper.accentRed : .white)
        let textColor : Color = meeting ? .black : .white
        let bgColor : Color = meeting ? .white : .white.opacity(ViewHelper.opacity)
        
        return HStack {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(color)
                .frame(width: 3)
                .padding(.vertical, 2)
                .padding(.trailing, 10)
            
            VStack(alignment: .leading) {
                CIText(name, color: textColor, fontWeight: .semibold)
                if meeting {
                    CIText("Proposed", color: color, fontWeight: .medium)
                }
                if overlap {
                    CIText("Conflicts", color: ViewHelper.accentPink, fontWeight: .medium)
                }
            }
            
            Spacer()
            
            VStack {
                CIText(DateHelper.minutesToTimeString(start), color: textColor.opacity(ViewHelper.opacity * 2.5), fontWeight: .medium)
                CIText(DateHelper.minutesToTimeString(end), color: textColor.opacity(ViewHelper.opacity * 2.5), fontWeight: .medium)
            }
        }
        .padding(ViewHelper.padding)
        .background(bgColor)
        .border(ViewHelper.accentRed, width: overlap ? 1 : 0)
        .cornerRadius(ViewHelper.componentRounding)
    }
    
    func emptyDaySlot(label: String) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(ViewHelper.text.opacity(ViewHelper.opacity))
                .frame(width: 3)
                .padding(.vertical, 2)
                .padding(.trailing, 10)
            
            CIText(label, color: ViewHelper.text, fontSize: ViewHelper.smallTextSize)
                .padding(ViewHelper.padding)
            Spacer()
        }
        .padding(ViewHelper.padding)
        .background(ViewHelper.cardBgColor)
        .cornerRadius(ViewHelper.componentRounding)
    }
}
