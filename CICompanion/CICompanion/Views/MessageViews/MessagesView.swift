//
//  MessagesView.swift
//  CICompanion
//

import SwiftUI

struct MessagesView: View {

    @StateObject var viewModel: ConversationsViewModel
    @StateObject private var contactsViewModel: ContactsViewModel
    @ObservedObject var sessionManager: SessionManager
    let messagingRepository: MessagingRepositoryProtocol
    let courseRepository: CourseRepositoryProtocol
    let studentRepository: StudentRepositoryProtocol

    @State private var showNewChat = false
    @State private var showNewGroup = false
    @State private var showAddContact = false
    @State private var showSignIn = false
    @State private var navigationPath = NavigationPath()
    @State private var mode: MessagesMode = .chats

    @State private var selectedParticipant: SelectedParticipant?

    private let bgColor = Color(red: 0.08, green: 0.10, blue: 0.15)
    private let cardColor = Color(red: 0.12, green: 0.14, blue: 0.20)
    private let accentBar = Color(red: 0.6, green: 0.8, blue: 1.0)
    private let buttonBlue = Color(red: 0.36, green: 0.55, blue: 0.90)

    private let pollIntervalSeconds: Int = 3
    private let pillIconSize: CGFloat = 9
    private let pillTextSize: CGFloat = 11
    private let pillIconTextSpacing: CGFloat = 4
    private let pillHorizontalPadding: CGFloat = 8
    private let pillVerticalPadding: CGFloat = 3
    private let pillStrokeOpacity: Double = 0.7
    private let unreadBadgeTextSize: CGFloat = 11

    init(
        viewModel: ConversationsViewModel,
        studentRepository: StudentRepositoryProtocol,
        messagingRepository: MessagingRepositoryProtocol,
        courseRepository: CourseRepositoryProtocol,
        sessionManager: SessionManager
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _contactsViewModel = StateObject(
            wrappedValue: ContactsViewModel(studentRepository: studentRepository)
        )
        self.messagingRepository = messagingRepository
        self.sessionManager = sessionManager
        self.courseRepository = courseRepository
        self.studentRepository = studentRepository
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
                        currentUserId: sessionManager.userId ?? ""
                    ),
                    conversation: conversation,
                    sessionManager: sessionManager,
                    messagingRepository: messagingRepository,
                    courseRepository: courseRepository,
                    contacts: contactsViewModel.contacts,
                    studentRepository: studentRepository
                )
            }
        }
        .task(id: sessionManager.isSignedIn) {
            if sessionManager.isSignedIn {
                viewModel.loadConversations()
                await contactsViewModel.loadContacts()
                // Background poll so new groups, removals, and incoming messages appear without manual refresh.
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(pollIntervalSeconds))
                    guard !Task.isCancelled, sessionManager.isSignedIn else { break }
                    await viewModel.refreshConversationsSilently()
                }
            } else {
                viewModel.conversations = []
                viewModel.errorMessage = nil
                contactsViewModel.reset()
                mode = .chats
            }
        }
        .onChange(of: mode) { _, newValue in
            guard sessionManager.isSignedIn, newValue == .contacts else { return }

            Task {
                await contactsViewModel.loadContacts()
            }
        }
        .sheet(isPresented: $showNewChat) {
            NewChatView(
                contacts: contactsViewModel.contacts,
                messagingRepository: messagingRepository,
                onConversationCreated: { conversation in
                    viewModel.loadConversations()
                    navigationPath.append(conversation)
                }
            )
        }
        .sheet(isPresented: $showNewGroup) {
            NewGroupView(
                contacts: contactsViewModel.contacts,
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
        .sheet(item: $selectedParticipant) { participant in
            ContactInformation(
                messagingRepository: messagingRepository,
                courseRepository: APICourseRepository(studentRepository: StudentRepository()),
                participantId: participant.id
            )
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
                                Label("New Direct Chat", systemImage: "bubble.left.fill")
                            }

                            Button {
                                showNewGroup = true
                            } label: {
                                Label("New Group Chat", systemImage: "person.3.fill")
                            }
                            .disabled(contactsViewModel.contacts.count < 2)
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
                        viewModel.markConversationReadLocally(conversationId: conversation.id)
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

                    if conversation.isGroup {
                        HStack(spacing: pillIconTextSpacing) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: pillIconSize, weight: .semibold))
                            Text("Group")
                                .font(.system(size: pillTextSize, weight: .semibold))
                        }
                        .foregroundColor(accentBar)
                        .padding(.horizontal, pillHorizontalPadding)
                        .padding(.vertical, pillVerticalPadding)
                        .background(
                            Capsule()
                                .stroke(accentBar.opacity(pillStrokeOpacity), lineWidth: 1)
                        )
                    } else if let directOtherId = conversation.otherParticipant?.id,
                              contactsViewModel.isContact(studentId: directOtherId) {
                        Text("Contact")
                            .font(.system(size: pillTextSize, weight: .semibold))
                            .foregroundColor(accentBar)
                            .padding(.horizontal, pillHorizontalPadding)
                            .padding(.vertical, pillVerticalPadding)
                            .background(
                                Capsule()
                                    .stroke(accentBar.opacity(pillStrokeOpacity), lineWidth: 1)
                            )
                    }
                }

                Text(previewText(for: conversation))
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let timeString = conversation.lastMessageAt {
                    Text(relativeTime(from: timeString))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                let count = viewModel.unreadCount(for: conversation)
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: unreadBadgeTextSize, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, pillHorizontalPadding)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(buttonBlue))
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
                Button {
                    selectedParticipant = SelectedParticipant(id: contact.id)
                } label: {
                    Text(contact.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                Text(contact.email)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            Button("Remove") {
                Task {
                    let removedId = contact.id
                    await contactsViewModel.removeContact(contactStudentId: removedId)
                    // Optimistically drop any direct chat with this contact while the network refresh is in flight,
                    // so the user can't tap a stale row and immediately hit a 403 from the archived conversation.
                    viewModel.conversations.removeAll {
                        $0.otherParticipant?.id == removedId
                    }
                    // Backend also archives direct chats and drops the contact from any groups we admin,
                    // so a full refresh is still needed for groups.
                    viewModel.loadConversations()
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
        
        if let meetingScheduler = messagingRepository.getMeeting(body: preview) {
            return "Scheduling a meeting: \(meetingScheduler.title)"
        } else if let proposal = messagingRepository.getMeetingProposal(body: preview) {
            return "Proposing a time for: \(proposal.title)"
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

private struct SelectedParticipant: Identifiable {
    let id: String
}
