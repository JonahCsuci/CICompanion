//
//  FullScreenImageView.swift
//  CICompanion
//

import SwiftUI

struct FullScreenImageView: View {
    let imageURL: URL

    @Environment(\.dismiss) private var dismiss

    private let closeButtonSize: CGFloat = 30
    private let failureIconSize: CGFloat = 40

    var body: some View {
        ZStack {
            ViewHelper.bgColor.ignoresSafeArea()

            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: failureIconSize))
                        .foregroundColor(ViewHelper.textImportant)
                case .empty:
                    ProgressView()
                        .tint(ViewHelper.textImportant)
                @unknown default:
                    EmptyView()
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            dismiss()
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: closeButtonSize))
                    .foregroundColor(ViewHelper.textImportant)
            }
            .padding(ViewHelper.padding)
        }
    }
}
