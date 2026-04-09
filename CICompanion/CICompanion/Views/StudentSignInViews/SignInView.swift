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
    
    private let bgColor = Color(red: 0.08, green: 0.10, blue: 0.15)

    var body: some View {
        NavigationStack {
            CIView {
                HStack {
                    Spacer()
                    VStack {
                        Spacer().frame(height: 30)
                        
                        Image("dolphin")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .padding(.bottom, 12)
                        
                        Text("Enter Your Details")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.bottom, 30)
                        
                        VStack(spacing: 16) {
                            
                            VStack(alignment: .leading, spacing: 8) {
                                
                                Text("Email")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 320, alignment: .leading)
                                
                                TextField("", text: $email)
                                    .font(.system(size: ViewHelper.textSize))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .padding(ViewHelper.padding)
                                    .background(ViewHelper.fieldBgColor)
                                    .cornerRadius(ViewHelper.componentRounding)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .keyboardType(.emailAddress)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 320, alignment: .leading)
                                
                                SecureField("", text: $password)
                                    .font(.system(size: ViewHelper.textSize))
                                    .foregroundColor(.white)
                                    .padding(ViewHelper.padding)
                                    .background(ViewHelper.fieldBgColor)
                                    .cornerRadius(ViewHelper.componentRounding)
                            }
                        }
                        
                        if !message.isEmpty {
                            Text(message)
                                .foregroundColor(.red)
                                .padding(.top, 12)
                        }
                        
                        Button {
                            Task {
                                do {
                                    let result = try await Amplify.Auth.signIn (
                                        username: email,
                                        password: password
                                    )

                                    // If sign in worked, assign user id
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
                                        
                                        // If user didn't previously confirm security code
                                        switch result.nextStep {
                                        case .confirmSignUp(_):
                                            message = "Confirm your account"
                                            showConfirmSignUp = true
                                        default:
                                            message = "Next step required"
                                        }
                                    }
                                } catch {
                                    message = "Email and Password required"
                                }
                            }
                        } label: {
                            Text("Sign in")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 320, height: 50)
                                .background(Color(red: 0.36, green: 0.55, blue: 0.90))
                                .cornerRadius(8)
                        }
                        .padding(.top, 24)
                        
                        Spacer()
                        
                        Text("Don't have an account?")
                            .foregroundColor(.gray)
                            .font(.system(size: 18))
                        
                        NavigationLink("Create Account") {
                            SignUpView(sessionManager: self.sessionManager)
                        }
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.90))
                        
                        Spacer()
                    }
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $showConfirmSignUp) {
                ConfirmSignUpView(email: email, name: name, sessionManager: self.sessionManager)
            }
        }
    }
}
