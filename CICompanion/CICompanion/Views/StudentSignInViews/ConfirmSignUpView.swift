//
//  ConfirmSignUpView.swift
//  CICompanion
//

import SwiftUI
import Amplify

struct ConfirmSignUpView: View {
    @Environment(\.dismiss) private var dismiss

    let email: String
    let name: String
    let sessionManager: SessionManager

    // Called once the account is verified, so a presenting screen (e.g. Sign Up)
    // can also dismiss itself and return the user to Sign In.
    var onVerified: () -> Void = {}

    @State private var code = ""
    @State private var message = ""
    @State private var noticeText = ""
    @State private var isVerifying = false
    @State private var isVerified = false

    var body: some View {
        CIView {
            HStack {
                Spacer()

                if isVerified {
                    verifiedContent
                } else {
                    formContent
                }

                Spacer()
            }
        }
    }

    private var formContent: some View {
        VStack {
            Spacer()
                .frame(height: AuthLayout.topSpacing)

            Image("TeamKNOWN")
                .resizable()
                .scaledToFit()
                .frame(width: AuthLayout.logoSize, height: AuthLayout.logoSize)
                .padding(.bottom, ViewHelper.smallPadding)

            CIPageTitle("Verify Email")
                .padding(.bottom, ViewHelper.biggerSpacing)

            AuthCodeSentBanner(email: email)
                .padding(.bottom, ViewHelper.biggerSpacing)

            VStack(spacing: AuthLayout.fieldSpacing) {
                CIItem(name: "Verification Code") {
                    AuthTextField(
                        kind: .code,
                        placeholder: "6-digit code",
                        text: $code
                    )
                }
            }
            .frame(width: ViewHelper.buttonWidth)

            if !message.isEmpty {
                CIErrorMessage(errorMessage: message)
            }

            if !noticeText.isEmpty {
                CIText(noticeText, color: ViewHelper.accentGreen)
                    .padding(.top, ViewHelper.smallPadding)
            }

            AuthPrimaryButton(
                title: "Verify",
                isLoading: isVerifying,
                isEnabled: !code.isEmpty
            ) {
                verify()
            }
            .padding(.top, AuthLayout.buttonTopSpacing)

            CITextButton(text: "Resend Code") {
                resendCode()
            }
            .padding(.top, ViewHelper.smallPadding)

            Spacer()

            CITextButton(text: "Cancel") {
                dismiss()
            }
            .padding(.bottom, AuthLayout.topSpacing)
        }
    }

    private var verifiedContent: some View {
        VStack(spacing: ViewHelper.biggerSpacing) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: AuthLayout.successIconSize))
                .foregroundColor(ViewHelper.accentGreen)

            CIPageTitle("Account verified!")

            CIText("Taking you to sign in…", color: ViewHelper.text)

            Spacer()
        }
    }

    private func verify() {
        Task {
            isVerifying = true
            defer { isVerifying = false }

            do {
                let result = try await Amplify.Auth.confirmSignUp(
                    for: email,
                    confirmationCode: code
                )

                guard result.isSignUpComplete else {
                    message = "Verification incomplete. Please try again."
                    return
                }

                message = ""
                noticeText = ""

                // Make sure the student row exists in the SQL backend.
                do {
                    let repo = APIStudentRepository(sessionManager: sessionManager)
                    _ = try await repo.ensureStudentExists()
                } catch {
                    print("ensureStudentExists failed:", error)
                }

                withAnimation {
                    isVerified = true
                }

                try? await Task.sleep(for: .seconds(1.5))

                onVerified()
                dismiss()
            } catch {
                message = AuthErrorMessage.text(for: error)
                print("Confirm error:", error)
            }
        }
    }

    private func resendCode() {
        Task {
            do {
                let result = try await Amplify.Auth.resendSignUpCode(for: email)
                message = ""
                noticeText = "Code resent to \(result.destination)"
            } catch {
                noticeText = ""
                message = "Failed to resend code"
                print("Resend error:", error)
            }
        }
    }
}

#Preview {
    ConfirmSignUpView(
        email: "student@myci.csuci.edu",
        name: "Alex Rivera",
        sessionManager: SessionManager()
    )
}
