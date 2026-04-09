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
    let meetingScheduler: MeetingScheduler
    let sessionManager: SessionManager
    let messagingRepository: MessagingRepositoryProtocol

    @Published var selectedRanges: [TimeRange] = []

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
            selectedRanges.append(range.range)
        }
    }
    
    func send(ranges: Set<TimeBlock>, isNew: Bool) {
        Task {
            do {
                let encoder = JSONEncoder()
                if let encoded = try? encoder.encode(meetingScheduler) {
                    try await messagingRepository.sendMessage(conversationId: self.meetingScheduler.conversationID, body: encoded.base64EncodedString())
                }
            } catch {
                print("goo")
            }
        }
    }
}
