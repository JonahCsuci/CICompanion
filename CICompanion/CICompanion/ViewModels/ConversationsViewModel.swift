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
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var errorMessage: String?
    @Published var searchErrorMessage: String?
    @Published var searchQuery = ""

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

    func loadConversations() {
        searchTask?.cancel()
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let loaded = try await messagingRepository.loadConversations()
                conversations = sortedByRecent(loaded.filter { $0.lastMessageAt != nil })
                isLoading = false
                applyCurrentSearchState()
            } catch {
                conversations = []
                displayedConversations = []
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
            return
        }

        guard trimmed.count >= minimumSearchLength else {
            isSearching = false
            displayedConversations = conversations
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: searchDebounceNanoseconds)

            guard !Task.isCancelled else { return }

            isSearching = true

            do {
                let results = try await messagingRepository.searchConversations(query: trimmed)

                guard !Task.isCancelled else { return }

                displayedConversations = results
                searchErrorMessage = nil
                isSearching = false
            } catch {
                guard !Task.isCancelled else { return }

                displayedConversations = []
                searchErrorMessage = "Unable to search conversations."
                isSearching = false
                print("Error searching conversations:", error)
            }
        }
    }

    func clearSearch() {
        searchTask?.cancel()
        searchQuery = ""
        searchErrorMessage = nil
        isSearching = false
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
            applyCurrentSearchState()
        } catch {
            // Intentional: best-effort background refresh
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
