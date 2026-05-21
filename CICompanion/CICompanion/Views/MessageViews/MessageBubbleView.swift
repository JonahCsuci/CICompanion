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

    private let currentUserColor = ViewHelper.currentUserColor
    private let otherUserColor = ViewHelper.otherUserColor
    private let metaTextSize: CGFloat = 12
    private let metaHorizontalInset: CGFloat = 4
    private let metaStackSpacing: CGFloat = 2
    private let bubbleTextSize: CGFloat = 16
    private let bubbleHorizontalPadding: CGFloat = 14
    private let bubbleVerticalPadding: CGFloat = 10
    private let bubbleCornerRadius: CGFloat = 16
    private let bubbleSideInset: CGFloat = 60
    private let imageBubbleSize: CGFloat = 220
    private let imagePlaceholderIconSize: CGFloat = 32

    @State private var showFullImage = false

    private var imageURL: URL? {
        message.imageURL.flatMap { URL(string: $0) }
    }

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

                if let imageURL {
                    imageBubble(imageURL)
                }

                if !message.body.isEmpty {
                    Text(message.body)
                        .font(.system(size: bubbleTextSize))
                        .foregroundColor(.white)
                        .padding(.horizontal, bubbleHorizontalPadding)
                        .padding(.vertical, bubbleVerticalPadding)
                        .background(isCurrentUser ? currentUserColor : otherUserColor)
                        .cornerRadius(bubbleCornerRadius)
                }

                if let receiptText {
                    Text(receiptText)
                        .font(.system(size: metaTextSize))
                        .foregroundColor(.gray)
                        .padding(.horizontal, metaHorizontalInset)
                }
            }

            if !isCurrentUser { Spacer(minLength: bubbleSideInset) }
        }
        .fullScreenCover(isPresented: $showFullImage) {
            if let imageURL {
                FullScreenImageView(imageURL: imageURL)
            }
        }
    }

    private func imageBubble(_ url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                Image(systemName: "photo")
                    .font(.system(size: imagePlaceholderIconSize))
                    .foregroundColor(.gray)
            case .empty:
                ProgressView()
                    .tint(.white)
            @unknown default:
                EmptyView()
            }
        }
        .frame(width: imageBubbleSize, height: imageBubbleSize)
        .background(otherUserColor)
        .clipShape(RoundedRectangle(cornerRadius: bubbleCornerRadius))
        .onTapGesture {
            showFullImage = true
        }
    }
}
