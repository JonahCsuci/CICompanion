//
//  NewGroupView.swift
//  CICompanion
//

import SwiftUI

struct NewGroupView: View {

    @ObservedObject var contactsViewModel: ContactsViewModel
    let messagingRepository: MessagingRepositoryProtocol
    let onGroupCreated: (Conversation) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var groupName = ""
    @State private var selectedContactIds = Set<String>()
    @State private var firstMessage = ""
    @State private var isCreating = false
    @State private var errorMessage: String?

    private let bgColor = Color(red: 0.08, green: 0.10, blue: 0.15)
    private let cardColor = Color(red: 0.12, green: 0.14, blue: 0.20)
    private let buttonBlue = Color(red: 0.36, green: 0.55, blue: 0.90)
    private let accentBar = Color(red: 0.6, green: 0.8, blue: 1.0)

    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        groupNameSection
                        membersSection
                        firstMessageSection

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.leading)
                        }

                        createButton
                            .padding(.top, 8)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .disabled(isCreating)
            .overlay {
                if isCreating {
                    ProgressView("Creating group...")
                        .tint(.white)
                        .foregroundColor(.white)
                        .padding(20)
                        .background(cardColor.cornerRadius(12))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var groupNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Group Name")

            TextField("", text: $groupName, prompt: Text("Enter group name").foregroundColor(.gray))
                .foregroundColor(.white)
                .font(.system(size: 16))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(cardColor)
                .cornerRadius(10)
        }
    }

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                sectionLabel("Members")
                Text("(\(selectedContactIds.count)/4)")
                    .font(.system(size: 13))
                    .foregroundColor(.gray.opacity(0.7))
                Spacer()
            }

            if contactsViewModel.contacts.isEmpty {
                Text("No contacts available. Add contacts from the Contacts tab first.")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(cardColor)
                    .cornerRadius(10)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(contactsViewModel.contacts.enumerated()), id: \.element.id) { index, contact in
                        memberRow(contact: contact, isLast: index == contactsViewModel.contacts.count - 1)
                    }
                }
                .background(cardColor)
                .cornerRadius(10)
            }

            if let hint = memberCountHint {
                Text(hint)
                    .font(.system(size: 13))
                    .foregroundColor(.gray.opacity(0.7))
                    .padding(.top, 2)
            }
        }
    }

    private func memberRow(contact: ContactStudent, isLast: Bool) -> some View {
        let selected = selectedContactIds.contains(contact.id)
        return Button {
            toggleSelection(contactId: contact.id)
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(contact.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text(contact.email)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(selected ? accentBar : .gray.opacity(0.6))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                if !isLast {
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 1)
                        .padding(.leading, 14)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var firstMessageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("First Message")

            ZStack(alignment: .topLeading) {
                if firstMessage.isEmpty {
                    Text("Say something to start the conversation")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                }

                TextEditor(text: $firstMessage)
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(minHeight: 110)
            }
            .background(cardColor)
            .cornerRadius(10)
        }
    }

    private var createButton: some View {
        HStack {
            Spacer()
            Button {
                createGroup()
            } label: {
                Text("Create Group")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(createButtonDisabled ? buttonBlue.opacity(0.35) : buttonBlue)
                    .cornerRadius(12)
            }
            .disabled(createButtonDisabled)
            Spacer()
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.gray)
            .textCase(.uppercase)
    }

    private func toggleSelection(contactId: String) {
        if selectedContactIds.contains(contactId) {
            selectedContactIds.remove(contactId)
        } else if selectedContactIds.count < 4 {
            selectedContactIds.insert(contactId)
        }
    }

    private var createButtonDisabled: Bool {
        groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        selectedContactIds.count < 2 ||
        selectedContactIds.count > 4 ||
        firstMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        isCreating
    }

    private var memberCountHint: String? {
        if selectedContactIds.isEmpty {
            return "Select 2–4 members (you'll be the 3rd–5th)"
        }
        if selectedContactIds.count < 2 {
            return "Select at least 2 members"
        }
        return nil
    }

    private func createGroup() {
        let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMessage = firstMessage.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty, !trimmedMessage.isEmpty else { return }
        guard selectedContactIds.count >= 2, selectedContactIds.count <= 4 else { return }

        isCreating = true
        errorMessage = nil

        Task {
            do {
                let conversation = try await messagingRepository.createGroupConversation(
                    groupName: trimmedName,
                    memberIds: Array(selectedContactIds),
                    firstMessageBody: trimmedMessage
                )
                isCreating = false
                dismiss()
                onGroupCreated(conversation)
            } catch {
                isCreating = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
