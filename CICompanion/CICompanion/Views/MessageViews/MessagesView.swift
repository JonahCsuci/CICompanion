//
//  MessagesView.swift
//  CICompanion
//

import SwiftUI

private enum MessagesViewFormatters {
    static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let iso8601: ISO8601DateFormatter = ISO8601DateFormatter()

    static let relative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
}

struct MessagesView: View {

    @StateObject var viewModel: ConversationsViewModel
    @ObservedObject var contactsViewModel: ContactsViewModel
    @ObservedObject var sessionManager: SessionManager
    let messagingRepository: MessagingRepositoryProtocol

    @State private var showNewChat = false
    @State private var showNewGroup = false
    @State private var showAddContact = false
    @State private var showSignIn = false
    @State private var navigationPath = NavigationPath()
    @State private var mode: MessagesMode = .chats

    private let bgColor = Color(red: 0.08, green: 0.10, blue: 0.15)
    private let cardColor = Color(red: 0.12, green: 0.14, blue: 0.20)
    private let accentBar = Color(red: 0.6, green: 0.8, blue: 1.0)
    private let buttonBlue = Color(red: 0.36, green: 0.55, blue: 0.90)

    init(
        viewModel: ConversationsViewModel,
        contactsViewModel: ContactsViewModel,
        messagingRepository: MessagingRepositoryProtocol,
        sessionManager: SessionManager
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.contactsViewModel = contactsViewModel
        self.messagingRepository = messagingRepository
        self.sessionManager = sessionManager
    }
    
    private var modePicker: some View {
        HStack(spacing: 8) {
            ForEach(MessagesMode.allCases) { item in
                Button {
                    mode = item
                } label: {
                    Text(item.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(mode == item ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(mode == item ? buttonBlue : cardColor)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardColor.opacity(0.8))
        )
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
                        modeContent
                    }
                }
            }
            .navigationDestination(for: Conversation.self) { conversation in
                ChatView(
                    viewModel: ChatViewModel(
                        messagingRepository: messagingRepository,
                        currentUserId: sessionManager.userId ?? "",
                        onMessageSent: { [weak viewModel] in
                            viewModel?.loadConversations()
                        }
                    ),
                    conversation: conversation,
                    sessionManager: sessionManager,
                    messagingRepository: messagingRepository,
                    contactsViewModel: contactsViewModel
                )
            }
        }
        .task(id: sessionManager.isSignedIn) {
            if sessionManager.isSignedIn {
                viewModel.loadConversations()
                await contactsViewModel.loadContacts()
            } else {
                viewModel.conversations = []
                viewModel.errorMessage = nil
                contactsViewModel.reset()
                mode = .chats
            }
        }
        .task(id: sessionManager.isSignedIn) {
            guard sessionManager.isSignedIn else { return }
            await pollConversations()
        }
        .onChange(of: mode) { _, newValue in
            guard sessionManager.isSignedIn, newValue == .contacts else { return }

            Task {
                await contactsViewModel.loadContacts()
            }
        }
        .sheet(isPresented: $showNewChat) {
            NewChatView(
                contactsViewModel: contactsViewModel,
                messagingRepository: messagingRepository,
                onConversationCreated: { conversation in
                    viewModel.loadConversations()
                    navigationPath.append(conversation)
                }
            )
        }
        .sheet(isPresented: $showNewGroup) {
            NewGroupView(
                contactsViewModel: contactsViewModel,
                messagingRepository: messagingRepository,
                onGroupCreated: { conversation in
                    viewModel.loadConversations()
                    navigationPath.append(conversation)
                }
            )
        }
        .sheet(isPresented: $showAddContact) {
            AddContactSheet(
                contactsViewModel: contactsViewModel,
                cardColor: cardColor,
                buttonBlue: buttonBlue
            )
        }
        .sheet(isPresented: $showSignIn) {
            SignInView(sessionManager: sessionManager)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Messages")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                if sessionManager.isSignedIn {
                    if mode == .chats {
                        Menu {
                            Button {
                                showNewChat = true
                            } label: {
                                Label("New Chat", systemImage: "message")
                            }

                            Button {
                                showNewGroup = true
                            } label: {
                                Label("New Group", systemImage: "person.3")
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    } else {
                        Button {
                            contactsViewModel.clearError()
                            showAddContact = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }

            modePicker
                .disabled(!sessionManager.isSignedIn)
                .opacity(sessionManager.isSignedIn ? 1 : 0.5)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    private var signInPrompt: some View {
        VStack {
            Spacer()
                .frame(height: 50)

            Text("Sign in to view your messages and contacts")
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

    private var modeContent: some View {
        Group {
            if mode == .chats {
                conversationContent
            } else {
                contactsContent
            }
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
                emptyChatsState
            } else {
                conversationList
            }
        }
    }

    private var emptyChatsState: some View {
        VStack(spacing: 16) {
            Spacer()

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            } else {
                Text("No conversations yet")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
            }

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

    private var contactsContent: some View {
        Group {
            if contactsViewModel.isLoading && contactsViewModel.contacts.isEmpty {
                Spacer()
                ProgressView()
                    .tint(.white)
                Spacer()
            } else if contactsViewModel.contacts.isEmpty {
                emptyContactsState
            } else {
                contactsList
            }
        }
    }

    private var emptyContactsState: some View {
        VStack(spacing: 16) {
            Spacer()

            if let errorMessage = contactsViewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            } else {
                Text("No contacts yet")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
            }

            Button {
                contactsViewModel.clearError()
                showAddContact = true
            } label: {
                Text("Add a Contact")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 180, height: 44)
                    .background(buttonBlue)
                    .cornerRadius(8)
            }

            Spacer()
        }
    }

    private var conversationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.conversations) { conversation in
                    Button {
                        navigationPath.append(conversation)
                    } label: {
                        conversationRow(conversation)
                    }
                }
            }
        }
        .refreshable {
            viewModel.loadConversations()
        }
    }

