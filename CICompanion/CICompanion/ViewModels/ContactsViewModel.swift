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
    @Published var searchQuery: String = ""
    @Published var searchResults: [StudentSharedCourses] = []
    @Published var isSearching = false
    @Published var searchErrorMessage: String?

    private let studentRepository: StudentRepositoryProtocol
    static let minimumSearchLength = 3
    static let searchDebounceNanoseconds: UInt64 = 300_000_000

    init(studentRepository: StudentRepositoryProtocol) {
        self.studentRepository = studentRepository
    }

    var contactIds: Set<String> {
        Set(contacts.map(\.id))
    }

    var trimmedSearchQuery: String {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var shouldShowShortSearchHint: Bool {
        !trimmedSearchQuery.isEmpty && trimmedSearchQuery.count < Self.minimumSearchLength
    }

    var isSearchActive: Bool {
        trimmedSearchQuery.count >= Self.minimumSearchLength
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

    func prepareContactSearch(query: String) {
        searchQuery = query
        searchErrorMessage = nil

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= Self.minimumSearchLength else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
    }

    func searchContactStudents(query: String) async {
        searchQuery = query
        searchErrorMessage = nil

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        guard trimmedQuery.count >= Self.minimumSearchLength else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true

        do {
            let results = try await studentRepository.searchContactStudents(query: trimmedQuery)

            guard trimmedQuery == trimmedSearchQuery else {
                return
            }

            searchResults = results
        } catch {
            guard trimmedQuery == trimmedSearchQuery else {
                return
            }

            searchResults = []
            searchErrorMessage = error.localizedDescription
        }

        if trimmedQuery == trimmedSearchQuery {
            isSearching = false
        }
    }

    func removeSearchResult(studentId: String) {
        searchResults.removeAll { $0.id == studentId }
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
        searchErrorMessage = nil
    }

    func reset() {
        contacts = []
        isLoading = false
        isMutating = false
        errorMessage = nil
        searchQuery = ""
        searchResults = []
        isSearching = false
        searchErrorMessage = nil
    }
}
