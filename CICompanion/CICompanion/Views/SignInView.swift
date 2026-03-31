//
//  SignInView.swift
//  CICompanion
//
//  Created by Wummiez on 3/30/26.
//

import SwiftUI
import Amplify

/*
struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    
    let sessionManager: SessionManager

    @State private var email = ""
    @State private var password = ""
    @State private var message = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Sign In")
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

            Button("Sign In") {
                Task {
                    do {
                        let session = try await Amplify.Auth.fetchAuthSession()

                        if session.isSignedIn {
                            let user = try await Amplify.Auth.getCurrentUser()
                            sessionManager.setSignedInUser(id: user.userId)
                            message = "Restored previous signed-in session"
                            dismiss()
                            return
                        }

                        let result = try await Amplify.Auth.signIn(
                            username: email,
                            password: password
                        )

                        if result.isSignedIn {
                            let user = try await Amplify.Auth.getCurrentUser()
                            sessionManager.setSignedInUser(id: user.userId)
                            dismiss()
                        } else {
                            message = "Next step required: \(result.nextStep)"
                            print("Sign in next step: \(result.nextStep)")
                        }
                    } catch let error as AuthError {
                        print("AuthError: \(error)")
                        print("Description: \(error.errorDescription)")
                        print("Recovery: \(error.recoverySuggestion)")
                        print("Underlying: \(String(describing: error.underlyingError))")
                        message = error.errorDescription
                    } catch {
                        print("Other error: \(error)")
                        message = error.localizedDescription
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
    }
}
*/
