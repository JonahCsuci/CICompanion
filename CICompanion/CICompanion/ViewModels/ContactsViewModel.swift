//
//  ContactsViewModel.swift
//  CICompanion
//

import Foundation
import Combine

@MainActor
class ContactsViewModel: ObservableObject {

    @Published var contacts: [ContactStudent] = []
    @Published var isLoading = false
    @Published var isMutating = false
    @Published var errorMessage: String?

    private let studentRepository: StudentRepositoryProtocol

    init(studentRepository: StudentRepositoryProtocol) {
        self.studentRepository = studentRepository
    }

    var contactIds: Set<String> {
        Set(contacts.map(\.id))
    }

    func loadContacts() async {
        isLoading = true
        errorMessage = nil

        do {
            contacts = try await studentRepository.loadStudentContacts()
        } catch {
            contacts = []
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func addContact(email: String) async -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            errorMessage = "Enter a contact email."
            return false
        }

        isMutating = true
        errorMessage = nil

        do {
            try await studentRepository.addStudentContact(email: trimmedEmail)
            contacts = try await studentRepository.loadStudentContacts()
            isMutating = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isMutating = false
            return false
        }
    }

    func removeContact(contactStudentId: String) async {
        isMutating = true
        errorMessage = nil

        do {
            try await studentRepository.deleteStudentContact(contactStudentId: contactStudentId)
            contacts.removeAll { $0.id == contactStudentId }
        } catch {
            errorMessage = error.localizedDescription
        }

        isMutating = false
    }

    func isContact(studentId: String) -> Bool {
        contactIds.contains(studentId)
    }

    func clearError() {
        errorMessage = nil
    }

    func reset() {
        contacts = []
        isLoading = false
        isMutating = false
        errorMessage = nil
    }
}
