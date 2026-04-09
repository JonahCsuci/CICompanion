//
//  MessagesView.swift
//  CICompanion
//

import SwiftUI

struct MessagesView: View {
    
    @StateObject var viewModel: ConversationsViewModel
    @ObservedObject var sessionManager: SessionManager
    
    let messagingRepository: MessagingRepositoryProtocol
    let studentRepository: StudentRepositoryProtocol
    let courseRepository: CourseRepositoryProtocol
    
    @State private var showNewChat = false
    @State private var showSignIn = false
    @State private var navigationPath = NavigationPath()
    @State private var selectedConversationForParticipant: Conversation?
    
    private let bgColor = Color(red: 0.08, green: 0.10, blue: 0.15)
    private let accentBar = Color(red: 0.6, green: 0.8, blue: 1.0)
    private let buttonBlue = Color(red: 0.36, green: 0.55, blue: 0.90)
    
    init(
        viewModel: ConversationsViewModel,
        messagingRepository: MessagingRepositoryProtocol,
        sessionManager: SessionManager,
        studentRepository: StudentRepositoryProtocol,
        courseRepository: CourseRepositoryProtocol
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.messagingRepository = messagingRepository
        self.sessionManager = sessionManager
        self.studentRepository = studentRepository
        self.courseRepository = courseRepository
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                bgColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    header
                    
                    if !sessionManager.isSignedIn {
                        signInPrompt
                    } else {
                        conversationContent
                    }
                }
            }
            .navigationDestination(for: Conversation.self) { conversation in
                ChatView(
                    viewModel: ChatViewModel(
                        messagingRepository: messagingRepository,
                        currentUserId: sessionManager.userId ?? ""
                    ),
                    conversation: conversation,
                    sessionManager: sessionManager,
                    messagingRepository: messagingRepository
                )
            }
        }
        .task(id: sessionManager.isSignedIn) {
            if sessionManager.isSignedIn {
                viewModel.loadConversations()
            } else {
                viewModel.conversations = []
                viewModel.errorMessage = nil
            }
        }
        .sheet(isPresented: $showNewChat) {
            NewChatView(
                messagingRepository: messagingRepository,
                onConversationCreated: { conversation in
                    viewModel.loadConversations()
                    navigationPath.append(conversation)
                }
            )
        }
        .sheet(isPresented: $showSignIn) {
            SignInView(sessionManager: sessionManager)
        }
        .sheet(item: $selectedConversationForParticipant) { conversation in
            ContactInformation(
                messagingRepository: messagingRepository,
                courseRepository: courseRepository,
                participantId: conversation.otherParticipant.id
            )
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Messages")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            HStack {
                Text("Chats")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if sessionManager.isSignedIn {
                    Button {
                        showNewChat = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }
    
    private var signInPrompt: some View {
        VStack {
            Spacer()
                .frame(height: 50)
            
            Text("Sign in to view your messages")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Button {
                showSignIn = true
            } label: {
                Text("Sign In")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(buttonBlue)
                    .cornerRadius(12)
            }
            
            Spacer()
        }
    }
    
    private var conversationContent: some View {
        Group {
            if viewModel.isLoading && viewModel.conversations.isEmpty {
                Spacer()
                ProgressView()
                    .tint(.white)
                Spacer()
            } else if viewModel.conversations.isEmpty {
                emptyState
            } else {
                conversationList
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Text("No conversations yet")
                .font(.system(size: 18))
                .foregroundColor(.gray)
            
            Button {
                showNewChat = true
            } label: {
                Text("Start a Chat")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 180, height: 44)
                    .background(buttonBlue)
                    .cornerRadius(10)
            }
            
            Spacer()
        }
    }
    
    private var conversationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.conversations) { conversation in
                    conversationRow(conversation)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            navigationPath.append(conversation)
                        }
                }
            }
        }
        .refreshable {
            viewModel.loadConversations()
        }
    }
    
    private func conversationRow(_ conversation: Conversation) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accentBar)
                .frame(width: 4, height: 44)
            
            VStack(alignment: .leading, spacing: 4) {
                Button {
                    selectedConversationForParticipant = conversation
                } label: {
                    Text(conversation.otherParticipant.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
                
                Text(previewText(for: conversation))
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if let timeString = conversation.lastMessageAt {
                Text(relativeTime(from: timeString))
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func previewText(for conversation: Conversation) -> String {
        guard let preview = conversation.lastMessagePreview, !preview.isEmpty else {
            return "No messages yet"
        }
        return preview
    }
    
    private func relativeTime(from isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: isoString)
                ?? ISO8601DateFormatter().date(from: isoString) else {
            return ""
        }
        
        let relative = RelativeDateTimeFormatter()
        relative.unitsStyle = .abbreviated
        return relative.localizedString(for: date, relativeTo: Date())
    }
}
