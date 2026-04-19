//
//  NewChatView.swift
//  CICompanion
//

import SwiftUI

struct NewChatView: View {

    let contacts: [ContactStudent]
    let messagingRepository: MessagingRepositoryProtocol
    let onConversationCreated: (Conversation) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var isCreating = false
    @State private var searchText = ""
    @State private var errorMessage: String?

    private let contactEmailTextSize: CGFloat = 13
    private let emptyStateTitleBoost: CGFloat = 2

    var body: some View {
        NavigationStack {
            ZStack {
                ViewHelper.bgColor.ignoresSafeArea()

                if contacts.isEmpty {
                    emptyState
                } else if filteredContacts.isEmpty {
                    noSearchMatchState
                } else {
                    contactList
                }
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .searchable(text: $searchText, prompt: "Search contacts")
            .disabled(isCreating)
            .overlay {
                if isCreating {
                    ProgressView("Starting chat...")
                        .tint(.white)
                        .foregroundColor(.white)
                        .padding(20)
                        .background(ViewHelper.fieldBgColor.cornerRadius(ViewHelper.componentRounding))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var contactList: some View {
        List(filteredContacts) { contact in
            Button {
                startConversation(with: contact)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(.system(size: ViewHelper.textSize, weight: .semibold))
                        .foregroundColor(.white)
                    Text(contact.email)
                        .font(.system(size: contactEmailTextSize))
                        .foregroundColor(ViewHelper.text)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(ViewHelper.fieldBgColor)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var noSearchMatchState: some View {
        VStack(spacing: ViewHelper.spacing) {
            Text("No matching contacts")
                .font(.system(size: ViewHelper.textSize, weight: .semibold))
                .foregroundColor(.white)
            Button {
                searchText = ""
            } label: {
                Text("Clear search")
                    .font(.system(size: ViewHelper.smallTextSize, weight: .semibold))
                    .foregroundColor(ViewHelper.accentBlue)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: ViewHelper.spacing * 2) {
            Text("No contacts yet")
                .font(.system(size: ViewHelper.textSize + emptyStateTitleBoost, weight: .semibold))
                .foregroundColor(.white)
            Text("Add contacts from the Contacts tab to start a chat.")
                .font(.system(size: ViewHelper.textSize))
                .foregroundColor(ViewHelper.text)
                .multilineTextAlignment(.center)
                .padding(.horizontal, ViewHelper.padding * 2)

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: ViewHelper.smallTextSize))
                    .foregroundColor(ViewHelper.accentRed)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ViewHelper.padding * 2)
            }
        }
    }

    private var filteredContacts: [ContactStudent] {
        guard !searchText.isEmpty else { return contacts }
        let query = searchText.lowercased()
        return contacts.filter {
            $0.name.lowercased().contains(query) || $0.email.lowercased().contains(query)
        }
    }

    private func startConversation(with contact: ContactStudent) {
        isCreating = true
        errorMessage = nil

        Task {
            do {
                let conversation = try await messagingRepository.createOrGetDirectConversation(
                    otherStudentId: contact.id
                )
                dismiss()
                onConversationCreated(conversation)
            } catch {
                isCreating = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
