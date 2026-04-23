//
//  GroupInfoView.swift
//  CICompanion
//

import SwiftUI

struct GroupInfoView: View {

    let conversation: Conversation
    let currentUserId: String
    let contacts: [ContactStudent]
    let messagingRepository: MessagingRepositoryProtocol
    // Awaited so the sheet stays visible until ChatView's refresh has loaded the new participants/admin/name —
    // prevents a race where the user re-opens GroupInfoView before the refresh finishes and sees stale data.
    let onConversationChanged: () async -> Void
    let onLeft: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var groupName: String
    @State private var isSavingName = false
    @State private var removingMemberId: String?
    @State private var isLeaving = false
    @State private var showAddMember = false
    @State private var confirmingLeave = false
    @State private var errorMessage: String?
    @State private var selectedParticipant: SelectedParticipant?

    private let maxMembers = 5

    private let memberTitleSpacing: CGFloat = 6
    private let memberContentSpacing: CGFloat = 3
    private let adminBadgeTextSize: CGFloat = 10
    private let adminBadgeHorizontalPadding: CGFloat = 7
    private let adminBadgeVerticalPadding: CGFloat = 2
    private let adminBadgeStrokeOpacity: Double = 0.6
    private let removeButtonHorizontalPadding: CGFloat = 12
    private let removeButtonVerticalPadding: CGFloat = 6
    private let removeButtonProgressWidth: CGFloat = 64
    private let removeButtonProgressHeight: CGFloat = 28
    private let removeButtonBackgroundOpacity: Double = 0.15
    private let actionRowIconSize: CGFloat = 17

    init(
        conversation: Conversation,
        currentUserId: String,
        contacts: [ContactStudent],
        messagingRepository: MessagingRepositoryProtocol,
        onConversationChanged: @escaping () async -> Void,
        onLeft: @escaping () -> Void
    ) {
        self.conversation = conversation
        self.currentUserId = currentUserId
        self.contacts = contacts
        self.messagingRepository = messagingRepository
        self.onConversationChanged = onConversationChanged
        self.onLeft = onLeft
        _groupName = State(initialValue: conversation.groupName ?? "")
    }

    private var isAdmin: Bool {
        conversation.isAdmin(currentUserId: currentUserId)
    }

    private var members: [Participant] {
        conversation.participants ?? []
    }

