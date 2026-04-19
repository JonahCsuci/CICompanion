//
//  MeetingDetailsView.swift
//  CICompanion
//
//  Created by Emma on 4/16/26.
//

import SwiftUI

struct MeetingDetailsView: View {
    @Environment(\.dismiss) var dismiss
    
    var navigationsActive: [Binding<Bool>]
    var messageId: Int
    var meetingScheduler: MeetingScheduler
    var sessionManager: SessionManager
    var messagingRepository: MessagingRepositoryProtocol
    
    init (
        navigationsActive: [Binding<Bool>],
        messageId: Int,
        meetingScheduler: MeetingScheduler,
        sessionManager: SessionManager,
        messagingRepository: MessagingRepositoryProtocol
    ) {
        self.navigationsActive = navigationsActive
        self.messageId = messageId
        self.meetingScheduler = meetingScheduler
        self.sessionManager = sessionManager
        self.messagingRepository = messagingRepository
    }
    
    var body: some View {
        CIView {
            
        }
    }
}
