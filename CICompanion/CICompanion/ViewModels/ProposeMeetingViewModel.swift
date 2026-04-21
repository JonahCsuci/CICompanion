//
//  ProposeMeetingViewModel.swift
//  CICompanion
//
//  Created by Emma on 4/16/26.
//

import SwiftUI
import Combine
import Foundation

@MainActor
class ProposeMeetingViewModel: ObservableObject {
    var meetingScheduler: MeetingScheduler
    var sessionManager: SessionManager
    var messagingRepository: MessagingRepositoryProtocol
    
    init (
        meetingScheduler: MeetingScheduler,
        sessionManager: SessionManager,
        messagingRepository: MessagingRepositoryProtocol
    ) {
        self.meetingScheduler = meetingScheduler
        self.sessionManager = sessionManager
        self.messagingRepository = messagingRepository
    }
    
    func proposeMeeting(prop: MeetingProposal) {
        Task {
            do {
                let encoder = JSONEncoder()
                if let encoded = try? encoder.encode(prop) {
                    var _ = try await messagingRepository.sendMessage(conversationId: self.meetingScheduler.conversationID, body: encoded.base64EncodedString())
                }
            } catch {
                print("There was an error updating/creating a meeting message: \(error)")
            }
        }
    }
    
    struct CoursesBeforeAfter {
        let before : Course?
        let after : Course?
        let overlapBefore : Bool
        let overlapAfter : Bool
    }
    
    func getCoursesBeforeAndAfter(prop: MeetingProposal, courseRepository: CourseRepositoryProtocol) async throws -> CoursesBeforeAfter? {
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

        return CoursesBeforeAfter(before: before.first, after: after.first, overlapBefore: overlapBefore, overlapAfter: overlapAfter)
    }
}
