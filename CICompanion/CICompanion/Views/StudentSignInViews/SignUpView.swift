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
                    Image("dolphin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .padding(.top, 20)
                        .padding(.bottom, 12)
                    
                    Text("Create Your Account")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 30)
                    
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 320, alignment: .leading)
                            
                            TextField("", text: $name)
                                .padding(.horizontal, 12)
                                .frame(width: 320, height: 48)
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 0)
                                        .stroke(Color.blue.opacity(0.8), lineWidth: 2)
                                )
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 320, alignment: .leading)
                            
                            TextField("", text: $email)
                                .padding(.horizontal, 12)
                                .frame(width: 320, height: 48)
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 0)
                                        .stroke(Color.blue.opacity(0.8), lineWidth: 2)
                                )
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
                                .padding(.horizontal, 12)
                                .frame(width: 320, height: 48)
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 0)
                                        .stroke(Color.blue.opacity(0.8), lineWidth: 2)
                                )
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
                            } catch let error as AuthError {
                                let description = error.errorDescription.lowercased()
                                
                                if description.contains("exists") || description.contains("already") {
                                    message = "Account already exists. Please verify your email."
                                    showConfirm = true
                                } else {
                                    message = error.errorDescription
                                }
                            } catch {
                                message = error.localizedDescription
                            }
                        }
                    } label: {
                        Text("Create Account")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 320, height: 50)
                            .background(Color(red: 0.36, green: 0.55, blue: 0.90))
                            .cornerRadius(8)
                    }
                    .padding(.top, 24)
                    
                    Spacer()
                    
                    Text("Already have an account?")
                        .foregroundColor(.gray)
                        .font(.system(size: 18))
                    
                    Button("Back to Sign In") {
                        dismiss()
                    }
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.90))
                    
                    Spacer()
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showConfirm) {
            CIView {ConfirmSignUpView(
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
