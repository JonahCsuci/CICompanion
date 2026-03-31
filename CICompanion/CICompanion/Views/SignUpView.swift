//
//  LoginView.swift
//  CICompanion
//
//  Created by Wummiez on 3/28/26.
//

import SwiftUI
import Amplify

/*
struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var message = ""
    @State private var showConfirm = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Sign Up")
                .font(.title)
                .bold()

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            if !message.isEmpty {
                Text(message)
                    .foregroundColor(.red)
            }

            Button("Create Account") {
                Task {
                    do {
                        let result = try await Amplify.Auth.signUp(
                            username: email,
                            password: password,
                            options: .init(userAttributes: [
                                AuthUserAttribute(.email, value: email)
                            ])
                        )

                        print("Sign up result: \(result.nextStep)")
                        showConfirm = true

                    } catch let error as AuthError {
                        print("AuthError: \(error)")
                        print("Recovery suggestion: \(error.recoverySuggestion)")

                        let description = error.errorDescription.lowercased()

                        if description.contains("exists") || description.contains("already") {
                            message = "Account already exists. Please verify your email."
                            showConfirm = true
                        } else {
                            message = error.errorDescription
                        }

                    } catch {
                        message = error.localizedDescription
                        print(error)
                    }
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Close") {
                dismiss()
            }

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showConfirm) {
            ConfirmSignUpView(email: email)
        }
    }
}
*/
