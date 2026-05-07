//
//  MessagesView.swift
//  CICompanion
//

import SwiftUI

struct MessagesView: View {

    @StateObject var viewModel: ConversationsViewModel
    @StateObject private var contactsViewModel: ContactsViewModel
    @ObservedObject var contactRequestsViewModel: ContactRequestsViewModel
    @ObservedObject private var tutorViewModel: TutorViewModel
    @ObservedObject var sessionManager: SessionManager
    let messagingRepository: MessagingRepositoryProtocol
    let courseRepository: CourseRepositoryProtocol
    let studentRepository: StudentRepositoryProtocol

    @State private var showNewChat = false
    @State private var showNewGroup = false
    @State private var showAddContact = false
    @State private var showSignIn = false
    @State private var showSettings = false
    @State private var navigationPath = NavigationPath()
    @State private var mode: MessagesMode = .chats

    @State private var selectedParticipant: SelectedParticipant?
    @State private var postAcceptToast: String?
    @State private var postAcceptToastTask: Task<Void, Never>?
    @State private var showDeleteDialogFor: Int?

    private let bgColor = ViewHelper.bgColor
    private let cardColor = ViewHelper.fieldBgColor
    private let accentBar = ViewHelper.accentBlue
    private let buttonBlue = ViewHelper.accentBlue

    private let pillIconSize: CGFloat = 9
    private let pillIconTextSpacing: CGFloat = 4
    private let pillHorizontalPadding: CGFloat = 8
    private let pillVerticalPadding: CGFloat = 3
    private let pillStrokeOpacity: Double = 0.7

    init(
        viewModel: ConversationsViewModel,
        studentRepository: StudentRepositoryProtocol,
        messagingRepository: MessagingRepositoryProtocol,
        courseRepository: CourseRepositoryProtocol,
        sessionManager: SessionManager,
        tutorViewModel: TutorViewModel,
        contactRequestsViewModel: ContactRequestsViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _contactsViewModel = StateObject(
            wrappedValue: ContactsViewModel(studentRepository: studentRepository)
        )
        self.contactRequestsViewModel = contactRequestsViewModel
        self.messagingRepository = messagingRepository
        self.sessionManager = sessionManager
        self.courseRepository = courseRepository
        self.studentRepository = studentRepository
        self.tutorViewModel = tutorViewModel
    }

    private var searchBinding: Binding<String> {
        Binding(
            get: { viewModel.searchQuery },
            set: { viewModel.updateSearchQuery($0) }
        )
    }

    private var searchFeedbackText: String? {
        if let searchErrorMessage = viewModel.searchErrorMessage {
            return searchErrorMessage
        }

        if viewModel.shouldShowShortSearchHint {
            return "Type at least 3 characters"
        }

        return nil
    }
    
