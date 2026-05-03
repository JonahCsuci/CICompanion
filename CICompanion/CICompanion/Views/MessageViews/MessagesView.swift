//
//  MessagesView.swift
//  CICompanion
//

import SwiftUI

struct MessagesView: View {

    @StateObject var viewModel: ConversationsViewModel
    @StateObject private var contactsViewModel: ContactsViewModel
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
        tutorViewModel: TutorViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _contactsViewModel = StateObject(
            wrappedValue: ContactsViewModel(studentRepository: studentRepository)
        )
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
                    Text(item.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(mode == item ? .white : .gray)
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
                    }
                )
            }
        }
        .task(id: sessionManager.isSignedIn) {
            if sessionManager.isSignedIn {
                viewModel.loadConversations()
                await contactsViewModel.loadContacts()

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
        Group {
            if contactsViewModel.isLoading && contactsViewModel.contacts.isEmpty {
                Spacer()
                CILoadingPage()
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
                    .cornerRadius(ViewHelper.componentRounding)
            }

            Spacer()
        }
    }

    private var conversationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if let searchErrorMessage = viewModel.searchErrorMessage, viewModel.isSearchActive {
                    Text(searchErrorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }

                if viewModel.isSearchActive {
                    ForEach(viewModel.displayedSearchResults) { result in
                        searchResultRow(result)
                    }
                } else {
                    ForEach(viewModel.displayedConversations) { conversation in
                        Button {
                            viewModel.markConversationReadLocally(conversationId: conversation.id)
                            navigationPath.append(conversation)
                        } label: {
                            conversationRow(conversation)
                        }
                    }
                }
            }
        }
        .refreshable {
            if viewModel.isSearchActive {
                viewModel.updateSearchQuery(viewModel.searchQuery)
            } else {
                viewModel.loadConversations()
            }
        }
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
    @ObservedObject var sessionManager: SessionManager

    let studentRepository: StudentRepositoryProtocol
    let messagingRepository: MessagingRepositoryProtocol
    let cardColor: Color
    let buttonBlue: Color

    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var suggestedStudents: [StudentSharedCourses] = []
    @State private var isLoadingSuggested = false
    @State private var suggestedErrorMessage: String?
    @State private var selectedSuggestedStudent: StudentSharedCourses?
    @State private var addingStudentId: String?


    var body: some View {
        NavigationStack {
            ZStack {
                ViewHelper.bgColor
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Add Contact")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(ViewHelper.textImportant)

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
                            let typedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

                            let added = await contactsViewModel.addContact(email: typedEmail)

                            if added {
                                suggestedStudents.removeAll { student in
                                    let suggestedEmail = student.email
                                        .trimmingCharacters(in: .whitespacesAndNewlines)
                                        .lowercased()

                                    return suggestedEmail == typedEmail.lowercased()
                                }

                                email = ""
                                await loadSuggestedContacts()
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
                    .cornerRadius(ViewHelper.componentRounding)
                    .disabled(contactsViewModel.isMutating)

                    suggestedContactsSection

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
                        suggestedContactRow(student)

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

    private func suggestedContactRow(_ student: StudentSharedCourses) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Button {
                    selectedSuggestedStudent = student
                } label: {
                    Text(student.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ViewHelper.textImportant)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                Text("\(student.sharedCourseCount) shared \(student.sharedCourseCount == 1 ? "course" : "courses")")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                Task {
                    addingStudentId = student.id

                    let added = await contactsViewModel.addContact(email: student.email)

                    if added {
                        suggestedStudents.removeAll { $0.id == student.id }
                    }

                    addingStudentId = nil
                }
            } label: {
                if addingStudentId == student.id {
                    ProgressView()
                        .tint(.white)
                        .frame(width: 70, height: 34)
                } else {
                    Text("+ Add")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 70, height: 34)
                        .background(buttonBlue)
                        .cornerRadius(ViewHelper.componentRounding)
                }
            }
            .disabled(addingStudentId != nil || contactsViewModel.isMutating)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
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

private struct SelectedParticipant: Identifiable {
    let id: String
}

private struct MeetingNavigationTarget: Hashable {
    let conversation: Conversation
    let messageId: Int
}