    var body: some View {
        NavigationStack {
            CIView(heading: {
                CIHeader { CIPageTitle("Group Info") }
            }) {
                CIScrollView {
                    Divider()
                        .padding(.bottom, ViewHelper.spacing)

                    nameSection

                    membersSection
                        .padding(.top, ViewHelper.spacing)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: ViewHelper.smallTextSize))
                            .foregroundColor(ViewHelper.accentRed)
                    }

                    leaveSection
                        .padding(.top, ViewHelper.spacing * 2)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .task {
                // Refresh immediately on open and every few seconds while visible so member changes from other admins
                // (or the user themselves being removed) reflect without waiting for ChatView's slower poll.
                while !Task.isCancelled {
                    await onConversationChanged()
                    try? await Task.sleep(for: .seconds(ViewHelper.pollIntervalSeconds))
                }
            }
            .sheet(isPresented: $showAddMember) {
                AddMemberSheet(
                    eligibleContacts: eligibleContacts,
                    onPick: { contact in
                        Task { await addMember(contact) }
                    }
                )
            }
            .sheet(item: $selectedParticipant) { participant in
                ContactInformation(
                    messagingRepository: messagingRepository,
                    courseRepository: APICourseRepository(studentRepository: StudentRepository()),
                    participantId: participant.id
                )
            }
            .alert("Leave this group?", isPresented: $confirmingLeave) {
                Button("Cancel", role: .cancel) { }
                Button("Leave", role: .destructive) {
                    Task { await leaveGroup() }
                }
            } message: {
                Text(isAdmin
                     ? "Admin will transfer to the next-oldest member."
                     : "You will lose access to this group.")
            }
        }
        .preferredColorScheme(.dark)
    }

    private var nameSection: some View {
        CIItem(name: "Group name") {
            if isAdmin {
                VStack(alignment: .trailing, spacing: ViewHelper.spacing) {
                    CITextField(placeholder: "Group name", text: $groupName, lines: 1)

                    if trimmedName != (conversation.groupName ?? "") && !trimmedName.isEmpty {
                        Button {
                            Task { await saveName() }
                        } label: {
                            Text(isSavingName ? "Saving..." : "Save")
                                .font(.system(size: ViewHelper.textSize, weight: .semibold))
                                .foregroundColor(ViewHelper.textImportant)
                                .padding(.horizontal, ViewHelper.padding)
                                .padding(.vertical, ViewHelper.tinyPadding)
                                .background(ViewHelper.accentBlue)
                                .cornerRadius(ViewHelper.componentRounding)
                        }
                        .disabled(isSavingName)
                    }
                }
            } else {
                Text(conversation.groupName ?? "")
                    .font(.system(size: ViewHelper.textSize))
                    .foregroundColor(.white)
                    .padding(.vertical, ViewHelper.tinyPadding)
            }
        }
    }

    private var membersSection: some View {
        CIItem(name: "Members (\(members.count) / \(maxMembers))") {
            VStack(spacing: 0) {
                ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
                    memberRow(member)

                    if index < members.count - 1 {
                        rowDivider
                    }
                }

                if canAddMembers {
                    rowDivider
                    addMemberRow
                }
            }
            .background(ViewHelper.fieldBgColor)
            .cornerRadius(ViewHelper.componentRounding)
        }
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(ViewHelper.hairlineOpacity))
            .frame(height: ViewHelper.hairlineHeight)
            .padding(.leading, ViewHelper.padding)
    }

    private func memberRow(_ member: Participant) -> some View {
        let memberIsAdmin = member.id == conversation.adminStudentId
        let isSelf = member.id == currentUserId

        return HStack(spacing: ViewHelper.spacing) {
            VStack(alignment: .leading, spacing: memberContentSpacing) {
                HStack(spacing: memberTitleSpacing) {
                    Button {
                        selectedParticipant = SelectedParticipant(id: member.id)
                    } label: {
                        Text(member.name + (isSelf ? " (You)" : ""))
                            .font(.system(size: ViewHelper.textSize, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .buttonStyle(.plain)

                    if memberIsAdmin {
                        Text("Admin")
                            .font(.system(size: adminBadgeTextSize, weight: .semibold))
                            .foregroundColor(ViewHelper.accentBlue)
                            .padding(.horizontal, adminBadgeHorizontalPadding)
                            .padding(.vertical, adminBadgeVerticalPadding)
                            .background(
                                Capsule().stroke(
                                    ViewHelper.accentBlue.opacity(adminBadgeStrokeOpacity),
                                    lineWidth: 1
                                )
                            )
                    }
                }

                Text(member.email)
                    .font(.system(size: ViewHelper.smallTextSize))
                    .foregroundColor(ViewHelper.text)
                    .lineLimit(1)
            }

            Spacer(minLength: ViewHelper.spacing)

            if isAdmin && !isSelf {
                Button {
                    Task { await removeMember(member) }
                } label: {
                    if removingMemberId == member.id {
                        ProgressView()
                            .tint(ViewHelper.accentRed)
                            .frame(width: removeButtonProgressWidth, height: removeButtonProgressHeight)
                    } else {
                        Text("Remove")
                            .font(.system(size: ViewHelper.metaTextSize, weight: .semibold))
                            .foregroundColor(ViewHelper.accentRed)
                            .padding(.horizontal, removeButtonHorizontalPadding)
                            .padding(.vertical, removeButtonVerticalPadding)
                            .background(
                                Capsule().fill(
                                    ViewHelper.accentRed.opacity(removeButtonBackgroundOpacity)
                                )
                            )
                    }
                }
                .buttonStyle(.plain)
                .disabled(removingMemberId != nil)
            }
        }
        .padding(.horizontal, ViewHelper.padding)
        .padding(.vertical, ViewHelper.cardRowVerticalPadding)
    }

    private var canAddMembers: Bool {
        isAdmin && members.count < maxMembers && !eligibleContacts.isEmpty
    }

    private var addMemberRow: some View {
        Button {
            showAddMember = true
        } label: {
            HStack(spacing: ViewHelper.rowIconTextSpacing) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: actionRowIconSize, weight: .medium))

                Text("Add Member")
                    .font(.system(size: ViewHelper.textSize, weight: .semibold))

                Spacer()
            }
            .foregroundColor(ViewHelper.accentBlue)
            .padding(.horizontal, ViewHelper.padding)
            .padding(.vertical, ViewHelper.cardRowVerticalPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var leaveSection: some View {
        Button {
            confirmingLeave = true
        } label: {
            HStack(spacing: ViewHelper.rowIconTextSpacing) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: actionRowIconSize, weight: .medium))

                Text(isLeaving ? "Leaving..." : "Leave Group")
                    .font(.system(size: ViewHelper.textSize, weight: .semibold))

                Spacer()
            }
            .foregroundColor(ViewHelper.accentRed)
            .padding(.horizontal, ViewHelper.padding)
            .padding(.vertical, ViewHelper.cardRowVerticalPadding)
            .background(ViewHelper.fieldBgColor)
            .cornerRadius(ViewHelper.componentRounding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isLeaving)
    }

    private var eligibleContacts: [ContactStudent] {
        let memberIdSet = Set(conversation.participantIds)
        return contacts.filter { !memberIdSet.contains($0.id) }
    }

    private var trimmedName: String {
        groupName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func saveName() async {
        isSavingName = true
        errorMessage = nil

        do {
            try await messagingRepository.renameGroup(
                conversationId: conversation.id,
                groupName: trimmedName
            )
            await onConversationChanged()
            isSavingName = false
            dismiss()
        } catch {
            isSavingName = false
            errorMessage = error.localizedDescription
        }
    }

    private func addMember(_ contact: ContactStudent) async {
        errorMessage = nil

        do {
            try await messagingRepository.addParticipant(
                conversationId: conversation.id,
                memberId: contact.id
            )
            await onConversationChanged()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func removeMember(_ member: Participant) async {
        removingMemberId = member.id
        errorMessage = nil

        do {
            try await messagingRepository.removeParticipant(
                conversationId: conversation.id,
                memberId: member.id
            )
            await onConversationChanged()
            removingMemberId = nil
            dismiss()
        } catch {
            removingMemberId = nil
            errorMessage = error.localizedDescription
        }
    }

    private func leaveGroup() async {
        isLeaving = true
        errorMessage = nil

        do {
            _ = try await messagingRepository.leaveGroup(conversationId: conversation.id)
            isLeaving = false
            onLeft()
            dismiss()
        } catch {
            isLeaving = false
            errorMessage = error.localizedDescription
        }
    }
}

private struct AddMemberSheet: View {

    let eligibleContacts: [ContactStudent]
    let onPick: (ContactStudent) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                ViewHelper.bgColor.ignoresSafeArea()

                if eligibleContacts.isEmpty {
                    Text("All your contacts are already in this group.")
                        .font(.system(size: ViewHelper.textSize))
                        .foregroundColor(ViewHelper.text)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, ViewHelper.padding * 2)
                } else {
                    List(filteredContacts) { contact in
                        Button {
                            onPick(contact)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(contact.name)
                                    .font(.system(size: ViewHelper.textSize, weight: .semibold))
                                    .foregroundColor(.white)

                                Text(contact.email)
                                    .font(.system(size: 13))
                                    .foregroundColor(ViewHelper.text)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(ViewHelper.fieldBgColor)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Add Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .searchable(text: $searchText, prompt: "Search contacts")
        }
        .preferredColorScheme(.dark)
    }

    private var filteredContacts: [ContactStudent] {
        guard !searchText.isEmpty else { return eligibleContacts }
        let query = searchText.lowercased()

        return eligibleContacts.filter {
            $0.name.lowercased().contains(query) || $0.email.lowercased().contains(query)
        }
    }
}

private struct SelectedParticipant: Identifiable {
    let id: String
}
