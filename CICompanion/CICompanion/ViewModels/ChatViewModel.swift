//
//  ChatViewModel.swift
//  CICompanion
//

import Foundation
import Combine
internal import ClientRuntime

@MainActor
class ChatViewModel: ObservableObject {

    @Published var messages: [Message] = []
    @Published var messageText = ""
    @Published var isLoading = false
    @Published var isSending = false
    @Published private(set) var successfulSendCount = 0
    // Latest conversation snapshot returned by loadMessages — carries fresh participants list,
    // group/admin metadata, etc. Falls back to the conversation passed into ChatView.
    @Published var loadedConversation: Conversation?
    // Set when the backend returns 403 from load/send (archived direct chat or removed group member).
    @Published var accessRevoked = false
    @Published var accessRevokedMessage: String?
    // Surfaces non-403 load/send errors so the user knows something failed instead of staring at a stale UI.
    @Published var errorMessage: String?

    let messagingRepository: MessagingRepositoryProtocol
    let currentUserId: String

    // Tracks which conversation the open ChatView is showing so realtime
    // `new_message` events for OTHER conversations are ignored (the chat list
    // handles them separately via ConversationsViewModel.handleRealtimeNewMessage).
    private var currentConversationId: Int?

    init(messagingRepository: MessagingRepositoryProtocol, currentUserId: String) {
        self.messagingRepository = messagingRepository
        self.currentUserId = currentUserId
    }

    func loadMessages(conversationId: Int) {
        currentConversationId = conversationId
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let detail = try await messagingRepository.loadMessages(conversationId: conversationId)
                messages = detail.messages
                loadedConversation = detail.conversation
                isLoading = false
                await markReadSilently(conversationId: conversationId)
            } catch {
                isLoading = false
                handleAccessError(error, label: "loading messages", userFacing: "Could not load messages.")
            }
        }
    }

    // Realtime path: a WebSocket-delivered message destined for the conversation
    // the user is currently viewing. Dedupe by server `Message.id` so the 1s poll
    // and the WebSocket push can race without producing duplicates.
    func ingest(_ message: Message) {
        guard message.conversationId == currentConversationId else { return }
        guard !messages.contains(where: { $0.id == message.id }) else { return }

        messages.append(message)
        messages.sort { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.id < rhs.id
            }
            return lhs.createdAt < rhs.createdAt
        }
    }

    // Silent refresh for the 5-second auto-poll — no loading spinner to avoid UI flicker.
    func refreshMessages(conversationId: Int) async {
        do {
            let detail = try await messagingRepository.loadMessages(conversationId: conversationId)
            messages = detail.messages
            loadedConversation = detail.conversation
            errorMessage = nil
            await markReadSilently(conversationId: conversationId)
        } catch {
            // Don't surface a user-visible error for silent polls — only access revocation matters here.
            handleAccessError(error, label: "refreshing messages", userFacing: nil)
        }
    }

    func sendMessage(conversationId: Int) {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSending = true
        errorMessage = nil

        Task {
            do {
                let sent = try await messagingRepository.sendMessage(
                    conversationId: conversationId,
                    body: trimmed
                )
                messages.append(sent)
                messageText = ""
                successfulSendCount += 1
                isSending = false
            } catch {
                isSending = false
                handleAccessError(error, label: "sending message", userFacing: "Could not send message. Tap to retry.")
            }
        }
    }

    // Fire-and-forget — receipt failures should never block the UI or surface errors.
    private func markReadSilently(conversationId: Int) async {
        do {
            try await messagingRepository.markRead(conversationId: conversationId)
        } catch {
            // Intentional: read receipts are best-effort
        }
    }

    private func handleAccessError(_ error: Error, label: String, userFacing: String?) {
        let nsError = error as NSError
        if nsError.domain == "APIError" && nsError.code == 403 {
            accessRevokedMessage = nsError.localizedDescription
            accessRevoked = true
        } else {
            print("Error \(label):", error)
            if let userFacing { errorMessage = userFacing }
        }
    }

    func clearErrorMessage() {
        errorMessage = nil
    }
}
