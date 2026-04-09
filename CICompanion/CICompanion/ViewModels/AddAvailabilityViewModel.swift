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
        for range in ranges {
            meetingScheduler.availableTimeRanges.append(range.range)
        }
    }
    
    func send(ranges: Set<TimeBlock>, messageId: Int) {
        addTimeRanges(ranges: ranges)
        
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
                print("goo")
            }
        }
    }
}
