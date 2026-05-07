//
//  RealtimeBootstrap.swift
//  CICompanion
//

import Combine
import SwiftUI

extension Notification.Name {
    static let realtimeNewMessage = Notification.Name("ci.realtime.newMessage")
    static let realtimeContactsRefresh = Notification.Name("ci.realtime.contactsRefresh")
}

// View modifier that owns the realtime lifecycle and event routing for the
// signed-in app. Attached once to `RootTabView`. Drives:
//   - WebSocket start/stop on sign-in and scenePhase transitions
//   - One-shot HTTP catch-up on every successful (re)connect
//   - 3s background poll of contact requests so the tab badge stays fresh
//     even when the WebSocket is dropped
//   - Fan-out of WebSocket events to ContactRequestsViewModel,
//     ConversationsViewModel, and any open ChatView (via NotificationCenter)
struct RealtimeBootstrap: ViewModifier {

    let container: AppContainer

    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            // Distinct id keys so SwiftUI doesn't merge the two `.task` modifiers
            // — both depend on `isSignedIn` but do different work and need to
            // run independently when sign-in state flips.
            .task(id: "ws-lifecycle-\(container.sessionManager.isSignedIn)") {
                await handleSignInChange()
            }
            .onChange(of: scenePhase) { _, newValue in
                handleScenePhase(newValue)
            }
            .task {
                for await event in container.realtimeService.events {
                    await route(event)
                }
            }
            .task(id: "requests-poll-\(container.sessionManager.isSignedIn)") {
                await runContactRequestsBackgroundPoll()
            }
            .task {
                for await state in container.realtimeService.$connectionState.values {
                    // Defensive: only catch up when we expect to be authenticated.
                    // Stops a stale WebSocket reconnect during sign-out from
                    // firing unauthenticated HTTP calls.
                    if state == .connected, container.sessionManager.isSignedIn {
                        await catchUpFromHTTP()
                    }
                }
            }
    }

    private func handleSignInChange() async {
        if container.sessionManager.isSignedIn,
           let studentId = container.sessionManager.userId {
            container.realtimeService.start(studentId: studentId)
            await catchUpFromHTTP()
        } else {
            container.realtimeService.stop()
        }
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        guard container.sessionManager.isSignedIn else { return }

        switch phase {
        case .active:
            if let studentId = container.sessionManager.userId {
                container.realtimeService.start(studentId: studentId)
            }
        case .background:
            container.realtimeService.stop()
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    private func runContactRequestsBackgroundPoll() async {
        guard container.sessionManager.isSignedIn else { return }

        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(Self.contactRequestsPollIntervalSeconds))
            guard !Task.isCancelled, container.sessionManager.isSignedIn else { return }
            await container.contactRequestsViewModel.refreshSilently()
        }
    }

    // Per the handoff: "On connect/reconnect: Fetch contacts, conversations,
    // messages, and contact requests over HTTP." HTTP/MySQL is the source of
    // truth — the WebSocket only delivers live updates. ContactsViewModel is
    // a `@StateObject` inside `MessagesView` so we reach it via NotificationCenter
    // rather than promoting it into AppContainer.
    private func catchUpFromHTTP() async {
        await container.contactRequestsViewModel.loadRequests()
        await container.conversationsViewModel.refreshConversationsSilently()
        NotificationCenter.default.post(name: .realtimeContactsRefresh, object: nil)
    }

    private func route(_ event: RealtimeEvent) async {
        switch event {
        case let .newMessage(conversationId, message):
            await container.conversationsViewModel.handleRealtimeNewMessage(conversationId: conversationId)
            NotificationCenter.default.post(name: .realtimeNewMessage, object: message)

        case let .contactRequestChanged(change):
            container.contactRequestsViewModel.applyChange(change)
            if change.shouldRefreshContactRequests {
                await container.contactRequestsViewModel.refreshSilently()
            }
            if change.shouldRefreshContacts {
                NotificationCenter.default.post(name: .realtimeContactsRefresh, object: nil)
            }
            if change.shouldRefreshConversations {
                await container.conversationsViewModel.refreshConversationsSilently()
            }

        case .unknown:
            break
        }
    }

    private static let contactRequestsPollIntervalSeconds: Double = 3
}
