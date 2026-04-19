//
//  MessageBubbleView.swift
//  CICompanion
//

import SwiftUI

struct MessageBubbleView: View {

    let message: Message
    let isCurrentUser: Bool
    let isLatestOutgoing: Bool
    let conversationType: String

    private let currentUserColor = Color(red: 0.30, green: 0.50, blue: 0.85)
    private let otherUserColor = Color(red: 0.55, green: 0.25, blue: 0.85)

    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
            HStack {
                if isCurrentUser { Spacer(minLength: 60) }

                Text(message.body)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isCurrentUser ? currentUserColor : otherUserColor)
                    .cornerRadius(16)

                if !isCurrentUser { Spacer(minLength: 60) }
            }

            if isLatestOutgoing && isCurrentUser {
                Text(receiptText)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .padding(.horizontal, isCurrentUser ? 14 : 0)
            }
        }
    }

    private var receiptText: String {
        if conversationType == "group" {
            if let readBy = message.readBy, !readBy.isEmpty {
                let names = readBy.map(\.name).joined(separator: ", ")
                return "Seen by \(names)"
            }
            return ""
        } else {
            switch message.deliveryStatus {
            case .seen:
                return "Seen"
            case .delivered:
                return "Delivered"
            case .sent:
                return "Sent"
            case .none:
                return ""
            }
        }
    }
}
