//
//  MessageBubbleView.swift
//  CICompanion
//

import SwiftUI

struct MessageBubbleView: View {

    let message: Message
    let isCurrentUser: Bool

    var body: some View {
        HStack {
            if isCurrentUser { Spacer(minLength: 60) }

            Text(message.body)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isCurrentUser ? ViewHelper.currentUserColor : ViewHelper.otherUserColor)
                .cornerRadius(16)

            if !isCurrentUser { Spacer(minLength: 60) }
        }
    }
}
