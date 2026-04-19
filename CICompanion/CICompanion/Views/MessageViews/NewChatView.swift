//
//  NewChatView.swift
//  CICompanion
//

import SwiftUI

struct NewChatView: View {

    @ObservedObject var contactsViewModel: ContactsViewModel
    let messagingRepository: MessagingRepositoryProtocol
    let onConversationCreated: (Conversation) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var isCreating = false
    @State private var searchText = ""
    @State private var errorMessage: String?

    private let bgColor = Color(red: 0.08, green: 0.10, blue: 0.15)
    private let cardColor = Color(red: 0.12, green: 0.14, blue: 0.20)

    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()

                if contactsViewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else if contactsViewModel.contacts.isEmpty {
                    VStack(spacing: 12) {
                        Text("No contacts yet")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                        Text("Add contacts from the Contacts tab to start chatting")
                            .foregroundColor(.gray.opacity(0.7))
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else if filteredContacts.isEmpty {
                    Text("No contacts match your search")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                } else {
                    contactList
                }

                if let errorMessage {
                    VStack {
                        Spacer()
                        Text(errorMessage)
                            .font(.system(size: ViewHelper.smallTextSize))
                            .foregroundColor(ViewHelper.accentRed)
                            .multilineTextAlignment(.center)
                            .padding(ViewHelper.padding)
                            .frame(maxWidth: .infinity)
                            .background(ViewHelper.fieldBgColor)
                    }
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
                        .background(cardColor.cornerRadius(12))
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

    private var filteredContacts: [ContactStudent] {
        guard !searchText.isEmpty else { return contactsViewModel.contacts }
        let query = searchText.lowercased()
        return contactsViewModel.contacts.filter {
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
                isCreating = false
                dismiss()
                onConversationCreated(conversation)
            } catch {
                isCreating = false
                errorMessage = error.localizedDescription
                print("Error creating conversation:", error)
            }
        }
    }
}
