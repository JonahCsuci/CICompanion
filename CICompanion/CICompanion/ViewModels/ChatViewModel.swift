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

    let messagingRepository: MessagingRepositoryProtocol
    let currentUserId: String

    init(messagingRepository: MessagingRepositoryProtocol, currentUserId: String) {
        self.messagingRepository = messagingRepository
        self.currentUserId = currentUserId
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

        Task {
            do {
                let detail = try await messagingRepository.loadMessages(conversationId: conversationId)
                messages = detail.messages
                isLoading = false
            } catch {
                isLoading = false
                print("Error loading messages:", error)
            }
        }
    }

    // Silent refresh for the 5-second auto-poll — no loading spinner to avoid UI flicker.
    func refreshMessages(conversationId: Int) async {
        do {
            let detail = try await messagingRepository.loadMessages(conversationId: conversationId)
            messages = detail.messages
        } catch {
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
                messages.append(sent)
                messageText = ""
                successfulSendCount += 1
                isSending = false
            } catch {
                isSending = false
                print("Error sending message:", error)
            }
        }
    }
}
