//
//  RealtimeServiceTests.swift
//  CICompanionTests
//

import XCTest
@testable import CICompanion

@MainActor
final class RealtimeServiceTests: XCTestCase {

    func testReceivedFrameYieldsNewMessageEvent() async throws {
        let socket = FakeRealtimeSocket()
        let transport = FakeRealtimeTransport(socket: socket)
        let service = RealtimeService(transport: transport)

        service.start(studentId: "user-A")
        await waitForConnected(service)

        let json = #"""
        {
          "type": "new_message",
          "conversationId": 42,
          "message": {
            "id": 7,
            "conversationId": 42,
            "senderId": "user-B",
            "senderName": "B",
            "body": "hi",
            "createdAt": "2026-05-05T12:00:00Z"
          }
        }
        """#
        socket.push(.string(json))

        var iterator = service.events.makeAsyncIterator()
        let event = await iterator.next()

        guard case let .newMessage(conversationId, message) = event else {
            XCTFail("Expected .newMessage; got \(String(describing: event))")
            return
        }
        XCTAssertEqual(conversationId, 42)
        XCTAssertEqual(message.id, 7)
        XCTAssertEqual(message.body, "hi")

        service.stop()
    }

    func testReceivedFrameYieldsContactRequestChangedEvent() async throws {
        let socket = FakeRealtimeSocket()
        let transport = FakeRealtimeTransport(socket: socket)
        let service = RealtimeService(transport: transport)

        service.start(studentId: "user-B")
        await waitForConnected(service)

        let json = #"""
        {
          "type": "contact_request_changed",
          "action": "accepted",
          "requestId": 12,
          "status": "accepted",
          "requesterId": "user-A",
          "recipientId": "user-B",
          "conversationId": 34,
          "shouldRefreshContactRequests": true,
          "shouldRefreshContacts": true,
          "shouldRefreshConversations": true
        }
        """#
        socket.push(.string(json))

        var iterator = service.events.makeAsyncIterator()
        let event = await iterator.next()

        guard case let .contactRequestChanged(change) = event else {
            XCTFail("Expected .contactRequestChanged; got \(String(describing: event))")
            return
        }
        XCTAssertEqual(change.action, "accepted")
        XCTAssertEqual(change.requestId, 12)
        XCTAssertEqual(change.conversationId, 34)
        XCTAssertTrue(change.shouldRefreshContacts)

        service.stop()
    }

    func testReceivedDataFrameDecodesSameAsString() async throws {
        let socket = FakeRealtimeSocket()
        let transport = FakeRealtimeTransport(socket: socket)
        let service = RealtimeService(transport: transport)

        service.start(studentId: "user-C")
        await waitForConnected(service)

        let json = #"{"type":"contact_request_changed","action":"declined","requestId":99,"status":"declined","requesterId":"a","recipientId":"b","shouldRefreshContactRequests":true,"shouldRefreshContacts":false,"shouldRefreshConversations":false}"#
        socket.push(.data(Data(json.utf8)))

        var iterator = service.events.makeAsyncIterator()
        let event = await iterator.next()

        guard case let .contactRequestChanged(change) = event else {
            XCTFail("Expected .contactRequestChanged from data frame")
            return
        }
        XCTAssertEqual(change.action, "declined")
        XCTAssertEqual(change.requestId, 99)

        service.stop()
    }

    func testStopTransitionsToDisconnected() async throws {
        let socket = FakeRealtimeSocket()
        let transport = FakeRealtimeTransport(socket: socket)
        let service = RealtimeService(transport: transport)

        service.start(studentId: "user-A")
        await waitForConnected(service)
        XCTAssertEqual(service.connectionState, .connected)

        service.stop()
        XCTAssertEqual(service.connectionState, .disconnected)
    }

    func testStartIsIdempotentWhileConnected() async throws {
        let socket = FakeRealtimeSocket()
        let transport = FakeRealtimeTransport(socket: socket)
        let service = RealtimeService(transport: transport)

        service.start(studentId: "user-A")
        await waitForConnected(service)
        XCTAssertEqual(transport.openCallCount, 1)

        // Calling start() again while already connected should be a no-op.
        // Re-using waitForConnected (instead of an arbitrary sleep) means we
        // observe the steady state directly instead of guessing a timing window.
        service.start(studentId: "user-A")
        await waitForConnected(service)

        XCTAssertEqual(transport.openCallCount, 1, "start() should not reconnect when already connected")

        service.stop()
    }

    private func waitForConnected(_ service: RealtimeService, file: StaticString = #file, line: UInt = #line) async {
        for _ in 0..<50 {   // up to ~250ms
            if service.connectionState == .connected { return }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
        XCTAssertEqual(
            service.connectionState,
            .connected,
            "RealtimeService did not reach .connected within 250ms",
            file: file,
            line: line
        )
    }
}

@MainActor
private final class FakeRealtimeTransport: RealtimeTransport {
    let socket: FakeRealtimeSocket
    private(set) var openCallCount = 0

    init(socket: FakeRealtimeSocket) {
        self.socket = socket
    }

    func open(url: URL) -> RealtimeSocket {
        openCallCount += 1
        return socket
    }
}

@MainActor
private final class FakeRealtimeSocket: RealtimeSocket {
    private var pendingFrames: [Result<RealtimeFrame, Error>] = []
    private var pendingContinuations: [CheckedContinuation<RealtimeFrame, Error>] = []
    private var isClosed = false

    func push(_ frame: RealtimeFrame) {
        guard !isClosed else { return }
        if let continuation = pendingContinuations.first {
            pendingContinuations.removeFirst()
            continuation.resume(returning: frame)
        } else {
            pendingFrames.append(.success(frame))
        }
    }

    func receive() async throws -> RealtimeFrame {
        if !pendingFrames.isEmpty {
            return try pendingFrames.removeFirst().get()
        }
        return try await withCheckedThrowingContinuation { continuation in
            if isClosed {
                continuation.resume(throwing: URLError(.cancelled))
            } else {
                pendingContinuations.append(continuation)
            }
        }
    }

    func sendPing() async throws {}

    func close() {
        isClosed = true
        let waiting = pendingContinuations
        pendingContinuations.removeAll()
        for continuation in waiting {
            continuation.resume(throwing: URLError(.cancelled))
        }
    }
}
