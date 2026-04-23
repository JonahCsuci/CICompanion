//
//  NewGroupView.swift
//  CICompanion
//

import SwiftUI

struct NewGroupView: View {

    let contacts: [ContactStudent]
    let messagingRepository: MessagingRepositoryProtocol
    let onGroupCreated: (Conversation) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var groupName = ""
    @State private var firstMessage = ""
    @State private var selectedContactIds: Set<String> = []
    @State private var isCreating = false
    @State private var errorMessage: String?

    // Backend enforces 3–5 total members including the creator.
    // The creator is always included, so the selection range is 2…4 of their contacts.
    private let minSelection = 2
    private let maxSelection = 4

    var body: some View {
        NavigationStack {
            CIView(heading: {
                CIHeader { CIPageTitle("New Group") }
            }) {
                CIScrollView {
                    Divider()
                        .padding(.bottom, ViewHelper.spacing)
                    CIItem(name: "Group name") {
                        CITextField(placeholder: "e.g. Calc Study Group", text: $groupName, lines: 1)
                    }

                    CIItem(name: "First message") {
                        CITextField(placeholder: "Say something to kick off the chat", text: $firstMessage, lines: 1...6)
                    }
                    .padding(.top, ViewHelper.spacing)

                    CIItem(name: membersLabel) {
                        if contacts.isEmpty {
                            emptyContactsHint
                        } else {
                            contactPickerList
                        }
                    }
                    .padding(.top, ViewHelper.spacing)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: ViewHelper.smallTextSize))
                            .foregroundColor(ViewHelper.accentRed)
                    }

                    createButton
                        .padding(.top, ViewHelper.spacing * 2)
                }
            }
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
                        .background(ViewHelper.fieldBgColor.cornerRadius(ViewHelper.componentRounding))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var membersLabel: String {
        "Members (\(selectedContactIds.count) / \(maxSelection))"
    }

    private var contactPickerList: some View {
        VStack(spacing: 0) {
            ForEach(Array(contacts.enumerated()), id: \.element.id) { index, contact in
                contactRow(contact)
                if index < contacts.count - 1 {
                    rowDivider
                }
            }
        }
        .background(ViewHelper.fieldBgColor)
        .cornerRadius(ViewHelper.componentRounding)
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(ViewHelper.Messaging.hairlineOpacity))
            .frame(height: ViewHelper.Messaging.hairlineHeight)
            .padding(.leading, ViewHelper.padding * 2 + ViewHelper.bigIconSize)
    }

    private func contactRow(_ contact: ContactStudent) -> some View {
        let isSelected = selectedContactIds.contains(contact.id)
        let atCapacity = selectedContactIds.count >= maxSelection && !isSelected

        return Button {
            toggleSelection(contact.id)
        } label: {
            HStack(spacing: ViewHelper.Messaging.contactRowSpacing) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: ViewHelper.bigIconSize, weight: .medium))
                    .foregroundColor(isSelected ? ViewHelper.accentBlue : ViewHelper.text.opacity(0.7))

                VStack(alignment: .leading, spacing: ViewHelper.Messaging.contactRowNameEmailSpacing) {
                    Text(contact.name)
                        .font(.system(size: ViewHelper.textSize, weight: .semibold))
                        .foregroundColor(atCapacity ? ViewHelper.text : .white)
                        .lineLimit(1)
                    Text(contact.email)
                        .font(.system(size: ViewHelper.smallTextSize))
                        .foregroundColor(ViewHelper.text)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, ViewHelper.padding)
            .padding(.vertical, ViewHelper.Messaging.cardRowVerticalPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(atCapacity)
    }

    private var emptyContactsHint: some View {
        Text("Add at least 2 contacts to create a group.")
            .font(.system(size: ViewHelper.textSize))
            .foregroundColor(ViewHelper.text)
    }

    private var createButton: some View {
        Button {
            createGroup()
        } label: {
            Text("Create Group")
                .font(.system(size: ViewHelper.textSize, weight: .bold))
                .foregroundColor(ViewHelper.textImportant)
                .frame(maxWidth: .infinity)
                .frame(height: ViewHelper.buttonHeight)
                .background(canCreate ? ViewHelper.accentBlue : ViewHelper.fieldBgColor)
                .cornerRadius(ViewHelper.componentRounding)
        }
        .disabled(!canCreate)
    }

    private var canCreate: Bool {
        !trimmedName.isEmpty
            && !trimmedFirstMessage.isEmpty
            && selectedContactIds.count >= minSelection
            && selectedContactIds.count <= maxSelection
    }

    private var trimmedName: String {
        groupName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedFirstMessage: String {
        firstMessage.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func toggleSelection(_ contactId: String) {
        if selectedContactIds.contains(contactId) {
            selectedContactIds.remove(contactId)
        } else if selectedContactIds.count < maxSelection {
            selectedContactIds.insert(contactId)
        }
    }

    private func createGroup() {
        isCreating = true
        errorMessage = nil

        let memberIds = Array(selectedContactIds)

        Task {
            do {
                let conversation = try await messagingRepository.createGroupConversation(
                    groupName: trimmedName,
                    memberIds: memberIds,
                    firstMessageBody: trimmedFirstMessage
                )
                dismiss()
                onGroupCreated(conversation)
            } catch {
                isCreating = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
