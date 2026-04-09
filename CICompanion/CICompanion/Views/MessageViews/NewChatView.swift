//
//  NewChatView.swift
//  CICompanion
//

import SwiftUI

struct NewChatView: View {

    let messagingRepository: MessagingRepositoryProtocol
    let onConversationCreated: (Conversation) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var students: [Participant] = []
    @State private var isLoading = true
    @State private var isCreating = false
    @State private var searchText = ""

    private let bgColor = Color(red: 0.08, green: 0.10, blue: 0.15)
    private let cardColor = Color(red: 0.12, green: 0.14, blue: 0.20)

    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if filteredStudents.isEmpty {
                    Text("No students found")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                } else {
                    studentList
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
            .searchable(text: $searchText, prompt: "Search students")
            .task {
                await loadStudents()
            }
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

    private var studentList: some View {
        List(filteredStudents) { student in
            Button {
                startConversation(with: student)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(student.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text(student.email)
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

    private var filteredStudents: [Participant] {
        guard !searchText.isEmpty else { return students }
        let query = searchText.lowercased()
        return students.filter {
            $0.name.lowercased().contains(query) || $0.email.lowercased().contains(query)
        }
    }

    private func loadStudents() async {
        do {
            students = try await messagingRepository.loadAllStudents()
            isLoading = false
        } catch {
            isLoading = false
            print("Error loading students:", error)
        }
    }

    private func startConversation(with student: Participant) {
        isCreating = true

        Task {
            do {
                let conversation = try await messagingRepository.createOrGetDirectConversation(
                    otherStudentId: student.id
                )
                dismiss()
                onConversationCreated(conversation)
            } catch {
                isCreating = false
                print("Error creating conversation:", error)
            }
        }
    }
}
