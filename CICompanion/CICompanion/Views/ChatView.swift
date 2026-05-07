//
//  ChatView.swift
//  CICompanion
//

import SwiftUI
internal import ClientRuntime

struct ChatView: View {
    @State var navigationActive = false

    @StateObject var viewModel: ChatViewModel
    let conversation: Conversation
    let onConversationUpdated: () -> Void
    var sessionManager : SessionManager
    var messagingRepository : MessagingRepositoryProtocol
    let courseRepository : CourseRepositoryProtocol
    let contacts: [ContactStudent]
    let studentRepository: StudentRepositoryProtocol
    let targetMessageId: Int?

    @Environment(\.dismiss) private var dismiss
    @State private var showGroupInfo = false
    @State private var showMeetings = false
    @State private var hasScrolledToTarget = false
    @State private var highlightedMessageId: Int?
    // Set when we want ChatView itself to pop AFTER GroupInfoView's sheet finishes its dismiss animation.
    // Prevents popping the navigation stack while a sheet is mid-animation (which can leave an orphan sheet).
    @State private var pendingDismiss = false

    private let bgColor = Color(red: 0.08, green: 0.10, blue: 0.15)
    private let inputBgColor = Color(red: 0.12, green: 0.14, blue: 0.20)
    private let accentBlue = Color(red: 0.6, green: 0.8, blue: 1.0)

    private let errorBannerHorizontalPadding: CGFloat = 14
    private let errorBannerVerticalPadding: CGFloat = 8
    private let errorBannerBackgroundOpacity: Double = 0.85
    private let pollIntervalSeconds: Int = 1

    init(
        viewModel: ChatViewModel,
        conversation: Conversation,
        sessionManager: SessionManager,
        messagingRepository: MessagingRepositoryProtocol,
        courseRepository: CourseRepositoryProtocol,
        contacts: [ContactStudent],
        studentRepository: StudentRepositoryProtocol,
        targetMessageId: Int? = nil,
        onConversationUpdated: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.conversation = conversation
        self.sessionManager = sessionManager
        self.messagingRepository = messagingRepository
        self.courseRepository = courseRepository
        self.contacts = contacts
        self.studentRepository = studentRepository
        self.targetMessageId = targetMessageId
        self.onConversationUpdated = onConversationUpdated
    }

    // Prefer the freshest snapshot from loadMessages — it carries up-to-date participants/admin info.
    private var activeConversation: Conversation {
        viewModel.loadedConversation ?? conversation
    }

