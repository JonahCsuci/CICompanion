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
    @Published var errorMessage: String?
    @Published var isForbidden = false

    let messagingRepository: MessagingRepositoryProtocol
    let currentUserId: String

    private let messageHistoryLimit = 200
    private let onMessageSent: (() -> Void)?

    var latestOutgoingMessageId: Int? {
        messages.last(where: { $0.senderId == currentUserId })?.id
    }

    init(
        messagingRepository: MessagingRepositoryProtocol,
        currentUserId: String,
        onMessageSent: (() -> Void)? = nil
    ) {
        self.messagingRepository = messagingRepository
        self.currentUserId = currentUserId
        self.onMessageSent = onMessageSent
    }

    func getMeeting(body: String) -> String {
        do {
            let JSON = try body.base64DecodedString()
            return JSON
        } catch {
            return ""
        }
    }
    
    func loadMessages(conversationId: Int) {
        isLoading = true
        errorMessage = nil
        isForbidden = false

        Task {
            do {
                let detail = try await messagingRepository.loadMessages(conversationId: conversationId)
                messages = trimmed(detail.messages)
                isLoading = false
            } catch {
                isLoading = false
                if let nsError = error as? NSError, nsError.code == 403 {
                    isForbidden = true
                    errorMessage = nsError.localizedDescription
                } else {
                    errorMessage = error.localizedDescription
                }
                print("Error loading messages:", error)
            }
        }
    }

    func refreshMessages(conversationId: Int) async {
        do {
            let detail = try await messagingRepository.loadMessages(conversationId: conversationId)
            let latest = trimmed(detail.messages)
            if latest != messages {
                messages = latest
            }
            errorMessage = nil
            isForbidden = false
        } catch {
            if let nsError = error as? NSError, nsError.code == 403 {
                isForbidden = true
                errorMessage = nsError.localizedDescription
            }
            print("Error refreshing messages:", error)
        }
    }

    func sendMessage(conversationId: Int) {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSending = true

        Task {
            do {
                let sent = try await messagingRepository.sendMessage(
                    conversationId: conversationId,
                    body: trimmed
                )
                if !messages.contains(where: { $0.id == sent.id }) {
                    messages.append(sent)
                }
                messageText = ""
                isSending = false
                onMessageSent?()
            } catch {
                isSending = false
                print("Error sending message:", error)
            }
        }
    }

    private func trimmed(_ incoming: [Message]) -> [Message] {
        guard incoming.count > messageHistoryLimit else { return incoming }
        return Array(incoming.suffix(messageHistoryLimit))
    }
}
