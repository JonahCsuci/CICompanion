//
//  ContactRequestsViewModel.swift
//  CICompanion
//

import Foundation
import Combine

@MainActor
class ContactRequestsViewModel: ObservableObject {

    @Published var incoming: [ContactRequest] = []
    @Published var outgoing: [ContactRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Tracks request IDs that currently have an in-flight accept/decline/cancel
    // call. Drives per-row spinner UI without locking the entire VM.
    @Published private(set) var mutatingRequestIds: Set<Int> = []

    var incomingPendingCount: Int {
        incoming.filter { $0.status == KnownContactRequestStatus.pending.rawValue }.count
    }

    var outgoingPendingCount: Int {
        outgoing.filter { $0.status == KnownContactRequestStatus.pending.rawValue }.count
    }

    private let studentRepository: StudentRepositoryProtocol

    init(studentRepository: StudentRepositoryProtocol) {
        self.studentRepository = studentRepository
    }

    func loadRequests() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await studentRepository.loadContactRequests(
                status: KnownContactRequestStatus.pending.rawValue,
                direction: nil,
                limit: nil
            )
            incoming = response.incoming
            outgoing = response.outgoing
        } catch let error as NSError where Self.isCancellation(error) {
            // URLSession cancellation (-999) happens when SwiftUI's `.refreshable`
            // Task or a parent `.task` is cancelled mid-flight (e.g., the 3s poll
            // racing the user's pull-to-refresh). Not a real failure — the next
            // background poll rehydrates state. Don't surface it.
            print("[ContactRequestsViewModel] loadRequests cancelled (benign):", error.code)
        } catch let error as NSError {
            // Surface the server's error string so a stale-data / 409 / 500
            // failure is diagnosable from the UI rather than masked behind
            // canned copy.
            errorMessage = "Couldn't load requests: \(error.localizedDescription)"
            print("[ContactRequestsViewModel] loadRequests failed:", error)
        } catch {
            errorMessage = "Couldn't load requests."
            print("[ContactRequestsViewModel] loadRequests failed:", error)
        }

        isLoading = false
    }

    // Silent counterpart used by RealtimeBootstrap's 3s background loop and the
    // catch-up-on-connect path. Keeps state fresh without spinner or banner.
    func refreshSilently() async {
        do {
            let response = try await studentRepository.loadContactRequests(
                status: KnownContactRequestStatus.pending.rawValue,
                direction: nil,
                limit: nil
            )
            incoming = response.incoming
            outgoing = response.outgoing
        } catch {
            // Best-effort background refresh; swallow.
        }
    }

    func accept(_ requestId: Int, onAccepted: (@MainActor (ContactRequestActionResponse) async -> Void)? = nil) async {
        await performAction(requestId: requestId) {
            try await self.studentRepository.acceptContactRequest(requestId: requestId)
        } onSuccess: { response in
            await onAccepted?(response)
        }
    }

    func decline(_ requestId: Int) async {
        await performAction(requestId: requestId) {
            try await self.studentRepository.declineContactRequest(requestId: requestId)
        }
    }

    func cancel(_ requestId: Int) async {
        await performAction(requestId: requestId) {
            try await self.studentRepository.cancelContactRequest(requestId: requestId)
        }
    }

    // Insert a freshly-sent outgoing pending request locally so the SENT · PENDING
    // section reflects it before the next refetch lands. Idempotent: a duplicate
    // requestId is ignored so a racing WebSocket "created" event won't double-add.
    func appendOutgoingPlaceholder(requestId: Int, recipient: StudentSummary) {
        guard !outgoing.contains(where: { $0.requestId == requestId }) else { return }
        outgoing.insert(
            ContactRequest(
                requestId: requestId,
                requesterId: "",
                recipientId: recipient.id ?? "",
                status: KnownContactRequestStatus.pending.rawValue,
                direction: KnownContactRequestDirection.outgoing.rawValue,
                createdAt: Self.isoNow(),
                updatedAt: nil,
                respondedAt: nil,
                otherStudent: recipient,
                requester: nil,
                recipient: recipient
            ),
            at: 0
        )
    }

    // Reacts to a server-pushed `contact_request_changed` event. The realtime
    // service fans these in via `RealtimeBootstrap.route(_:)`. Idempotent —
    // if local state is already reflected, no-op.
    func applyChange(_ change: ContactRequestChange) {
        switch KnownRealtimeAction(rawValue: change.action) {
        case .accepted, .autoAccepted, .declined, .canceled:
            incoming.removeAll { $0.requestId == change.requestId }
            outgoing.removeAll { $0.requestId == change.requestId }
        case .created, .none:
            // For "created" the receiving side will pick up the new row on the
            // next refresh; no need to fabricate one without full student info.
            break
        }
    }

    private func performAction(
        requestId: Int,
        _ operation: @escaping () async throws -> ContactRequestActionResponse,
        onSuccess: ((ContactRequestActionResponse) async -> Void)? = nil
    ) async {
        mutatingRequestIds.insert(requestId)
        defer { mutatingRequestIds.remove(requestId) }

        do {
            let response = try await operation()
            incoming.removeAll { $0.requestId == requestId }
            outgoing.removeAll { $0.requestId == requestId }
            await onSuccess?(response)
        } catch let error as NSError where Self.isCancellation(error) {
            print("[ContactRequestsViewModel] performAction(requestId: \(requestId)) cancelled (benign):", error.code)
        } catch let error as NSError {
            errorMessage = "Couldn't update request: \(error.localizedDescription)"
            print("[ContactRequestsViewModel] performAction(requestId: \(requestId)) failed:", error)
        } catch {
            errorMessage = "Couldn't update request. Try again."
            print("[ContactRequestsViewModel] performAction(requestId: \(requestId)) failed:", error)
        }
    }

    private static func isCancellation(_ error: NSError) -> Bool {
        error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled
    }

    private static func isoNow() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: Date())
    }
}