    var body: some View {
        VStack(spacing: 0) {
            messageList
            errorBanner
            inputBar
        }
        .background(bgColor)
        .navigationTitle(activeConversation.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task {
            viewModel.loadMessages(conversationId: conversation.id)
        }
        .task(id: "poll-\(conversation.id)") {
            await pollForNewMessages()
        }
        .onChange(of: viewModel.successfulSendCount) { _, newValue in
            guard newValue > 0 else { return }
            onConversationUpdated()
        }
        .alert("Conversation unavailable", isPresented: $viewModel.accessRevoked) {
            Button("OK") {
                // If GroupInfoView is open, close it first and let onDismiss pop the stack
                // — popping while a sheet is presented would orphan the sheet.
                if showGroupInfo {
                    pendingDismiss = true
                    showGroupInfo = false
                } else {
                    dismiss()
                }
            }
        } message: {
            Text(viewModel.accessRevokedMessage ?? "You no longer have access to this conversation.")
        }
        .toolbar {
            if activeConversation.isGroup {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showGroupInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(.white)
                    }
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showMeetings = true
                } label: {
                    Image(systemName: "calendar")
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(
            isPresented: $showGroupInfo,
            onDismiss: {
                if pendingDismiss {
                    pendingDismiss = false
                    dismiss()
                }
            }
        ) {
            GroupInfoView(
                conversation: activeConversation,
                currentUserId: viewModel.currentUserId,
                contacts: contacts,
                messagingRepository: messagingRepository,
                onConversationChanged: {
                    await viewModel.refreshMessages(conversationId: conversation.id)
                },
                onLeft: {
                    pendingDismiss = true
                }
            )
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
                            messageRow(message)
                                .id(message.id)
                                .padding(.vertical, highlightedMessageId == message.id ? 3 : 0)
                                .background(highlightBackground(for: message))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
            .refreshable {
                await viewModel.refreshMessages(conversationId: conversation.id)
                _ = scrollToTargetIfNeeded(proxy: proxy)
            }
            .onChange(of: viewModel.messages.count) { _ in
                if scrollToTargetIfNeeded(proxy: proxy) { return }
                scrollToBottom(proxy: proxy)
            }
            .sheet(isPresented: $showMeetings) {
                ScrollView {
                    CIPageTitle("Previous meetings")
                    ForEach(viewModel.messages) { message in
                        if let meetingScheduler = messagingRepository.getMeeting(body: message.body) {
                            MeetingBubbleView(message: message, isCurrentUser: message.senderId == viewModel.currentUserId, meetingScheduler: meetingScheduler, sessionManager: sessionManager, messagingRepository: messagingRepository, courseRepository: courseRepository, conversation: conversation, studentRepository: studentRepository)
                                .onTapGesture {
                                    showMeetings = false
                                    proxy.scrollTo(message.id, anchor: .center)
                                }
                        }
                    }
                    Spacer()
                }.padding(ViewHelper.padding)
            }
        }
    }

    @ViewBuilder
    private func messageRow(_ message: Message) -> some View {
        if let prop = messagingRepository.getMeetingProposal(body: message.body) {
            MeetingProposalBubbleView(
                message: message,
                isCurrentUser: message.senderId == viewModel.currentUserId,
                proposal: prop,
                sessionManager: sessionManager,
                messagingRepository: messagingRepository,
                courseRepository: courseRepository,
                conversation: conversation,
                studentRepository: studentRepository
            )
        } else if let meetingScheduler = messagingRepository.getMeeting(body: message.body) {
            MeetingBubbleView(
                message: message,
                isCurrentUser: message.senderId == viewModel.currentUserId,
                meetingScheduler: meetingScheduler,
                sessionManager: sessionManager,
                messagingRepository: messagingRepository,
                courseRepository: courseRepository,
                conversation: conversation, studentRepository: studentRepository
            )
        } else {
            MessageBubbleView(
                message: message,
                isCurrentUser: message.senderId == viewModel.currentUserId,
                showSenderName: shouldShowSenderName(for: message),
                receiptText: receiptText(for: message)
            )
        }
    }

    @ViewBuilder
    private func highlightBackground(for message: Message) -> some View {
        if highlightedMessageId == message.id {
            RoundedRectangle(cornerRadius: ViewHelper.componentRounding)
                .fill(accentBlue.opacity(0.18))
        }
    }

    @ViewBuilder
    private var errorBanner: some View {
        if let errorMessage = viewModel.errorMessage {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text(errorMessage)
                    .lineLimit(2)
                Spacer()
                Button {
                    viewModel.clearErrorMessage()
                } label: {
                    Image(systemName: "xmark")
                }
                .foregroundColor(.white)
            }
            .font(.system(size: ViewHelper.metaTextSize, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, errorBannerHorizontalPadding)
            .padding(.vertical, errorBannerVerticalPadding)
            .background(Color.red.opacity(errorBannerBackgroundOpacity))
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            NavigationLink(destination: CreateMeetingView(
                navigationActive: $navigationActive,
                sessionManager: sessionManager,
                conversationID: conversation.id,
                messagingRepository: messagingRepository,
                courseRepository: courseRepository
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

    private func scrollToTargetIfNeeded(proxy: ScrollViewProxy) -> Bool {
        guard let targetMessageId, !hasScrolledToTarget else { return false }
        guard viewModel.messages.contains(where: { $0.id == targetMessageId }) else { return false }

        hasScrolledToTarget = true
        highlightedMessageId = targetMessageId

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(targetMessageId, anchor: .center)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if highlightedMessageId == targetMessageId {
                highlightedMessageId = nil
            }
        }

        return true
    }

    private func shouldShowSenderName(for message: Message) -> Bool {
        activeConversation.isGroup && message.senderId != viewModel.currentUserId
    }

    private func receiptText(for message: Message) -> String? {
        guard message.senderId == viewModel.currentUserId else { return nil }
        guard message.id == lastOutgoingMessageId else { return nil }

        if activeConversation.isGroup {
            return groupReceiptText(for: message)
        }
        return directReceiptText(for: message)
    }

    private var lastOutgoingMessageId: Int? {
        viewModel.messages.last(where: { $0.senderId == viewModel.currentUserId })?.id
    }

    private func directReceiptText(for message: Message) -> String {
        switch message.deliveryStatus {
        case "seen":
            return "Seen"
        case "delivered":
            return "Delivered"
        default:
            // Includes "sent" and the null case for an own outgoing message that has no recipient receipt yet.
            return "Sent"
        }
    }

    private func groupReceiptText(for message: Message) -> String? {
        let readers = message.readBy ?? []
        // No readers yet = "Sent" (matches the direct-chat treatment of an own outgoing message
        // that hasn't reached anyone). Avoids leaving the bubble visually orphaned.
        if readers.isEmpty {
            return "Sent"
        }
        // Always list reader names. "Read by all" was unreliable when membership changed mid-conversation
        // (old messages keep receipts from removed members, so the count comparison drifted).
        let names = readers.map(\.name).joined(separator: ", ")
        return "Read by \(names)"
    }

    // Polls for new messages every 5 seconds while this view is on screen.
    // SwiftUI cancels this .task automatically when the view disappears.
    private func pollForNewMessages() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(pollIntervalSeconds))
            guard !Task.isCancelled else { break }
            await viewModel.refreshMessages(conversationId: conversation.id)
        }
    }
}
