//
//  LoginView.swift
//  CICompanion
//
//  Created by Wummiez on 3/28/26.
//

import SwiftUI
import Amplify

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss

    let sessionManager: SessionManager

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var message = ""
    @State private var showConfirm = false
    @State private var isSubmitting = false

    private var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && !password.isEmpty
    }

    var body: some View {
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

                    CIPageTitle("Create Your Account")
                        .padding(.bottom, ViewHelper.biggerSpacing)

                    VStack(spacing: AuthLayout.fieldSpacing) {
                        CIItem(name: "Name") {
                            AuthTextField(
                                kind: .name,
                                placeholder: "Your full name",
                                text: $name
                            )
                        }

                        CIItem(name: "Email") {
                            AuthTextField(
                                kind: .email,
                                placeholder: "you@myci.csuci.edu",
                                text: $email
                            )
                        }

                        CIItem(name: "Password") {
                            AuthSecureField(
                                placeholder: "Create a password",
                                text: $password
                            )
                        }
                    }
                    .frame(width: ViewHelper.buttonWidth)

                    if !message.isEmpty {
                        CIErrorMessage(errorMessage: message)
                    }

                    AuthPrimaryButton(
                        title: "Create Account",
                        isLoading: isSubmitting,
                        isEnabled: isFormValid
                    ) {
                        Task {
                            isSubmitting = true
                            defer { isSubmitting = false }

                            do {
                                let result = try await Amplify.Auth.signUp(
                                    username: email,
                                    password: password,
                                    options: .init(userAttributes: [
                                        AuthUserAttribute(.email, value: email),
                                        AuthUserAttribute(.name, value: name)
                                    ])
                                )

                                print("Sign up result: \(result.nextStep)")
                                showConfirm = true
                            } catch {
                                if AuthErrorMessage.isAccountAlreadyExists(error) {
                                    message = "Account already exists. Please verify your email."
                                    showConfirm = true
                                } else {
                                    message = AuthErrorMessage.text(for: error)
                                }
                            }
                        }
                    }
                    .padding(.top, AuthLayout.buttonTopSpacing)

                    Spacer()

                    VStack(spacing: ViewHelper.smallPadding) {
                        CIText("Already have an account?", color: ViewHelper.text)

                        CITextButton(text: "Back to Sign In") {
                            dismiss()
                        }
                    }
                    .padding(.bottom, AuthLayout.topSpacing)
                }

                Spacer()
            }
        }
        .sheet(isPresented: $showConfirm) {
            ConfirmSignUpView(
                email: email,
                name: name,
                sessionManager: sessionManager
            ) {
                dismiss()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}
