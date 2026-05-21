//
//  ForgotPasswordView.swift
//  CICompanion
//
//  Created by Wummiez on 4/15/26.
//

import SwiftUI
import Amplify

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss

    let sessionManager: SessionManager

    @State private var email = ""
    @State private var code = ""
    @State private var newPassword = ""
    @State private var sendEmail = true
    @State private var message = ""
    @State private var successMessage = ""
    @State private var confirmPassword = ""
    @State private var isSubmitting = false

    private var isFormValid: Bool {
        if sendEmail {
            return !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        return !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !newPassword.isEmpty
            && !confirmPassword.isEmpty
    }

    var body: some View {
        NavigationStack {
            CIView {
                HStack {
                    Spacer()

                    VStack {
                        Spacer()
                            .frame(height: AuthLayout.topSpacing)

                        Image("TeamKNOWN")
                            .resizable()
                            .scaledToFit()
                            .frame(width: AuthLayout.logoSize, height: AuthLayout.logoSize)
                            .padding(.bottom, ViewHelper.smallPadding)

                        CIPageTitle(sendEmail ? "Enter Your Email" : "Reset Password")
                            .padding(.bottom, ViewHelper.biggerSpacing)

                        if sendEmail {
                            Text("We'll send a 6-digit code to your inbox to reset your password.")
                                .font(.system(size: ViewHelper.textSize))
                                .foregroundColor(ViewHelper.text)
                                .multilineTextAlignment(.center)
                                .frame(width: ViewHelper.buttonWidth)
                                .padding(.bottom, ViewHelper.biggerSpacing)
                        } else if !email.isEmpty {
                            AuthCodeSentBanner(email: email)
                                .padding(.bottom, ViewHelper.biggerSpacing)
                        }

                        VStack(spacing: AuthLayout.fieldSpacing) {
                            if sendEmail {
                                CIItem(name: "Email") {
                                    AuthTextField(
                                        kind: .email,
                                        placeholder: "you@myci.csuci.edu",
                                        text: $email
                                    )
                                }
                            } else {
                                CIItem(name: "Code") {
                                    AuthTextField(
                                        kind: .code,
                                        placeholder: "6-digit code",
                                        text: $code
                                    )
                                }

                                CIItem(name: "New Password") {
                                    AuthSecureField(
                                        placeholder: "New password",
                                        text: $newPassword
                                    )
                                }

                                CIItem(name: "Confirm New Password") {
                                    AuthSecureField(
                                        placeholder: "Re-enter new password",
                                        text: $confirmPassword
                                    )
                                }
                            }
                        }
                        .frame(width: ViewHelper.buttonWidth)

                        if !message.isEmpty {
                            CIErrorMessage(errorMessage: message)
                        }

                        if !successMessage.isEmpty {
                            CIText(successMessage, color: ViewHelper.accentGreen)
                                .padding(.top, ViewHelper.smallPadding)
                        }

                        AuthPrimaryButton(
                            title: sendEmail ? "Send Code" : "Reset Password",
                            isLoading: isSubmitting,
                            isEnabled: isFormValid
                        ) {
                            Task {
                                isSubmitting = true
                                defer { isSubmitting = false }

                                do {
                                    if sendEmail {
                                        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            message = "Enter your email"
                                            return
                                        }

                                        _ = try await Amplify.Auth.resetPassword(for: email)

                                        sendEmail = false
                                        message = ""
                                    } else {
                                        if code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                            newPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                            confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            message = "Fill out all fields"
                                            return
                                        }

                                        if newPassword != confirmPassword {
                                            message = "Passwords do not match"
                                            return
                                        }

                                        try await Amplify.Auth.confirmResetPassword(
                                            for: email,
                                            with: newPassword,
                                            confirmationCode: code
                                        )

                                        message = ""
                                        successMessage = "Password reset confirmed"

                                        try await Task.sleep(for: .seconds(2))

                                        dismiss()
                                    }
                                } catch {
                                    successMessage = ""
                                    message = AuthErrorMessage.text(for: error)
                                }
                            }
                        }
                        .padding(.top, AuthLayout.buttonTopSpacing)

                        Spacer()

                        VStack(spacing: ViewHelper.smallPadding) {
                            CIText("Remember Password?", color: ViewHelper.text)

                            CITextButton(text: "Back to Sign In") {
                                dismiss()
                            }
                        }
                        .padding(.bottom, AuthLayout.topSpacing)
                    }

                    Spacer()
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

}

#Preview {
    ForgotPasswordView(sessionManager: SessionManager())
}
