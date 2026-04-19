//
//  GroupInfoView.swift
//  CICompanion
//

import SwiftUI

struct GroupInfoView: View {

    let conversation: Conversation
    let messagingRepository: MessagingRepositoryProtocol
    @ObservedObject var contactsViewModel: ContactsViewModel
    let currentUserId: String
    let onConversationUpdated: () -> Void
    let onLeftGroup: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var showRename = false
    @State private var showAddMember = false
    @State private var isLeaving = false
    @State private var errorMessage: String?

    @State private var participants: [Participant] = []
    @State private var displayedGroupName: String = ""
    @State private var hasLoadedInitialState = false

    private let bgColor = Color(red: 0.08, green: 0.10, blue: 0.15)
    private let cardColor = Color(red: 0.12, green: 0.14, blue: 0.20)
    private let buttonBlue = Color(red: 0.36, green: 0.55, blue: 0.90)
    private let destructiveRed = Color(red: 0.90, green: 0.35, blue: 0.35)
    private let accentBar = Color(red: 0.6, green: 0.8, blue: 1.0)

    private var isAdmin: Bool {
        conversation.adminStudentId == currentUserId
    }

    private var canAddMembers: Bool {
        participants.count < 5
    }

    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        groupNameSection
                        membersSection

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.leading)
                        }

                        leaveGroupButton
                            .padding(.top, 8)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Group Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .disabled(isLeaving)
            .overlay {
                if isLeaving {
                    ProgressView()
                        .tint(.white)
                        .padding(20)
                        .background(cardColor.cornerRadius(12))
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            guard !hasLoadedInitialState else { return }
            participants = conversation.participants ?? []
            displayedGroupName = conversation.groupName ?? ""
            hasLoadedInitialState = true
        }
        .sheet(isPresented: $showRename) {
            RenameGroupSheet(
                currentName: displayedGroupName,
                onRename: { name in renameGroup(name: name) }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showAddMember) {
            AddMemberSheet(
                contactsViewModel: contactsViewModel,
                existingMemberIds: Set(participants.map(\.id)),
                onAdd: { contact in addMember(contact: contact) }
            )
        }
    }

    private var groupNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Group Name")

            HStack(spacing: 12) {
                Text(displayedGroupName.isEmpty ? "Unnamed Group" : displayedGroupName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isAdmin {
                    Button {
                        showRename = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(buttonBlue)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(cardColor)
            .cornerRadius(10)
        }
    }

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Members (\(participants.count))")

            VStack(spacing: 0) {
                ForEach(Array(participants.enumerated()), id: \.element.id) { index, participant in
                    memberRow(participant: participant, isLast: index == participants.count - 1 && !showsAddMemberRow)
                }

                if showsAddMemberRow {
                    addMemberRow
                }
            }
            .background(cardColor)
            .cornerRadius(10)
        }
    }

    private var showsAddMemberRow: Bool {
        isAdmin && canAddMembers
    }

    private func memberRow(participant: Participant, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentBar)
                    .frame(width: 4, height: 36)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(participant.id == currentUserId ? "\(participant.name) (You)" : participant.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        if participant.id == conversation.adminStudentId {
                            Text("Admin")
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

                    Text(participant.email)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isAdmin && participant.id != currentUserId {
                    Button("Remove") {
                        removeMember(memberId: participant.id)
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(destructiveRed)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .stroke(destructiveRed.opacity(0.6), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            if !isLast {
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 1)
                    .padding(.leading, 30)
            }
        }
    }

    private var addMemberRow: some View {
        Button {
            showAddMember = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(buttonBlue)

                Text("Add Member")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private var leaveGroupButton: some View {
        Button {
            leaveGroup()
        } label: {
            Text("Leave Group")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(destructiveRed)
                .cornerRadius(12)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.gray)
            .textCase(.uppercase)
    }

    private func renameGroup(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let previousName = displayedGroupName
        displayedGroupName = trimmed
        errorMessage = nil
        showRename = false

        Task {
            do {
                try await messagingRepository.renameGroup(conversationId: conversation.id, groupName: trimmed)
                onConversationUpdated()
            } catch {
                displayedGroupName = previousName
                errorMessage = error.localizedDescription
            }
        }
    }

    private func addMember(contact: ContactStudent) {
        guard !participants.contains(where: { $0.id == contact.id }) else { return }

        let optimisticParticipant = Participant(
            id: contact.id,
            name: contact.name,
            email: contact.email,
            joinedAt: nil
        )
        participants.append(optimisticParticipant)
        errorMessage = nil
        showAddMember = false

        Task {
            do {
                try await messagingRepository.addGroupParticipant(conversationId: conversation.id, memberId: contact.id)
                onConversationUpdated()
            } catch {
                participants.removeAll { $0.id == contact.id }
                errorMessage = error.localizedDescription
            }
        }
    }

    private func removeMember(memberId: String) {
        guard let index = participants.firstIndex(where: { $0.id == memberId }) else { return }

        let removed = participants.remove(at: index)
        errorMessage = nil

        Task {
            do {
                try await messagingRepository.removeGroupParticipant(conversationId: conversation.id, memberId: memberId)
                onConversationUpdated()
            } catch {
                participants.insert(removed, at: min(index, participants.count))
                errorMessage = error.localizedDescription
            }
        }
    }

    private func leaveGroup() {
        isLeaving = true
        errorMessage = nil

        Task {
            do {
                try await messagingRepository.leaveGroup(conversationId: conversation.id)
                isLeaving = false
                dismiss()
                onLeftGroup()
            } catch {
                isLeaving = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct RenameGroupSheet: View {

    let currentName: String
    let onRename: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var newName = ""
    @FocusState private var nameFocused: Bool

    private let bgColor = Color(red: 0.08, green: 0.10, blue: 0.15)
    private let cardColor = Color(red: 0.12, green: 0.14, blue: 0.20)
    private let buttonBlue = Color(red: 0.36, green: 0.55, blue: 0.90)

    private var trimmedName: String {
        newName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValid: Bool {
        !trimmedName.isEmpty && trimmedName != currentName
    }

    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    Text("New Name")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.gray)
                        .textCase(.uppercase)

                    TextField("", text: $newName, prompt: Text("Enter new group name").foregroundColor(.gray))
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(cardColor)
                        .cornerRadius(10)
                        .focused($nameFocused)

                    Button {
                        onRename(trimmedName)
                    } label: {
                        Text("Rename")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isValid ? buttonBlue : buttonBlue.opacity(0.35))
                            .cornerRadius(12)
                    }
                    .disabled(!isValid)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .navigationTitle("Rename Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .onAppear {
                newName = currentName
                nameFocused = true
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct AddMemberSheet: View {

    @ObservedObject var contactsViewModel: ContactsViewModel
    let existingMemberIds: Set<String>
    let onAdd: (ContactStudent) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""

    private let bgColor = Color(red: 0.08, green: 0.10, blue: 0.15)
    private let cardColor = Color(red: 0.12, green: 0.14, blue: 0.20)

    private var availableContacts: [ContactStudent] {
        let filtered = contactsViewModel.contacts.filter { !existingMemberIds.contains($0.id) }
        guard !searchText.isEmpty else { return filtered }
        let query = searchText.lowercased()
        return filtered.filter {
            $0.name.lowercased().contains(query) || $0.email.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()

                if contactsViewModel.isLoading && contactsViewModel.contacts.isEmpty {
                    ProgressView().tint(.white)
                } else if availableContacts.isEmpty {
                    Text(searchText.isEmpty ? "No contacts available to add" : "No contacts match your search")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                } else {
                    List(availableContacts) { contact in
                        Button {
                            onAdd(contact)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(contact.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Text(contact.email)
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(cardColor)
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
}
