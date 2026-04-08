//
//  MessageBubbleView.swift
//  CICompanion
//

import SwiftUI

struct MessageBubbleView: View {

    let message: Message
    let isCurrentUser: Bool

    private let currentUserColor = Color(red: 0.30, green: 0.50, blue: 0.85)
    private let otherUserColor = Color(red: 0.55, green: 0.25, blue: 0.85)

    var body: some View {
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
    }
}
