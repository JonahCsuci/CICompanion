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

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if isCurrentUser { Spacer(minLength: ViewHelper.Messaging.bubbleSideInset) }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: ViewHelper.Messaging.metaStackSpacing) {
                if showSenderName, let senderName = message.senderName {
                    Text(senderName)
                        .font(.system(size: ViewHelper.Messaging.metaTextSize))
                        .foregroundColor(.gray)
                        .padding(.horizontal, ViewHelper.Messaging.metaHorizontalInset)
                }

                Text(message.body)
                    .font(.system(size: ViewHelper.Messaging.bubbleTextSize))
                    .foregroundColor(.white)
                    .padding(.horizontal, ViewHelper.Messaging.bubbleHorizontalPadding)
                    .padding(.vertical, ViewHelper.Messaging.bubbleVerticalPadding)
                    .background(isCurrentUser ? ViewHelper.Messaging.currentUserBubbleColor : ViewHelper.Messaging.otherUserBubbleColor)
                    .cornerRadius(ViewHelper.Messaging.bubbleCornerRadius)

                if let receiptText {
                    Text(receiptText)
                        .font(.system(size: ViewHelper.Messaging.metaTextSize))
                        .foregroundColor(.gray)
                        .padding(.horizontal, ViewHelper.Messaging.metaHorizontalInset)
                }
            }

            if !isCurrentUser { Spacer(minLength: ViewHelper.Messaging.bubbleSideInset) }
        }
    }
}
