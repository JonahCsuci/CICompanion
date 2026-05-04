//
//  ConversationsViewModel.swift
//  CICompanion
//

import Foundation
import Combine

@MainActor
class ConversationsViewModel: ObservableObject {

    @Published var conversations: [Conversation] = []
    @Published var displayedConversations: [Conversation] = []
    @Published var meetingSearchResults: [MeetingSearchResult] = []
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var errorMessage: String?
    @Published var searchErrorMessage: String?
    @Published var searchQuery = ""

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

    private let minimumSearchLength = 3
    private let searchDebounceNanoseconds: UInt64 = 300_000_000
    private var searchTask: Task<Void, Never>?

    init(messagingRepository: MessagingRepositoryProtocol) {
        self.messagingRepository = messagingRepository
    }

    deinit {
        searchTask?.cancel()
    }

    var trimmedSearchQuery: String {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isSearchActive: Bool {
        trimmedSearchQuery.count >= minimumSearchLength
    }

    var shouldShowShortSearchHint: Bool {
        let trimmed = trimmedSearchQuery
        return !trimmed.isEmpty && trimmed.count < minimumSearchLength
    }

    var displayedSearchResults: [MessageSearchResult] {
        guard isSearchActive else {
            return conversations.map { .conversation($0) }
        }

        return displayedConversations.map { .conversation($0) }
            + meetingSearchResults.map { .meeting($0) }
    }

    var hasDisplayedResults: Bool {
        !displayedSearchResults.isEmpty
    }

    func loadConversations() {
        searchTask?.cancel()
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let loaded = try await messagingRepository.loadConversations()
                conversations = sortedByRecent(loaded.filter { $0.lastMessageAt != nil })
                reconcileOverrides()
                isLoading = false
                applyCurrentSearchState()
            } catch {
                conversations = []
                displayedConversations = []
                meetingSearchResults = []
                errorMessage = "Unable to load conversations."
                isLoading = false
                print("Error loading conversations:", error)
            }
        }
    }

    func updateSearchQuery(_ query: String) {
        searchQuery = query
        searchTask?.cancel()
        searchErrorMessage = nil

        let trimmed = trimmedSearchQuery

        guard !trimmed.isEmpty else {
            isSearching = false
            displayedConversations = conversations
            meetingSearchResults = []
            return
        }

        guard trimmed.count >= minimumSearchLength else {
            isSearching = false
            displayedConversations = conversations
            meetingSearchResults = []
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: searchDebounceNanoseconds)

            guard !Task.isCancelled else { return }

            isSearching = true

            var nextConversationResults: [Conversation] = []
            var nextMeetingResults: [MeetingSearchResult] = []
            var failedSearches: [String] = []

            do {
                nextConversationResults = try await messagingRepository.searchConversations(query: trimmed)
            } catch {
                failedSearches.append("messages")
                print("Error searching conversations:", error)
            }

            guard !Task.isCancelled else { return }

            do {
                nextMeetingResults = try await messagingRepository.searchMeetingSchedulers(query: trimmed)
            } catch {
                failedSearches.append("meetings")
                print("Error searching meeting schedulers:", error)
            }

            guard !Task.isCancelled else { return }

            displayedConversations = nextConversationResults
            meetingSearchResults = nextMeetingResults

            if failedSearches.isEmpty {
                searchErrorMessage = nil
            } else if failedSearches.count == 2 {
                searchErrorMessage = "Unable to search messages or meetings."
            } else {
                searchErrorMessage = "Unable to search \(failedSearches[0])."
            }

            isSearching = false
        }
    }

    func clearSearch() {
        searchTask?.cancel()
        searchQuery = ""
        searchErrorMessage = nil
        isSearching = false
        meetingSearchResults = []
        displayedConversations = conversations
    }

    private func applyCurrentSearchState() {
        if isSearchActive {
            updateSearchQuery(searchQuery)
        } else {
            displayedConversations = conversations
        }
    }

    // Silent background refresh used by polling — no spinner, no error banner on transient failures.
    func refreshConversationsSilently() async {
        do {
            let loaded = try await messagingRepository.loadConversations()
            conversations = sortedByRecent(loaded.filter { $0.lastMessageAt != nil })
            reconcileOverrides()
            applyCurrentSearchState()
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
