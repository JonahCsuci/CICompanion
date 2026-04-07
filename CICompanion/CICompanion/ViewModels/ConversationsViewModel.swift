//
//  ConversationsViewModel.swift
//  CICompanion
//

import Foundation
import Combine

@MainActor
class ConversationsViewModel: ObservableObject {

    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let messagingRepository: MessagingRepositoryProtocol

    init(messagingRepository: MessagingRepositoryProtocol) {
        self.messagingRepository = messagingRepository
    }

    func loadConversations() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let loaded = try await messagingRepository.loadConversations()
                conversations = sortedByRecent(loaded)
                isLoading = false
            } catch {
                conversations = []
                errorMessage = "Unable to load conversations."
                isLoading = false
                print("Error loading conversations:", error)
            }
        }
    }

    // Most recent conversations first; nil lastMessageAt sorts to bottom
    private func sortedByRecent(_ list: [Conversation]) -> [Conversation] {
        list.sorted { lhs, rhs in
            switch (lhs.lastMessageAt, rhs.lastMessageAt) {
            case let (l?, r?): return l > r
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil): return lhs.createdAt > rhs.createdAt
            }
        }
    }
}
