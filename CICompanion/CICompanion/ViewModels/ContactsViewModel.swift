//
//  ContactsViewModel.swift
//  CICompanion
//

import Foundation
import Combine

// Result of `ContactsViewModel.addContact(email:)`. The view layer switches on
// this to drive per-row UI states without inspecting HTTP details. Error copy
// for surfaced cases lives on `errorMessage`; this enum is the discriminator.
enum AddContactOutcome {
    case pendingSent(requestId: Int, contactStudentId: String)
    case autoAccepted(conversationId: Int?)
    case alreadyContact
    case sharedCourseRequired
    case studentNotFound
    case rateLimited
    case failed
}

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

    // Silent counterpart to loadContacts() — no spinner, no error banner. Used
    // by the realtime catch-up path in `RealtimeBootstrap` so the contacts list
    // refreshes without flickering UI on every WebSocket reconnect.
    func refreshSilently() async {
        do {
            contacts = try await studentRepository.loadStudentContacts()
        } catch {
            // Best-effort background refresh; swallow errors.
        }
    }

    func addContact(email: String) async -> AddContactOutcome {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            errorMessage = "Enter a contact email."
            return .failed
        }

        isMutating = true
        errorMessage = nil
        defer { isMutating = false }

        do {
            let response = try await studentRepository.sendContactRequest(toEmail: trimmedEmail)
            return await mapSendResponse(response)
        } catch let error as NSError {
            return mapSendError(error)
        } catch {
            errorMessage = error.localizedDescription
            return .failed
        }
    }

    private func mapSendResponse(_ response: SendContactRequestResponse) async -> AddContactOutcome {
        switch response.status {
        case KnownContactRequestStatus.accepted.rawValue:
            // Reciprocal pending request triggered auto-accept server-side; the
            // backend created the mutual contact rows, so refetch to reflect them.
            await refreshSilently()
            return .autoAccepted(conversationId: response.conversationId)

        case KnownContactRequestStatus.pending.rawValue:
            guard let requestId = response.requestId,
                  let contactStudentId = response.contactStudentId else {
                errorMessage = "Couldn't send request. Try again."
                return .failed
            }
            return .pendingSent(requestId: requestId, contactStudentId: contactStudentId)

        default:
            errorMessage = "Couldn't send request. Try again."
            return .failed
        }
    }

    private func mapSendError(_ error: NSError) -> AddContactOutcome {
        switch error.code {
        case 403:
            errorMessage = "You and this person need to share at least one course."
            return .sharedCourseRequired
        case 404:
            errorMessage = "We couldn't find a CIApp account with that email."
            return .studentNotFound
        case 409:
            errorMessage = nil
            return .alreadyContact
        case 429:
            errorMessage = "Slow down a moment, then try again."
            return .rateLimited
        default:
            errorMessage = error.localizedDescription
            return .failed
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
