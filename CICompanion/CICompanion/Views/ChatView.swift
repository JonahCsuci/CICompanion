//
//  ChatView.swift
//  CICompanion
//

import SwiftUI

struct ChatView: View {

    @StateObject var viewModel: ChatViewModel
    let conversation: Conversation

    private let bgColor = Color(red: 0.08, green: 0.10, blue: 0.15)
    private let inputBgColor = Color(red: 0.12, green: 0.14, blue: 0.20)
    private let accentBlue = Color(red: 0.6, green: 0.8, blue: 1.0)

    init(viewModel: ChatViewModel, conversation: Conversation) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.conversation = conversation
    }

    var body: some View {
        VStack(spacing: 0) {
            messageList
            inputBar
        }
        .background(bgColor)
        .navigationTitle(conversation.otherParticipant.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            viewModel.loadMessages(conversationId: conversation.id)
        }
        .task(id: "poll-\(conversation.id)") {
            await pollForNewMessages()
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if viewModel.isLoading && viewModel.messages.isEmpty {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                } else if viewModel.messages.isEmpty {
                    Text("Send a message to start the conversation")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 100)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(
                                message: message,
                                isCurrentUser: message.senderId == viewModel.currentUserId
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
            .refreshable {
                await viewModel.refreshMessages(conversationId: conversation.id)
            }
            .onChange(of: viewModel.messages.count) { _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("", text: $viewModel.messageText, prompt: Text("Message").foregroundColor(ViewHelper.text))
                .foregroundColor(.white)
                .font(.system(size: 16))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(inputBgColor)
                .cornerRadius(20)

            Button {
                viewModel.sendMessage(conversationId: conversation.id)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(sendButtonDisabled ? .gray : accentBlue)
            }
            .disabled(sendButtonDisabled)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(red: 0.10, green: 0.12, blue: 0.18))
    }

    private var sendButtonDisabled: Bool {
        viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || viewModel.isSending
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastId = viewModel.messages.last?.id else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(lastId, anchor: .bottom)
        }
    }

    // Polls for new messages every 5 seconds while this view is on screen.
    // SwiftUI cancels this .task automatically when the view disappears.
    private func pollForNewMessages() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { break }
            await viewModel.refreshMessages(conversationId: conversation.id)
        }
    }
}
