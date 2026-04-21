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
    @State var proposal: MeetingProposal
    let sessionManager : SessionManager
    let messagingRepository : MessagingRepositoryProtocol
    let courseRepository : CourseRepositoryProtocol
    let conversation : Conversation
    let studentRepository: StudentRepositoryProtocol
    @State var responded = false
    
    @State var navigationActive = false
    
    @State private var coursesBeforeAfter: ProposeMeetingViewModel.CoursesBeforeAfter? = nil
    
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
                
                if coursesBeforeAfter != nil {
                    Divider()
                        .background(ViewHelper.textImportant)
                    
                    CIText("How does this fit into your schedule?")
                    
                    Spacer()
                    
                    VStack {
                        if (coursesBeforeAfter!.before != nil) {
                            let course = coursesBeforeAfter!.before!
                            timeRangeCard(name: course.courseName, start: DateHelper.timeStringToMinutes(course.startTime) ?? 0, end: DateHelper.timeStringToMinutes(course.endTime) ?? 0, overlap: coursesBeforeAfter!.overlapBefore)
                        } else {
                            CIText("No events before...")
                        }
                        
                        timeRangeCard(name: proposal.title, start: proposal.timeRange.startTime, end: proposal.timeRange.endTime, overlap: coursesBeforeAfter!.overlapBefore || coursesBeforeAfter!.overlapAfter, meeting: true)
                        
                        if (coursesBeforeAfter!.after != nil) {
                            let course = coursesBeforeAfter!.after!
                            timeRangeCard(name: course.courseName, start: DateHelper.timeStringToMinutes(course.startTime) ?? 0, end: DateHelper.timeStringToMinutes(course.endTime) ?? 0, overlap: coursesBeforeAfter!.overlapAfter)
                        } else {
                            CIText("No events after...")
                        }
                    }
                    
                    Spacer()
                
                    Divider()
                        .background(ViewHelper.textImportant)
                }
                
                if responded {
                    CIText("✓ Added to calendar", fontSize: ViewHelper.smallTextSize)
                } else {
                    HStack(spacing: 12) {
                        Button {
                            responded = true
                            Task {
                                do {
                                    var meetings = try await studentRepository.loadStudent().meetings
                                    
                                    if !meetings.contains(proposal) {
                                        meetings.append(proposal)
                                    }
                                    
                                    try await studentRepository.updateScheduleTimes(meetings: meetings)
                                } catch {
                                    print("There was an error adding the student meeting: \(error)")
                                }
                            }
                        } label: {
                            Spacer()
                            Image(systemName: "calendar").font(.system(size: ViewHelper.textSize, weight: .semibold))
                            CIText("Add to calendar")
                            Spacer()
                        }
                        .padding(10).background(ViewHelper.lightBgColor)
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
        }.task {
            do {
                coursesBeforeAfter = try await getCoursesBeforeAndAfter(
                    prop: proposal,
                    courseRepository: courseRepository
                )
            } catch {
                print("Error loading courses: \(error)")
            }
            do {
                let student = try await studentRepository.loadStudent()
                responded = student.meetings.contains(proposal)
            } catch {
                responded = false
                print("Failed to load student in MeetingProposalBubbleView .task: \(error)")
            }
        }
    }
    
    func timeRangeCard(name: String, start: Int, end: Int, overlap: Bool = false, meeting: Bool = false) -> some View {
        HStack {
            VStack {
                CIText(name, fontWeight: .medium)
                if meeting {
                    CIText("[MEETING]", color: overlap ? ViewHelper.textImportant : ViewHelper.text)
                    if overlap {
                        CIText("CONFLICTING TIMES", color: overlap ? ViewHelper.textImportant : ViewHelper.text)
                    }
                }
            }
            Spacer()
            VStack {
                CIText(DateHelper.minutesToTimeString(start), color: overlap ? ViewHelper.textImportant : ViewHelper.text)
                CIText(DateHelper.minutesToTimeString(end), color: overlap ? ViewHelper.textImportant : ViewHelper.text)
            }
        }
        .padding(ViewHelper.padding)
        .background(overlap ? (meeting ? ViewHelper.accentRed : ViewHelper.accentPink) : ViewHelper.lightBgColor)
        .cornerRadius(ViewHelper.componentRounding)
    }
    
    func getCoursesBeforeAndAfter(prop: MeetingProposal, courseRepository: CourseRepositoryProtocol) async throws -> ProposeMeetingViewModel.CoursesBeforeAfter? {
        let courses = try await courseRepository.loadStudentCourses()

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE"

        let dayOfTheWeek = formatter.string(from: prop.timeRange.day)
        let startTime = prop.timeRange.startTime
        let endTime = prop.timeRange.endTime

        var before: [Course] = []
        var after: [Course] = []
        var overlapBefore = false
        var overlapAfter = false

        for course in courses {
            guard course.days.contains(dayOfTheWeek) else { continue }
            
            let courseStartTime = DateHelper.timeStringToMinutes(course.startTime)
            let courseEndTime = DateHelper.timeStringToMinutes(course.endTime)
            
            if (courseStartTime == nil || courseEndTime == nil) {continue}

            if courseEndTime! <= startTime {
                before.append(course)
            } else if courseStartTime! >= endTime {
                after.append(course)
            } else {
                if courseEndTime! > startTime && courseEndTime! < endTime {
                    overlapBefore = true
                    before.append(course)
                }
                if courseStartTime! > startTime && courseStartTime! < endTime {
                    overlapAfter = true
                    after.append(course)
                }
                if courseStartTime! <= startTime && courseEndTime! >= endTime {
                    overlapBefore = true
                    overlapAfter = true
                    before.append(course)
                    after.append(course)
                }
            }
        }
        
        before.sort {
            (DateHelper.timeStringToMinutes($0.endTime) ?? 0) >
            (DateHelper.timeStringToMinutes($1.endTime) ?? 0)
        }
        after.sort {
            (DateHelper.timeStringToMinutes($0.startTime) ?? 0) >
            (DateHelper.timeStringToMinutes($1.startTime) ?? 0)
        }

        return ProposeMeetingViewModel.CoursesBeforeAfter(before: before.first, after: after.first, overlapBefore: overlapBefore, overlapAfter: overlapAfter)
    }
}

