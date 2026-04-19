//
//  ChatView.swift
//  CICompanion
//

import SwiftUI

struct ChatView: View {
    @State var navigationActive = false
    @State private var showGroupInfo = false
    @Environment(\.dismiss) private var dismiss

    @StateObject var viewModel: ChatViewModel
    @ObservedObject var contactsViewModel: ContactsViewModel
    let conversation: Conversation
    var sessionManager : SessionManager
    var messagingRepository : MessagingRepositoryProtocol

    private let bgColor = Color(red: 0.08, green: 0.10, blue: 0.15)
    private let inputBgColor = Color(red: 0.12, green: 0.14, blue: 0.20)
    private let accentBlue = Color(red: 0.6, green: 0.8, blue: 1.0)

    init(viewModel: ChatViewModel, conversation: Conversation, sessionManager: SessionManager, messagingRepository: MessagingRepositoryProtocol, contactsViewModel: ContactsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.conversation = conversation
        self.sessionManager = sessionManager
        self.messagingRepository = messagingRepository
        self.contactsViewModel = contactsViewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            messageList
            inputBar
        }
        .background(bgColor)
        .navigationTitle(conversation.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            if conversation.isGroup {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showGroupInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .task {
            viewModel.loadMessages(conversationId: conversation.id)
            try? await messagingRepository.markRead(conversationId: conversation.id)
        }
        .task(id: "poll-\(conversation.id)") {
            await pollForNewMessages()
        }
        .sheet(isPresented: $showGroupInfo) {
            GroupInfoView(
                conversation: conversation,
                messagingRepository: messagingRepository,
                contactsViewModel: contactsViewModel,
                currentUserId: viewModel.currentUserId,
                onConversationUpdated: {
                    viewModel.loadMessages(conversationId: conversation.id)
                },
                onLeftGroup: {
                    dismiss()
                }
            )
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if viewModel.isForbidden {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)

                        Text(viewModel.errorMessage ?? "You no longer have access to this conversation")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Button {
                            dismiss()
                        } label: {
                            Text("Back to Chats")
                                .font(.system(size: ViewHelper.buttonTextSize, weight: .bold))
                                .foregroundColor(ViewHelper.textImportant)
                                .frame(width: ViewHelper.buttonWidth, height: ViewHelper.buttonHeight)
                                .background(ViewHelper.accentBlue)
                                .cornerRadius(ViewHelper.componentRounding)
                        }
                        .padding(.top, ViewHelper.biggerSpacing)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else if viewModel.isLoading && viewModel.messages.isEmpty {
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
                    let latestOutgoingId = viewModel.latestOutgoingMessageId

                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            let meetingJSON = viewModel.getMeeting(body: message.body)
                            if !meetingJSON.isEmpty {
                                MeetingBubbleView(
                                    message: message,
                                    isCurrentUser: message.senderId == viewModel.currentUserId,
                                    json: meetingJSON,
                                    sessionManager: sessionManager,
                                    messagingRepository: messagingRepository
                                )
                            } else {
                                MessageBubbleView(
                                    message: message,
                                    isCurrentUser: message.senderId == viewModel.currentUserId,
                                    isLatestOutgoing: message.id == latestOutgoingId,
                                    conversationType: conversation.conversationType
                                )
                                .id(message.id)
                            }
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
            NavigationLink(destination: CreateMeetingView(
                navigationActive: $navigationActive,
                sessionManager: sessionManager,
                conversationID: conversation.id,
                messagingRepository: messagingRepository
            ), isActive: $navigationActive) {
                Image(systemName: "plus")
                    .font(.system(size: 32))
                    .foregroundColor(ViewHelper.textImportant)
            }
            
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
        .disabled(viewModel.isForbidden)
        .opacity(viewModel.isForbidden ? 0.5 : 1.0)
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

    private func pollForNewMessages() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { break }
            await viewModel.refreshMessages(conversationId: conversation.id)
            guard !viewModel.isForbidden else { break }
            try? await messagingRepository.markDelivered(conversationId: conversation.id)
        }
    }
}
