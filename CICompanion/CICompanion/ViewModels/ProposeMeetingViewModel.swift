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
        let before: Course?
        let after: Course?
        let conflicts: [Course]
        
        var hasConflict: Bool { !conflicts.isEmpty }
    }
    
    static func getCoursesBeforeAndAfter(prop: MeetingProposal, courseRepository: CourseRepositoryProtocol) async throws -> CoursesBeforeAfter? {
        let courses = try await courseRepository.loadStudentCourses()

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE"

        let dayOfTheWeek = formatter.string(from: prop.timeRange.day)
        let meetingStart = prop.timeRange.startTime
        let meetingEnd = prop.timeRange.endTime

        var before: [Course] = []
        var after: [Course] = []
        var conflicts: [Course] = []

        for course in courses {
            guard course.days.contains(dayOfTheWeek),
                  let courseStart = DateHelper.timeStringToMinutes(course.startTime),
                  let courseEnd = DateHelper.timeStringToMinutes(course.endTime)
            else { continue }

            if courseStart < meetingStart {
                before.append(course)
            } else if courseStart >= meetingEnd {
                after.append(course)
            }
            if courseStart < meetingEnd && courseEnd > meetingStart {
                conflicts.append(course)
            }
        }

        before.sort { (DateHelper.timeStringToMinutes($0.endTime) ?? 0) > (DateHelper.timeStringToMinutes($1.endTime) ?? 0) }
        after.sort { (DateHelper.timeStringToMinutes($0.startTime) ?? 0) < (DateHelper.timeStringToMinutes($1.startTime) ?? 0) }

        return CoursesBeforeAfter(
            before: before.first,
            after: after.first,
            conflicts: conflicts
        )
    }
}
