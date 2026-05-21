//
//  SignInView.swift
//  CICompanion
//
//  Created by Wummiez on 3/30/26.
//

import SwiftUI
import Amplify

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss

    let sessionManager: SessionManager

    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var message = ""
    @State private var showConfirmSignUp = false
    @State private var isSigningIn = false

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
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

                        CIPageTitle("Enter Your Details")
                            .padding(.bottom, ViewHelper.biggerSpacing)

                        VStack(spacing: AuthLayout.fieldSpacing) {
                            CIItem(name: "Email") {
                                AuthTextField(
                                    kind: .email,
                                    placeholder: "you@myci.csuci.edu",
                                    text: $email
                                )
                            }

                            CIItem(name: "Password") {
                                AuthSecureField(
                                    placeholder: "Enter your password",
                                    text: $password
                                )
                            }
                        }
                        .frame(width: ViewHelper.buttonWidth)

                        if !message.isEmpty {
                            CIErrorMessage(errorMessage: message)
                        }

                        AuthPrimaryButton(
                            title: "Sign In",
                            isLoading: isSigningIn,
                            isEnabled: isFormValid
                        ) {
                            Task {
                                isSigningIn = true
                                defer { isSigningIn = false }

                                do {
                                    // A session may already be active (e.g. resumed from a
                                    // previous launch). Signing in over it throws
                                    // AuthError.invalidState, so keep the valid session and
                                    // continue instead of failing a correct login.
                                    if let activeSession = try? await Amplify.Auth.fetchAuthSession(),
                                       activeSession.isSignedIn {
                                        await sessionManager.loadCurrentUser()
                                        dismiss()
                                        return
                                    }

                                    let result = try await Amplify.Auth.signIn(
                                        username: email,
                                        password: password
                                    )

                                    if result.isSignedIn {
                                        await sessionManager.loadCurrentUser()

                                        do {
                                            let repo = APIStudentRepository(sessionManager: sessionManager)
                                            _ = try await repo.ensureStudentExists()
                                        } catch {
                                            print("ensureStudentExists after sign-in failed:", error)
                                        }

                                        dismiss()
                                    } else {
                                        switch result.nextStep {
                                        case .confirmSignUp(_):
                                            message = "Confirm your account"
                                            showConfirmSignUp = true
                                        default:
                                            message = "Next step required"
                                        }
                                    }
                                } catch {
                                    message = AuthErrorMessage.text(for: error)
                                }
                            }
                        }
                        .padding(.top, AuthLayout.buttonTopSpacing)

                        NavigationLink("Need to reset password?") {
                            ForgotPasswordView(sessionManager: sessionManager)
                        }
                        .font(.system(size: ViewHelper.textSize))
                        .padding(.top, ViewHelper.padding)
                        .foregroundColor(ViewHelper.accentBlue)

                        Spacer()

                        VStack(spacing: ViewHelper.smallPadding) {
                            CIText("Don't have an account?", color: ViewHelper.text)

                            NavigationLink("Create Account") {
                                SignUpView(sessionManager: sessionManager)
                            }
                            .font(.system(size: ViewHelper.textSize, weight: .semibold))
                            .foregroundColor(ViewHelper.accentBlue)
                        }
                        .padding(.bottom, AuthLayout.topSpacing)
                    }

                    Spacer()
                }
            }
            .navigationDestination(isPresented: $showConfirmSignUp) {
                ConfirmSignUpView(
                    email: email,
                    name: name,
                    sessionManager: sessionManager
                )
            }
        }
    }
}

#Preview {
    SignInView(sessionManager: SessionManager())
}
