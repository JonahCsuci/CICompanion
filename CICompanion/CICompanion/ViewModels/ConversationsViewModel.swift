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

    // Local optimistic overrides for unread counts, keyed by conversationId.
    // Lets us drop a row (and the tab badge) to zero the instant a chat is opened,
    // without waiting for the next poll. The server is still the source of truth.
    @Published private var unreadOverrides: [Int: Int] = [:]

    // Effective unread count for a conversation, honoring any local override.
    func unreadCount(for conversation: Conversation) -> Int {
        if let override = unreadOverrides[conversation.id] { return override }
        return conversation.unreadCount ?? 0
    }

    // Sum of unread counts across all conversations — drives the Messages tab badge.
    var totalUnreadCount: Int {
        conversations.reduce(0) { $0 + unreadCount(for: $1) }
    }

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
                conversations = sortedByRecent(loaded.filter { $0.lastMessageAt != nil })
                reconcileOverrides()
                isLoading = false
            } catch {
                conversations = []
                errorMessage = "Unable to load conversations."
                isLoading = false
                print("Error loading conversations:", error)
            }
        }
    }

    // Silent background refresh used by polling — no spinner, no error banner on transient failures.
    func refreshConversationsSilently() async {
        do {
            let loaded = try await messagingRepository.loadConversations()
            conversations = sortedByRecent(loaded.filter { $0.lastMessageAt != nil })
            reconcileOverrides()
        } catch {
            // Intentional: best-effort background refresh
        }
    }

    // Clear any override once the server has caught up (server count == our override).
    // Also drops overrides for conversations no longer in the list.
    private func reconcileOverrides() {
        guard !unreadOverrides.isEmpty else { return }
        let idsInList = Set(conversations.map { $0.id })
        for (id, override) in unreadOverrides {
            if !idsInList.contains(id) {
                unreadOverrides.removeValue(forKey: id)
                continue
            }
            if let server = conversations.first(where: { $0.id == id })?.unreadCount,
               server == override {
                unreadOverrides.removeValue(forKey: id)
            }
        }
    }

    // Optimistic local-only update so the tab badge & row count drop immediately when a chat is opened,
    // without waiting for the next poll. The backend is the source of truth — the next poll will reconcile.
    func markConversationReadLocally(conversationId: Int) {
        unreadOverrides[conversationId] = 0
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
