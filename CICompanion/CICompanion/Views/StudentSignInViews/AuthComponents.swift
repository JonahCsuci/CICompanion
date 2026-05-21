//
//  AuthComponents.swift
//  CICompanion
//
//  Shared building blocks for the authentication screens (sign in, sign up,
//  forgot password). Kept in its own file so the larger auth layout does not
//  change every other screen that relies on `ViewHelper`.
//

import SwiftUI
import UIKit

// Sizing shared by the authentication screens.
enum AuthLayout {
    static let logoSize = 132.0
    static let topSpacing = 24.0
    static let fieldSpacing = 20.0
    static let buttonTopSpacing = 28.0
    static let buttonHeight = 58.0
    static let buttonRounding = 16.0
    static let disabledButtonOpacity = 0.5
    static let focusAnimationDuration = 0.15
    static let successIconSize = 56.0
}

// Field background that lights up with an accent border while the field is focused.
struct AuthFieldChrome: ViewModifier {
    let isFocused: Bool

    func body(content: Content) -> some View {
        content
            .padding(ViewHelper.padding)
            .background(ViewHelper.fieldBgColor)
            .cornerRadius(ViewHelper.componentRounding)
            .overlay(
                RoundedRectangle(cornerRadius: ViewHelper.componentRounding)
                    .stroke(
                        isFocused ? ViewHelper.accentBlue : Color.clear,
                        lineWidth: ViewHelper.borderWidth
                    )
            )
            .animation(
                .easeInOut(duration: AuthLayout.focusAnimationDuration),
                value: isFocused
            )
    }
}

// The kinds of single-line text input used across the auth screens.
enum AuthFieldKind {
    case name
    case email
    case code

    var keyboardType: UIKeyboardType {
        switch self {
        case .name: return .default
        case .email: return .emailAddress
        case .code: return .numberPad
        }
    }

    var contentType: UITextContentType {
        switch self {
        case .name: return .name
        case .email: return .emailAddress
        case .code: return .oneTimeCode
        }
    }

    var capitalization: TextInputAutocapitalization {
        switch self {
        case .name: return .words
        case .email, .code: return .never
        }
    }
}

// Single-line text field with a focus border, configured for its input kind.
struct AuthTextField: View {
    let kind: AuthFieldKind
    let placeholder: String
    @Binding var text: String

    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(
            "",
            text: $text,
            prompt: Text(placeholder).foregroundColor(ViewHelper.text)
        )
        .font(.system(size: ViewHelper.textSize))
        .foregroundColor(ViewHelper.textImportant)
        .keyboardType(kind.keyboardType)
        .textContentType(kind.contentType)
        .textInputAutocapitalization(kind.capitalization)
        .autocorrectionDisabled(true)
        .focused($isFocused)
        .modifier(AuthFieldChrome(isFocused: isFocused))
    }
}

// Secure field with a focus border and a tap-to-reveal toggle.
struct AuthSecureField: View {
    let placeholder: String
    @Binding var text: String

    @State private var isRevealed = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: ViewHelper.spacing) {
            Group {
                if isRevealed {
                    TextField("", text: $text, prompt: promptText)
                } else {
                    SecureField("", text: $text, prompt: promptText)
                }
            }
            .font(.system(size: ViewHelper.textSize))
            .foregroundColor(ViewHelper.textImportant)
            .textContentType(.password)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .focused($isFocused)

            Button {
                let wasFocused = isFocused
                isRevealed.toggle()
                isFocused = wasFocused
            } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .font(.system(size: ViewHelper.textSize))
                    .foregroundColor(ViewHelper.text)
            }
            .buttonStyle(.plain)
        }
        .modifier(AuthFieldChrome(isFocused: isFocused))
    }

    private var promptText: Text {
        Text(placeholder).foregroundColor(ViewHelper.text)
    }
}

// Full-width primary action button with loading and disabled states.
struct AuthPrimaryButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    private var isActive: Bool { isEnabled && !isLoading }

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(ViewHelper.textImportant)
                } else {
                    Text(title)
                        .font(.system(size: ViewHelper.buttonTextSize, weight: .bold))
                        .foregroundColor(ViewHelper.textImportant)
                }
            }
            .frame(width: ViewHelper.buttonWidth, height: AuthLayout.buttonHeight)
            .background(
                ViewHelper.accentBlue.opacity(isActive ? 1.0 : AuthLayout.disabledButtonOpacity)
            )
            .cornerRadius(AuthLayout.buttonRounding)
        }
        .disabled(!isActive)
    }
}

// Rounded banner confirming which address a verification code was sent to.
struct AuthCodeSentBanner: View {
    let email: String

    var body: some View {
        HStack(alignment: .top, spacing: ViewHelper.spacing) {
            Image(systemName: "envelope")
                .font(.system(size: ViewHelper.textSize))
                .foregroundColor(ViewHelper.text)

            Text("Code sent to \(email)")
                .font(.system(size: ViewHelper.smallTextSize))
                .foregroundColor(ViewHelper.text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(ViewHelper.padding)
        .frame(width: ViewHelper.buttonWidth)
        .background(ViewHelper.fieldBgColor)
        .cornerRadius(ViewHelper.componentRounding)
    }
}
