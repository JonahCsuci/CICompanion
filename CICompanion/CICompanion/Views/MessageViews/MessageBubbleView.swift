//
//  MessageBubbleView.swift
//  CICompanion
//

import SwiftUI

struct MessageBubbleView: View {

    let message: Message
    let isCurrentUser: Bool
    var showSenderName: Bool = false
    var receiptText: String? = nil

    private let currentUserColor = Color(red: 0.30, green: 0.50, blue: 0.85)
    private let otherUserColor = Color(red: 0.55, green: 0.25, blue: 0.85)
    private let metaTextSize: CGFloat = 12
    private let bubbleSideInset: CGFloat = 60

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if isCurrentUser { Spacer(minLength: bubbleSideInset) }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 2) {
                if showSenderName, let senderName = message.senderName {
                    Text(senderName)
                        .font(.system(size: metaTextSize))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 4)
                }

                Text(message.body)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isCurrentUser ? currentUserColor : otherUserColor)
                    .cornerRadius(16)

                if let receiptText {
                    Text(receiptText)
                        .font(.system(size: metaTextSize))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 4)
                }
            }

            if !isCurrentUser { Spacer(minLength: bubbleSideInset) }
        }
    }
}
