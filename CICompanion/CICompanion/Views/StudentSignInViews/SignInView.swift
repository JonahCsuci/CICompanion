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
    
    var body: some View {
        NavigationStack {
            CIView {
                HStack {
                    Spacer()
                    
                    VStack {
                        Spacer()
                            .frame(height: ViewHelper.biggerSpacing)
                        
                        Image("TeamKNOWN")
                            .resizable()
                            .scaledToFit()
                            .frame(width: ViewHelper.logoSize, height: ViewHelper.logoSize)
                            .padding(.bottom, ViewHelper.smallPadding)
                        
                        CIPageTitle("Enter Your Details")
                            .padding(.bottom, ViewHelper.biggerSpacing)
                        
                        VStack(spacing: ViewHelper.biggerSpacing) {
                            CIItem(name: "Email") {
                                CIEmailTextField(
                                    placeholder: "",
                                    text: $email,
                                    lines: 1
                                )
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                            }
                            
                            CIItem(name: "Password") {
                                CIPasswordTextField(
                                    placeholder: "",
                                    text: $password,
                                    lines: 1
                                )
                            }
                        }
                        .frame(width: ViewHelper.buttonWidth)
                        
                        if !message.isEmpty {
                            CIErrorMessage(errorMessage: message)
                        }
                        
                        Button {
                            Task {
                                do {
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
                                    message = "Email and Password required"
                                }
                            }
                        } label: {
                            Text("Sign In")
                                .font(.system(size: ViewHelper.buttonTextSize, weight: .bold))
                                .foregroundColor(ViewHelper.textImportant)
                                .frame(width: ViewHelper.buttonWidth, height: ViewHelper.buttonHeight)
                                .background(ViewHelper.accentBlue)
                                .cornerRadius(ViewHelper.componentRounding)
                        }
                        .padding(.top, ViewHelper.padding)
                        
                        NavigationLink("Need to reset password?") {
                            ForgotPasswordView(sessionManager: sessionManager)
                        }
                        .font(.system(size: ViewHelper.textSize))
                        .padding(.top, ViewHelper.smallPadding)
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
                        
                        Spacer()
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
