//
//  SwipeToDeleteRow.swift
//  CICompanion
//
//  A generic wrapper that adds a left-swipe-to-delete interaction to any content.
//

import SwiftUI

/// A generic wrapper that adds a left-swipe → delete interaction to any content.
///
/// Wrapping content in this view adds a drag gesture that reveals a red
/// trash button. The caller provides the `onDelete` closure.
struct SwipeToDeleteRow<Content: View>: View {

    let onDelete: () -> Void
    @ViewBuilder let content: Content

    @State private var offset: CGFloat = 0
    @State private var isRevealed = false

    var body: some View {
        ZStack(alignment: .trailing) {
            deleteButton
            swipeableContent
        }
        .clipped()
    }

    /// The red trash button sitting behind the content.
    private var deleteButton: some View {
        HStack {
            Spacer()
            Button {
                withAnimation(.easeInOut(duration: AppTheme.defaultAnimationDuration)) {
                    onDelete()
                    offset = 0
                    isRevealed = false
                }
            } label: {
                Image(systemName: "trash.fill")
                    .font(AppTheme.Fonts.iconAction)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .frame(width: 50, height: 36)
                    .background(AppTheme.Colors.error)
                    .cornerRadius(8)
            }
        }
    }

    /// The foreground content that slides left on drag.
    private var swipeableContent: some View {
        content
            .background(AppTheme.Colors.cardBackground)
            .offset(x: offset)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        withAnimation(.easeInOut(duration: AppTheme.defaultAnimationDuration)) {
                            if value.translation.width < AppTheme.Spacing.swipeDeleteThreshold {
                                offset = AppTheme.Spacing.swipeDeleteThreshold
                                isRevealed = true
                            } else {
                                offset = 0
                                isRevealed = false
                            }
                        }
                    }
            )
    }
}
