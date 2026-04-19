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
    private let metaHorizontalInset: CGFloat = 4
    private let metaStackSpacing: CGFloat = 2
    private let bubbleTextSize: CGFloat = 16
    private let bubbleHorizontalPadding: CGFloat = 14
    private let bubbleVerticalPadding: CGFloat = 10
    private let bubbleCornerRadius: CGFloat = 16
    private let bubbleSideInset: CGFloat = 60

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if isCurrentUser { Spacer(minLength: bubbleSideInset) }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: metaStackSpacing) {
                if showSenderName, let senderName = message.senderName {
                    Text(senderName)
                        .font(.system(size: metaTextSize))
                        .foregroundColor(.gray)
                        .padding(.horizontal, metaHorizontalInset)
                }

                Text(message.body)
                    .font(.system(size: bubbleTextSize))
                    .foregroundColor(.white)
                    .padding(.horizontal, bubbleHorizontalPadding)
                    .padding(.vertical, bubbleVerticalPadding)
                    .background(isCurrentUser ? currentUserColor : otherUserColor)
                    .cornerRadius(bubbleCornerRadius)

                if let receiptText {
                    Text(receiptText)
                        .font(.system(size: metaTextSize))
                        .foregroundColor(.gray)
                        .padding(.horizontal, metaHorizontalInset)
                }
            }

            if !isCurrentUser { Spacer(minLength: bubbleSideInset) }
        }
    }
}