    private var contactsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if let errorMessage = contactsViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }

                ForEach(contactsViewModel.contacts) { contact in
                    contactRow(contact)
                }
            }
        }
        .refreshable {
            await contactsViewModel.loadContacts()
        }
    }

    private func conversationRow(_ conversation: Conversation) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accentBar)
                .frame(width: 4, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(conversation.displayTitle)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if !conversation.isGroup,
                       let otherParticipant = conversation.otherParticipant,
                       contactsViewModel.isContact(studentId: otherParticipant.id) {
                        Text("Contact")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(accentBar)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .stroke(accentBar.opacity(0.7), lineWidth: 1)
                            )
                    }
                }

                HStack(spacing: 6) {
                    Text(previewText(for: conversation))
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(1)

                    if conversation.isGroup, let participants = conversation.participants {
                        Text("•")
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("\(participants.count) members")
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let timeString = conversation.lastMessageAt {
                    Text(relativeTime(from: timeString))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                if let unreadCount = conversation.unreadCount, unreadCount > 0 {
                    ZStack {
                        Circle()
                            .fill(buttonBlue)
                            .frame(width: 20, height: 20)

                        Text("\(min(unreadCount, 99))")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func contactRow(_ contact: ContactStudent) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accentBar)
                .frame(width: 4, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(contact.email)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            Button("Remove") {
                Task {
                    await contactsViewModel.removeContact(contactStudentId: contact.id)
                }
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .disabled(contactsViewModel.isMutating)
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
        let date = MessagesViewFormatters.iso8601WithFractionalSeconds.date(from: isoString)
            ?? MessagesViewFormatters.iso8601.date(from: isoString)
        guard let date else { return "" }
        return MessagesViewFormatters.relative.localizedString(for: date, relativeTo: Date())
    }

    private func pollConversations() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { break }
            guard sessionManager.isSignedIn else { break }
            viewModel.loadConversations()
        }
    }
}

private enum MessagesMode: String, CaseIterable, Identifiable {
    case chats
    case contacts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chats:
            return "Chats"
        case .contacts:
            return "Contacts"
        }
    }
}

private struct AddContactSheet: View {

    @ObservedObject var contactsViewModel: ContactsViewModel
    let cardColor: Color
    let buttonBlue: Color

    @Environment(\.dismiss) private var dismiss
    @State private var email = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.10, blue: 0.15)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Add Contact")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    CITextField(placeholder: "Email", text: $email, lines: 1)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)

                    if let errorMessage = contactsViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }

                    Button {
                        Task {
                            let added = await contactsViewModel.addContact(email: email)
                            if added {
                                dismiss()
                            }
                        }
                    } label: {
                        if contactsViewModel.isMutating {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        } else {
                            Text("Add Contact")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                    }
                    .background(buttonBlue)
                    .cornerRadius(8)
                    .disabled(contactsViewModel.isMutating)

                    Spacer()
                }
                .padding(20)
                .padding(16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                contactsViewModel.clearError()
            }
        }
        .preferredColorScheme(.dark)
    }
}
