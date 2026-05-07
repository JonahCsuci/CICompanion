//
//  RealtimeService.swift
//  CICompanion
//

import Foundation
import Combine

enum RealtimeFrame: Sendable {
    case data(Data)
    case string(String)
}

@MainActor
protocol RealtimeSocket: AnyObject {
    func receive() async throws -> RealtimeFrame
    func sendPing() async throws
    func close()
}

@MainActor
protocol RealtimeTransport {
    func open(url: URL) -> RealtimeSocket
}

// Receive-only WebSocket client for the CIApp realtime channel. The server pushes
// `new_message` and `contact_request_changed` events; iOS never sends frames
// (the WebSocket API only has $connect / $disconnect / $default routes).
//
// Lifecycle is owned externally by `RealtimeBootstrap`: start/stop on sign-in,
// scenePhase transitions. Reconnect is a flat 3s delay (demo-friendly) and pings
// fire every 3s to defeat idle disconnects. `connectionState` is published
// solely for tests and the catch-up trigger; no UI binds to it.
@MainActor
final class RealtimeService: ObservableObject {

    enum ConnectionState: Sendable {
        case disconnected
        case connecting
        case connected
        case reconnecting
    }

    private static let baseWebSocketURL = "wss://o2lm22178g.execute-api.us-west-1.amazonaws.com/production"
    private static let reconnectDelaySeconds: Double = 3
    private static let pingIntervalSeconds: Double = 3

    @Published private(set) var connectionState: ConnectionState = .disconnected

    let events: AsyncStream<RealtimeEvent>

    private let transport: RealtimeTransport
    private let eventsContinuation: AsyncStream<RealtimeEvent>.Continuation
    private var receiveTask: Task<Void, Never>?
    private var pingTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var currentSocket: RealtimeSocket?
    private var currentStudentId: String?

    init(transport: RealtimeTransport = URLSessionRealtimeTransport()) {
        self.transport = transport
        var continuation: AsyncStream<RealtimeEvent>.Continuation!
        self.events = AsyncStream { c in continuation = c }
        self.eventsContinuation = continuation
    }

    func start(studentId: String) {
        currentStudentId = studentId
        guard connectionState != .connected, connectionState != .connecting else { return }
        connect()
    }

    func stop() {
        currentStudentId = nil
        cancelAllTasks()
        currentSocket?.close()
        currentSocket = nil
        connectionState = .disconnected
    }

    private func connect() {
        guard let studentId = currentStudentId else { return }

        // Defensive: if a prior `connect()` left a socket attached (e.g., a
        // rapid scenePhase transition or a stale reconnect path), close and
        // discard it before opening a new one so the old WebSocket can't leak.
        cancelAllTasks()
        currentSocket?.close()
        currentSocket = nil

        connectionState = .connecting

        var components = URLComponents(string: Self.baseWebSocketURL)
        components?.queryItems = [URLQueryItem(name: "studentId", value: studentId)]
        guard let url = components?.url else {
            scheduleReconnect()
            return
        }

        let socket = transport.open(url: url)
        currentSocket = socket

        receiveTask = Task { [weak self] in
            await self?.runReceiveLoop()
        }

        pingTask = Task { [weak self] in
            await self?.runPingLoop()
        }
    }

    private func runReceiveLoop() async {
        guard let socket = currentSocket else { return }
        connectionState = .connected

        while !Task.isCancelled {
            do {
                let frame = try await socket.receive()
                let data: Data
                switch frame {
                case let .data(value): data = value
                case let .string(value): data = value.data(using: .utf8) ?? Data()
                }
                eventsContinuation.yield(RealtimeEvent.decode(from: data))
            } catch {
                handleSocketFailure()
                return
            }
        }
    }

    private func runPingLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(Self.pingIntervalSeconds))
            guard !Task.isCancelled, let socket = currentSocket else { return }
            try? await socket.sendPing()
        }
    }

    private func handleSocketFailure() {
        guard currentStudentId != nil else { return }   // stop() was called

        cancelAllTasks()
        currentSocket?.close()
        currentSocket = nil
        connectionState = .reconnecting
        scheduleReconnect()
    }

    private func scheduleReconnect() {
        reconnectTask?.cancel()
        reconnectTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.reconnectDelaySeconds))
            guard !Task.isCancelled else { return }
            await self?.connect()
        }
    }

    private func cancelAllTasks() {
        receiveTask?.cancel()
        pingTask?.cancel()
        reconnectTask?.cancel()
        receiveTask = nil
        pingTask = nil
        reconnectTask = nil
    }
}

// MARK: - URLSession-backed default transport

// `init` is intentionally nonisolated so it can serve as the default-arg
// expression for `RealtimeService.init`. The `open(url:)` method is already
// MainActor-isolated through the `RealtimeTransport` protocol.
final class URLSessionRealtimeTransport: RealtimeTransport {
    nonisolated init() {}

    func open(url: URL) -> RealtimeSocket {
        let task = URLSession.shared.webSocketTask(with: url)
        task.resume()
        return URLSessionRealtimeSocket(task: task)
    }
}

@MainActor
final class URLSessionRealtimeSocket: RealtimeSocket {
    private let task: URLSessionWebSocketTask

    init(task: URLSessionWebSocketTask) {
        self.task = task
    }

    func receive() async throws -> RealtimeFrame {
        let message = try await task.receive()
        switch message {
        case let .data(data): return .data(data)
        case let .string(string): return .string(string)
        @unknown default: return .data(Data())
        }
    }

    func sendPing() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            task.sendPing { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func close() {
        task.cancel(with: .goingAway, reason: nil)
    }
}
