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
}