    private var modePicker: some View {
        HStack(spacing: 8) {
            ForEach(MessagesMode.allCases) { item in
                Button {
                    mode = item
                } label: {
                    HStack(spacing: 6) {
                        Text(item.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(mode == item ? .white : .gray)

                        if item == .contacts, contactRequestsViewModel.incomingPendingCount > 0 {
                            Text("\(contactRequestsViewModel.incomingPendingCount)")
                                .font(.system(size: ViewHelper.pillTextSize, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(ViewHelper.accentDarkBlue))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: ViewHelper.componentRounding)
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
                    studentRepository: studentRepository,
                    onConversationUpdated: {
                        viewModel.loadConversations()
                    },
                    onAccessRevokedDismiss: {
                        Task { await viewModel.refreshConversationsSilently() }
                    }
                )
            }
            .navigationDestination(for: MeetingNavigationTarget.self) { target in
                ChatView(
                    viewModel: ChatViewModel(
                        messagingRepository: messagingRepository,
                        currentUserId: sessionManager.userId ?? ""
                    ),
                    conversation: target.conversation,
                    sessionManager: sessionManager,
                    messagingRepository: messagingRepository,
                    courseRepository: courseRepository,
                    contacts: contactsViewModel.contacts,
                    studentRepository: studentRepository,
                    targetMessageId: target.messageId,
                    onConversationUpdated: {
                        viewModel.loadConversations()
                    },
                    onAccessRevokedDismiss: {
                        Task { await viewModel.refreshConversationsSilently() }
                    }
                )
            }
        }
        .task(id: sessionManager.isSignedIn) {
            if sessionManager.isSignedIn {
                viewModel.loadConversations()
                await contactsViewModel.loadContacts()
                await contactRequestsViewModel.loadRequests()

                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(ViewHelper.pollIntervalSeconds))
                    guard !Task.isCancelled, sessionManager.isSignedIn else { break }
                    await viewModel.refreshConversationsSilently()
                }
            } else {
                viewModel.conversations = []
                viewModel.displayedConversations = []
                viewModel.errorMessage = nil
                viewModel.clearSearch()
                contactsViewModel.reset()
                mode = .chats
            }
        }
        .onChange(of: mode) { _, newValue in
            guard sessionManager.isSignedIn, newValue == .contacts else { return }

            Task {
                async let contacts: () = contactsViewModel.loadContacts()
                async let requests: () = contactRequestsViewModel.loadRequests()
                _ = await (contacts, requests)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeContactsRefresh)) { _ in
            Task { await contactsViewModel.refreshSilently() }
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
                contactRequestsViewModel: contactRequestsViewModel,
                sessionManager: sessionManager,
                studentRepository: studentRepository,
                messagingRepository: messagingRepository,
                cardColor: cardColor,
                buttonBlue: buttonBlue
            )
        }
        .sheet(isPresented: $showSignIn) {
            SignInView(sessionManager: sessionManager)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                courseRepository: courseRepository,
                studentRepository: studentRepository,
                tutorViewModel: tutorViewModel,
                sessionManager: sessionManager
            )
        }
        .sheet(item: $selectedParticipant) { participant in
            ContactInformation(
                messagingRepository: messagingRepository,
                courseRepository: APICourseRepository(studentRepository: StudentRepository()),
                participantId: participant.id,
                currentStudentId: sessionManager.userId
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: ViewHelper.navIconSize, weight: .semibold))
                        .foregroundColor(ViewHelper.textImportant)
                        .frame(width: ViewHelper.navButtonSize, height: ViewHelper.navButtonSize)
                        .background(Circle().fill(cardColor))
                }
                .accessibilityLabel("Settings")

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

            if sessionManager.isSignedIn, mode == .chats {
                searchRow
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    private var searchRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                CITextField(
                    placeholder: "Search messages",
                    text: searchBinding,
                    lines: 1
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                if !viewModel.trimmedSearchQuery.isEmpty {
                    CITextButton(text: "Clear") {
                        viewModel.clearSearch()
                    }
                }
            }

            if let searchFeedbackText {
                Text(searchFeedbackText)
                    .font(.system(size: 13))
                    .foregroundColor(viewModel.searchErrorMessage == nil ? .gray : .red)
            }
        }
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
                    .cornerRadius(ViewHelper.componentRounding)
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
            if viewModel.isLoading && !viewModel.hasDisplayedResults && viewModel.trimmedSearchQuery.isEmpty {
                Spacer()
                CILoadingPage()
                Spacer()
            } else if viewModel.isSearchActive && viewModel.isSearching && !viewModel.hasDisplayedResults {
                Spacer()
                CILoadingPage()
                Spacer()
            } else if viewModel.isSearchActive && !viewModel.hasDisplayedResults {
                emptySearchState
            } else if !viewModel.hasDisplayedResults {
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

                Button {
                    viewModel.loadConversations()
                } label: {
                    Text("Try Again")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 180, height: 44)
                        .background(buttonBlue)
                        .cornerRadius(ViewHelper.componentRounding)
                }
            } else {
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
                        .cornerRadius(ViewHelper.componentRounding)
                }
            }

            Spacer()
        }
    }

    private var emptySearchState: some View {
        VStack(spacing: 16) {
            Spacer()

            Text("No matching messages or meetings")
                .font(.system(size: 18))
                .foregroundColor(.gray)

            if !viewModel.trimmedSearchQuery.isEmpty {
                CITextButton(text: "Clear Search") {
                    viewModel.clearSearch()
                }
            }

            Spacer()
        }
    }

    private var contactsContent: some View {
        let allEmpty = contactsViewModel.contacts.isEmpty
            && contactRequestsViewModel.incoming.isEmpty
            && contactRequestsViewModel.outgoing.isEmpty
        let isInitialLoading = (contactsViewModel.isLoading || contactRequestsViewModel.isLoading) && allEmpty

        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if isInitialLoading {
                    CILoadingPage()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                } else {
                    if let combinedError = contactsViewModel.errorMessage ?? contactRequestsViewModel.errorMessage {
                        Text(combinedError)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                    }

                    if let postAcceptToast {
                        postAcceptToastView(postAcceptToast)
                    }

                    if !contactRequestsViewModel.incoming.isEmpty {
                        incomingRequestsSection
                    }

                    if !contactRequestsViewModel.outgoing.isEmpty {
                        sentPendingSection
                    }

                    contactsSection
                }
            }
            .padding(.bottom, 24)
        }
        .refreshable {
            // SwiftUI's `.refreshable` Task can get cancelled by the spinner
            // lifecycle / view body re-eval, which propagates to the URLSession
            // calls and aborts the refresh. Run the actual work in a detached
            // task so cancellation of the outer `.refreshable` task can't kill
            // the network round-trip — `await detached.value` is non-throwing
            // and waits even if the surrounding task is cancelled.
            let contactsVM = contactsViewModel
            let requestsVM = contactRequestsViewModel
            await Task.detached(priority: .userInitiated) { @MainActor in
                async let contacts: () = contactsVM.loadContacts()
                async let requests: () = requestsVM.loadRequests()
                _ = await (contacts, requests)
            }.value
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.gray)
            .textCase(.uppercase)
            .tracking(1)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 6)
    }

    private var incomingRequestsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Incoming")
            ForEach(contactRequestsViewModel.incoming) { request in
                incomingRequestRow(request)
            }
        }
    }

    private var sentPendingSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Sent · Pending")
            ForEach(contactRequestsViewModel.outgoing) { request in
                sentPendingRow(request)
            }
        }
    }

    private var contactsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Contacts")
            if contactsViewModel.contacts.isEmpty {
                Text("No contacts yet — search to add")
                    .font(.system(size: 14))
                    .foregroundColor(ViewHelper.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            } else {
                ForEach(contactsViewModel.contacts) { contact in
                    contactRow(contact)
                }
            }
        }
    }

    private func incomingRequestRow(_ request: ContactRequest) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accentBar)
                .frame(width: 4)
                .frame(maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 4) {
                Text(request.otherStudent?.name ?? "Unknown")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(request.otherStudent?.email ?? "")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)

                if contactRequestsViewModel.mutatingRequestIds.contains(request.requestId) {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .frame(height: 36)
                        .padding(.top, 4)
                } else {
                    HStack(spacing: 12) {
                        Button {
                            Task { await acceptRequest(request) }
                        } label: {
                            Text("Accept")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(buttonBlue)
                                .cornerRadius(ViewHelper.componentRounding)
                        }
                        .buttonStyle(.plain)

                        Button {
                            Task { await contactRequestsViewModel.decline(request.requestId) }
                        } label: {
                            Text("Decline")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(ViewHelper.accentRed)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(ViewHelper.accentRed.opacity(0.2))
                                .cornerRadius(ViewHelper.componentRounding)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func sentPendingRow(_ request: ContactRequest) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(ViewHelper.text)
                .frame(width: 4, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(request.otherStudent?.name ?? "Unknown")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(request.otherStudent?.email ?? "")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            if contactRequestsViewModel.mutatingRequestIds.contains(request.requestId) {
                ProgressView()
                    .tint(.white)
                    .frame(width: 80, height: 34)
            } else {
                Button {
                    Task { await contactRequestsViewModel.cancel(request.requestId) }
                } label: {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(ViewHelper.text)
                        .frame(width: 80, height: 34)
                        .background(ViewHelper.fieldBgColor)
                        .cornerRadius(ViewHelper.componentRounding)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func postAcceptToastView(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(ViewHelper.accentGreen)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ViewHelper.accentGreen.opacity(0.15))
            .cornerRadius(ViewHelper.componentRounding)
            .padding(.horizontal, 16)
            .padding(.top, 12)
    }

    private func acceptRequest(_ request: ContactRequest) async {
        let displayName = request.otherStudent?.name ?? "your contact"
        await contactRequestsViewModel.accept(request.requestId) { _ in
            await contactsViewModel.refreshSilently()
            await viewModel.refreshConversationsSilently()
            showPostAcceptToast(name: displayName)
        }
    }

    private func showPostAcceptToast(name: String) {
        postAcceptToast = "You and \(name) are now contacts. Send the first message to start the chat."
        postAcceptToastTask?.cancel()
        postAcceptToastTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            postAcceptToast = nil
        }
    }

    private func refreshContactsAndRequests() async {
        async let contacts: () = contactsViewModel.loadContacts()
        async let requests: () = contactRequestsViewModel.loadRequests()
        _ = await (contacts, requests)
    }

    private var conversationList: some View {
        List {
            if let searchErrorMessage = viewModel.searchErrorMessage, viewModel.isSearchActive {
                Text(searchErrorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .modifier(ConversationListRowAppearance())
            }

            if viewModel.isSearchActive {
                ForEach(viewModel.displayedSearchResults) { result in
                    searchResultRow(result)
                        .modifier(ConversationListRowAppearance())
                }
            } else {
                ForEach(viewModel.displayedConversations) { conversation in
                    conversationListRow(conversation)
                        .modifier(ConversationListRowAppearance())
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable {
            if viewModel.isSearchActive {
                viewModel.updateSearchQuery(viewModel.searchQuery)
            } else {
                viewModel.loadConversations()
            }
        }
        .alert(
            "Delete chat?",
            isPresented: deleteDialogPresentedBinding,
            presenting: showDeleteDialogFor
        ) { conversationId in
            Button("Cancel", role: .cancel) {
                showDeleteDialogFor = nil
            }
            Button("Delete", role: .destructive) {
                viewModel.hideConversation(conversationId: conversationId)
                showDeleteDialogFor = nil
            }
        } message: { _ in
            Text("Messages stay on the server but this conversation is hidden until someone messages it.")
        }
    }

    @ViewBuilder
    private func conversationListRow(_ conversation: Conversation) -> some View {
        let row = Button {
            viewModel.markConversationReadLocally(conversationId: conversation.id)
            navigationPath.append(conversation)
        } label: {
            conversationRow(conversation)
        }

        if conversation.isGroup {
            row
        } else {
            CISwipeable {
                Button(role: .destructive) {
                    showDeleteDialogFor = conversation.id
                } label: {
                    Label("Delete", systemImage: "trash.fill")
                }
            } content: {
                row
            }
        }
    }

    private var deleteDialogPresentedBinding: Binding<Bool> {
        Binding(
            get: { showDeleteDialogFor != nil },
            set: { newValue in
                if !newValue { showDeleteDialogFor = nil }
            }
        )
    }

    @ViewBuilder
    private func searchResultRow(_ result: MessageSearchResult) -> some View {
        switch result {
        case .conversation(let conversation):
            Button {
                viewModel.markConversationReadLocally(conversationId: conversation.id)
                navigationPath.append(conversation)
            } label: {
                conversationRow(conversation)
            }
        case .meeting(let meeting):
            Button {
                viewModel.markConversationReadLocally(conversationId: meeting.conversation.id)
                navigationPath.append(
                    MeetingNavigationTarget(
                        conversation: meeting.conversation,
                        messageId: meeting.messageId
                    )
                )
            } label: {
                meetingResultRow(meeting)
            }
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
                        let others = max(conversation.participantIds.count - 1, 0)
                        HStack(spacing: pillIconTextSpacing) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: pillIconSize, weight: .semibold))
                            Text("Group +\(others)")
                                .font(.system(size: ViewHelper.pillTextSize, weight: .semibold))
                        }
                        .foregroundColor(accentBar)
                        .padding(.horizontal, pillHorizontalPadding)
                        .padding(.vertical, pillVerticalPadding)
                        .background(
                            Capsule()
                                .stroke(accentBar.opacity(pillStrokeOpacity), lineWidth: 1)
                        )
                    } else if let otherParticipant = conversation.otherParticipant,
                              contactsViewModel.isContact(studentId: otherParticipant.id) {
                        Text("Contact")
                            .font(.system(size: ViewHelper.pillTextSize, weight: .semibold))
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
                        .font(.system(size: ViewHelper.pillTextSize, weight: .bold))
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

    private func meetingResultRow(_ meeting: MeetingSearchResult) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(ViewHelper.accentPurple)
                .frame(width: 4, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(meeting.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text("Meeting")
                        .font(.system(size: ViewHelper.pillTextSize, weight: .semibold))
                        .foregroundColor(ViewHelper.accentPurple)
                        .padding(.horizontal, pillHorizontalPadding)
                        .padding(.vertical, pillVerticalPadding)
                        .background(
                            Capsule()
                                .stroke(ViewHelper.accentPurple.opacity(pillStrokeOpacity), lineWidth: 1)
                        )
                }

                Text(meeting.conversation.displayTitle)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            Text(relativeTime(from: meeting.createdAt))
                .font(.system(size: 12))
                .foregroundColor(.gray)
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

                    viewModel.conversations.removeAll {
                        $0.otherParticipant?.id == removedId
                    }

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

// Strips List's default row chrome so the converted conversation list keeps the
// LazyVStack-era look (transparent, no separator, edge-to-edge insets) while
// still benefiting from `.swipeActions` for the trailing delete affordance.
private struct ConversationListRowAppearance: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
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
    @ObservedObject var contactRequestsViewModel: ContactRequestsViewModel
    @ObservedObject var sessionManager: SessionManager

    let studentRepository: StudentRepositoryProtocol
    let messagingRepository: MessagingRepositoryProtocol
    let cardColor: Color
    let buttonBlue: Color

    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var suggestedStudents: [StudentSharedCourses] = []
    @State private var isLoadingSuggested = false
    @State private var suggestedErrorMessage: String?
    @State private var selectedSuggestedStudent: StudentSharedCourses?
    @State private var addingStudentId: String?
    @State private var searchTask: Task<Void, Never>?
    @State private var successToast: String?
    @State private var successToastTask: Task<Void, Never>?


    var body: some View {
        NavigationStack {
            ZStack {
                ViewHelper.bgColor
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Add Contact")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(ViewHelper.textImportant)

                    CITextField(placeholder: "Search by name or email", text: $searchText, lines: 1)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    if let errorMessage = contactsViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }

                    if contactsViewModel.shouldShowShortSearchHint {
                        Text("Type at least 3 characters to search")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }

                    Button {
                        Task {
                            await addExactEmail()
                        }
                    } label: {
                        // Only show this button's own spinner when THIS button's
                        // flow is in flight. `addingStudentId != nil` means a row
                        // Send Request tap is what's loading; let that row spin
                        // alone instead of also lighting up this button.
                        if contactsViewModel.isMutating && addingStudentId == nil {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        } else {
                            Text("Add Exact Email")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                    }
                    .background(buttonBlue)
                    .cornerRadius(ViewHelper.componentRounding)
                    .disabled(contactsViewModel.isMutating || searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if let successToast {
                        Text(successToast)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(ViewHelper.accentGreen)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ViewHelper.accentGreen.opacity(0.15))
                            .cornerRadius(ViewHelper.componentRounding)
                    }

                    contactDiscoveryContent

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
                    .foregroundColor(ViewHelper.textImportant)
                }
            }
            .onAppear {
                contactsViewModel.clearError()
            }
            .task {
                await loadSuggestedContacts()
            }
            .onChange(of: searchText) { _, newValue in
                contactsViewModel.prepareContactSearch(query: newValue)
                searchTask?.cancel()

                let trimmedQuery = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmedQuery.count >= ContactsViewModel.minimumSearchLength else {
                    return
                }

                searchTask = Task {
                    try? await Task.sleep(nanoseconds: ContactsViewModel.searchDebounceNanoseconds)
                    guard !Task.isCancelled else {
                        return
                    }

                    await contactsViewModel.searchContactStudents(query: newValue)
                }
            }
            .onDisappear {
                searchTask?.cancel()
                successToastTask?.cancel()
            }
            .sheet(item: $selectedSuggestedStudent) { student in
                ContactInformation(
                    messagingRepository: messagingRepository,
                    courseRepository: APICourseRepository(studentRepository: StudentRepository()),
                    participantId: student.id,
                    currentStudentId: sessionManager.userId
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var contactDiscoveryContent: some View {
        if contactsViewModel.isSearchActive {
            searchResultsSection
        } else {
            suggestedContactsSection
        }
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Search Results")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.gray)
                .textCase(.uppercase)
                .padding(.top, 10)

            if contactsViewModel.isSearching {
                ProgressView()
                    .tint(ViewHelper.textImportant)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else if let searchErrorMessage = contactsViewModel.searchErrorMessage {
                Text(searchErrorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.red)
            } else if contactsViewModel.searchResults.isEmpty {
                Text("No matching shared-course contacts found")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            } else {
                VStack(spacing: 0) {
                    ForEach(contactsViewModel.searchResults) { student in
                        contactCandidateRow(student, opensProfile: false)

                        if student.id != contactsViewModel.searchResults.last?.id {
                            Divider()
                                .background(Color.white.opacity(0.08))
                                .padding(.leading, 12)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: ViewHelper.componentRounding)
                        .fill(cardColor)
                )
            }
        }
    }

    private var suggestedContactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggested Contacts")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.gray)
                .textCase(.uppercase)
                .padding(.top, 10)

            if isLoadingSuggested {
                ProgressView()
                    .tint(ViewHelper.textImportant)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else if let suggestedErrorMessage {
                Text(suggestedErrorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.red)
            } else if suggestedStudents.isEmpty {
                Text("No suggested contacts found")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            } else {
                VStack(spacing: 0) {
                    ForEach(suggestedStudents) { student in
                        contactCandidateRow(student, opensProfile: true)

                        if student.id != suggestedStudents.last?.id {
                            Divider()
                                .background(Color.white.opacity(0.08))
                                .padding(.leading, 12)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: ViewHelper.componentRounding)
                        .fill(cardColor)
                )
            }
        }
    }

    private func contactCandidateRow(_ student: StudentSharedCourses, opensProfile: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                if opensProfile {
                    Button {
                        selectedSuggestedStudent = student
                    } label: {
                        candidateName(student.name)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(student.name)
                        .modifier(ContactCandidateNameStyle())
                }

                Text(student.email)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)

                Text("\(student.sharedCourseCount) shared \(student.sharedCourseCount == 1 ? "course" : "courses")")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            if isPendingSent(for: student) {
                requestSentPill
            } else if addingStudentId == student.id {
                ProgressView()
                    .tint(.white)
                    .frame(width: 110, height: 34)
            } else {
                Button {
                    Task { await sendRequest(forCandidate: student) }
                } label: {
                    Text("Send Request")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 110, height: 34)
                        .background(buttonBlue)
                        .cornerRadius(ViewHelper.componentRounding)
                }
                .disabled(addingStudentId != nil || contactsViewModel.isMutating)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }

    private func candidateName(_ name: String) -> some View {
        Text(name)
            .modifier(ContactCandidateNameStyle())
    }

    private var requestSentPill: some View {
        Text("Request Sent")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(ViewHelper.text)
            .frame(width: 110, height: 34)
            .background(ViewHelper.fieldBgColor)
            .overlay(
                RoundedRectangle(cornerRadius: ViewHelper.componentRounding)
                    .stroke(ViewHelper.text.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(ViewHelper.componentRounding)
    }

    private func isPendingSent(for student: StudentSharedCourses) -> Bool {
        // Source of truth is the VM's outgoing array. `appendOutgoingPlaceholder`
        // inserts immediately on a successful Send Request, so the pill flips
        // instantly; when the recipient declines (or the next refresh sees the
        // row gone), the placeholder is removed and the pill clears.
        contactRequestsViewModel.outgoing.contains { request in
            request.recipientId == student.id
                && request.status == KnownContactRequestStatus.pending.rawValue
        }
    }

    private func sendRequest(forCandidate student: StudentSharedCourses) async {
        addingStudentId = student.id
        defer { addingStudentId = nil }

        let outcome = await contactsViewModel.addContact(email: student.email)
        applyAddOutcome(outcome, for: student)
    }

    private func applyAddOutcome(_ outcome: AddContactOutcome, for student: StudentSharedCourses) {
        switch outcome {
        case let .pendingSent(requestId, contactStudentId):
            let summary = StudentSummary(id: contactStudentId, name: student.name, email: student.email)
            contactRequestsViewModel.appendOutgoingPlaceholder(requestId: requestId, recipient: summary)
        case .autoAccepted:
            removeStudentFromCandidateLists(studentId: student.id)
            showSuccessToast("You're now contacts with \(student.name).")
        case .alreadyContact:
            removeStudentFromCandidateLists(studentId: student.id)
        case .sharedCourseRequired, .studentNotFound, .rateLimited, .failed:
            // Inline error from contactsViewModel.errorMessage; row stays visible.
            break
        }
    }

    private func removeStudentFromCandidateLists(studentId: String) {
        suggestedStudents.removeAll { $0.id == studentId }
        contactsViewModel.removeSearchResult(studentId: studentId)
    }

    private func showSuccessToast(_ message: String) {
        successToast = message
        successToastTask?.cancel()
        successToastTask = Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard !Task.isCancelled else { return }
            successToast = nil
        }
    }

    private func addExactEmail() async {
        let typedEmail = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let outcome = await contactsViewModel.addContact(email: typedEmail)

        switch outcome {
        case let .pendingSent(requestId, contactStudentId):
            let summary = StudentSummary(id: contactStudentId, name: nil, email: typedEmail)
            contactRequestsViewModel.appendOutgoingPlaceholder(requestId: requestId, recipient: summary)
            removeMatchingCandidates(typedEmail: typedEmail)
            searchText = ""
            await contactsViewModel.searchContactStudents(query: "")
            showSuccessToast("Request sent to \(typedEmail).")
        case .autoAccepted:
            removeMatchingCandidates(typedEmail: typedEmail)
            searchText = ""
            await contactsViewModel.searchContactStudents(query: "")
            await loadSuggestedContacts()
            showSuccessToast("You're now contacts with \(typedEmail).")
        case .alreadyContact:
            removeMatchingCandidates(typedEmail: typedEmail)
            searchText = ""
        case .sharedCourseRequired, .studentNotFound, .rateLimited, .failed:
            // Inline error from contactsViewModel.errorMessage; input stays so the user can edit.
            break
        }
    }

    private func removeMatchingCandidates(typedEmail: String) {
        let normalized = typedEmail.lowercased()
        suggestedStudents.removeAll { $0.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalized }
        contactsViewModel.searchResults.removeAll {
            $0.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalized
        }
    }

    private func loadSuggestedContacts() async {
        isLoadingSuggested = true
        suggestedErrorMessage = nil

        do {
            suggestedStudents = try await studentRepository.loadStudentSharedCourses()
        } catch {
            suggestedErrorMessage = "Could not load suggested contacts"
        }

        isLoadingSuggested = false
    }
    
}

private struct ContactCandidateNameStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(ViewHelper.textImportant)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SelectedParticipant: Identifiable {
    let id: String
}

private struct MeetingNavigationTarget: Hashable {
    let conversation: Conversation
    let messageId: Int
}
