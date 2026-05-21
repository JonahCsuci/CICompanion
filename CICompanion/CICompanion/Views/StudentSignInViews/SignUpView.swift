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
    
    var body: some View {
        CIView {
            HStack {
                Spacer()
                
                VStack {
                    Image("TeamKNOWN")
                        .resizable()
                        .scaledToFit()
                        .frame(width: ViewHelper.logoSize, height: ViewHelper.logoSize)
                        .padding(.top, ViewHelper.padding + ViewHelper.smallPadding)
                        .padding(.bottom, ViewHelper.smallPadding)
                    
                    CIPageTitle("Create Your Account")
                        .padding(.bottom, ViewHelper.biggerSpacing)
                    
                    VStack(spacing: ViewHelper.biggerSpacing) {
                        CIItem(name: "Name") {
                            CITextField(
                                placeholder: "",
                                text: $name,
                                lines: 1
                            )
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        }
                        
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
                    } label: {
                        Text("Create Account")
                            .font(.system(size: ViewHelper.buttonTextSize, weight: .bold))
                            .foregroundColor(ViewHelper.textImportant)
                            .frame(width: ViewHelper.buttonWidth, height: ViewHelper.buttonHeight)
                            .background(ViewHelper.accentBlue)
                            .cornerRadius(ViewHelper.componentRounding)
                    }
                    .padding(.top, ViewHelper.padding)
                    
                    Spacer()
                    
                    VStack(spacing: ViewHelper.smallPadding) {
                        CIText("Already have an account?", color: ViewHelper.text)
                        
                        CITextButton(text: "Back to Sign In") {
                            dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showConfirm) {
            CIView {
                ConfirmSignUpView(
                    email: email,
                    name: name,
                    sessionManager: sessionManager
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}
