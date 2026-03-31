//
//  AuthEntryView.swift
//  CICompanion
//
//  Created by Wummiez on 3/30/26.
//

import SwiftUI

/*
struct AuthEntryView: View {
    @ObservedObject var sessionManager: SessionManager
    
    @State private var showSignUp = false
    @State private var showSignIn = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome")
                .font(.largeTitle)
                .bold()

            Button("Create Account") {
                showSignUp = true
            }
            .buttonStyle(.borderedProminent)

            Button("Sign In") {
                showSignIn = true
            }
            .buttonStyle(.bordered)

            if sessionManager.isSignedIn {
                Text("✅ Signed In")
                    .foregroundColor(.green)
            } else {
                Text("❌ Not Signed In")
                    .foregroundColor(.red)
            }

            if let userId = sessionManager.userId {
                Text("User ID: \(userId)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .sheet(isPresented: $showSignUp) {
            SignUpView()
        }
        .sheet(isPresented: $showSignIn) {
            SignInView(sessionManager: sessionManager)
        }
        .task {
            await sessionManager.loadCurrentUser()
        }
    }
}
*/
