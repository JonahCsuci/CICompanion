//
//  AddAvailabilityViewModel.swift
//  CICompanion
//
//  Created by Emma on 4/8/26.
//

import SwiftUI
import Combine
import Foundation

@MainActor
class AddAvailabilityViewModel: ObservableObject {
    var meetingScheduler: MeetingScheduler
    let sessionManager: SessionManager
    let messagingRepository: MessagingRepositoryProtocol

    init(
        meetingScheduler: MeetingScheduler,
        sessionManager: SessionManager,
        messagingRepository: MessagingRepositoryProtocol
    ) {
        self.meetingScheduler = meetingScheduler
        self.sessionManager = sessionManager
        self.messagingRepository = messagingRepository
    }
    
    func addTimeRanges(ranges: Set<TimeBlock>) {
        if sessionManager.userId != nil {
            for var range in meetingScheduler.availableTimeRanges {
                range.peopleAvailable.remove(sessionManager.userId!)
            }
            
            for block in ranges {
                var range = block.range
                range.peopleAvailable.insert(sessionManager.userId!)
                meetingScheduler.availableTimeRanges.append(range)
            }
        }

        let sortedRanges = ranges
            .map(\.range)
            .sorted {
                if Calendar.current.isDate($0.day, inSameDayAs: $1.day) {
                    return $0.startTime < $1.startTime
                }
                return $0.day < $1.day
            }

        meetingScheduler.availableTimeRanges.append(contentsOf: sortedRanges)
    }
    
    func send(ranges: Set<TimeBlock>, messageId: Int) {
        addTimeRanges(ranges: ranges)
        
        if let uID = sessionManager.userId {
            meetingScheduler.respondees.insert(uID)
        }
        
        Task {
            do {
                let encoder = JSONEncoder()
                if let encoded = try? encoder.encode(meetingScheduler) {
                    if (messageId == -1) {
                        try await messagingRepository.sendMessage(conversationId: self.meetingScheduler.conversationID, body: encoded.base64EncodedString())
                    } else {
                        try await messagingRepository.editMeetup(messageId: messageId, body: encoded.base64EncodedString())
                    }
                }
            } catch {
                print("There was an error updating/creating a meeting message: \(error)")
            }
        }
    }
}
