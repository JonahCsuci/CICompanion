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
            VStack {
                CIText("[Proposed] · \(DateHelper.dateToDayString(proposal.timeRange.day))", color: ViewHelper.textImportant.opacity(0.75))
                
                CIText("\(proposal.title)", fontSize: 20, fontWeight: .bold)
                
                HStack(spacing: 0) {
                    CIText("\(DateHelper.minutesToTimeString(proposal.timeRange.startTime))-\(DateHelper.minutesToTimeString(proposal.timeRange.endTime))")
                }
                
                HStack(spacing: ViewHelper.tinyPadding) {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(proposal.studyRoomID != nil ? ViewHelper.textImportant : ViewHelper.text)
                    CIText(proposal.studyRoomID != nil ? proposal.studyRoom() : "No room", color: (proposal.studyRoomID != nil ? ViewHelper.textImportant : ViewHelper.text), fontWeight: proposal.studyRoomID != nil ? .semibold : .regular)
                }
                
                if coursesBeforeAfter != nil {
                    if (coursesBeforeAfter!.hasConflict) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill").padding(8).background(ViewHelper.accentRed).cornerRadius(64)
                            
                            VStack(alignment: .leading) {
                                CIText("Conflicts with \(coursesBeforeAfter!.conflicts.count) \(coursesBeforeAfter!.conflicts.count == 1 ? "class" : "classes")", color: .white, fontWeight: .semibold)
                            }
                            Spacer()
                        }
                        .padding(ViewHelper.padding)
                        .background(.white.opacity(ViewHelper.opacity))
                        .cornerRadius(ViewHelper.componentRounding)
                    }
                    
                    Divider()
                        .background(ViewHelper.textImportant)
                    
                    CIText("Your day")
                    
                    Spacer()
                    
                    VStack {
                        if (coursesBeforeAfter!.before != nil) {
                            let course = coursesBeforeAfter!.before!
                            timeRangeCard(name: course.courseName, start: DateHelper.timeStringToMinutes(course.startTime) ?? 0, end: DateHelper.timeStringToMinutes(course.endTime) ?? 0, overlap: coursesBeforeAfter!.conflicts.contains(course))
                        } else {
                            CIText("No events before...")
                        }
                        
                        timeRangeCard(name: proposal.title, start: proposal.timeRange.startTime, end: proposal.timeRange.endTime, meeting: true)
                        
                        if (coursesBeforeAfter!.after != nil) {
                            let course = coursesBeforeAfter!.after!
                            timeRangeCard(name: course.courseName, start: DateHelper.timeStringToMinutes(course.startTime) ?? 0, end: DateHelper.timeStringToMinutes(course.endTime) ?? 0, overlap: coursesBeforeAfter!.conflicts.contains(course))
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
                            CIText("Add to calendar", color: .black)
                            Spacer()
                        }
                        .padding(10).background(.white)
                        .cornerRadius(16).foregroundColor(.black)
                    }.padding(10)
                }
            }
        }.task {
            do {
                coursesBeforeAfter = try await ProposeMeetingViewModel.getCoursesBeforeAndAfter(
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
}

