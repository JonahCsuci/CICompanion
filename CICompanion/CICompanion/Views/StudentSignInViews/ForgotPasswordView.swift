//
//  ForgotPasswordView.swift
//  CICompanion
//
//  Created by Wummiez on 4/15/26.
//

import SwiftUI
import Amplify

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    
    let sessionManager: SessionManager
    
    @State private var email = ""
    @State private var code = ""
    @State private var newPassword = ""
    @State private var sendEmail = true
    @State private var message = ""
    @State private var successMessage = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        NavigationStack {
            CIView {
                HStack {
                    
                    Spacer()
                    
                    VStack {
                        
                        Image("TeamKNOWN")
                            .resizable()
                            .scaledToFit()
                            .frame(width: ViewHelper.logoSize, height: ViewHelper.logoSize)
                            .padding(.bottom, ViewHelper.smallPadding)
                        
                        CIPageTitle(sendEmail ? "Enter your email" : "Reset Password")
                            .padding(.bottom, ViewHelper.biggerSpacing)
                        
                        VStack(alignment: .leading) {
                            
                            if sendEmail {
                                
                                CIText("Email", color: ViewHelper.text)
                                    .foregroundColor(ViewHelper.textImportant)
                                
                                CIEmailTextField(
                                    placeholder: "",
                                    text: $email,
                                    lines: 1
                                )
                                .autocorrectionDisabled(true)
                                
                            } else {
                                
                                CIText("Code", color: ViewHelper.text)
                                
                                CITextField(
                                    placeholder: "",
                                    text: $code,
                                    lines: 1
                                )
                                
                                CIText("New Password", color: ViewHelper.text)
                                    .padding(ViewHelper.smallPadding)
                                
                                CIPasswordTextField(
                                    placeholder: "",
                                    text: $newPassword,
                                    lines: 1
                                )
                                
                                CIText("Confirm New Password", color: ViewHelper.text)
                                    .padding(ViewHelper.smallPadding)
                                
                                CIPasswordTextField(
                                    placeholder: "",
                                    text: $confirmPassword,
                                    lines: 1)
                            }
                        }
                        
                        if !email.isEmpty && !sendEmail {
                            CIText("Code sent to \(email)", color: ViewHelper.textImportant)
                        }
                        
                        if !message.isEmpty {
                            CIErrorMessage(errorMessage: message)
                        }
                        
                        if !successMessage.isEmpty {
                            CIText(successMessage, color: ViewHelper.accentGreen)
                        }
                        
                        Button {
                            Task {
                                do {
                                    
                                    if sendEmail {
                                        
                                        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            message = "Enter your email"
                                            return
                                        }
                                        
                                        _ = try await Amplify.Auth.resetPassword(for: email)
                                        
                                        sendEmail = false
                                        message = ""
                                        
                                    } else {
                                        
                                        if code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                            newPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                            confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            message = "Fill out all fields"
                                            return
                                        }
                                        
                                        if newPassword != confirmPassword {
                                            message = "Passwords do not match"
                                            return
                                        }
                                        
                                        try await Amplify.Auth.confirmResetPassword(
                                            for: email,
                                            with: newPassword,
                                            confirmationCode: code
                                        )
                                        
                                        
                                        message = ""
                                        successMessage = "Password reset confirmed"
                                        
                                        try await Task.sleep(for: .seconds(2))
                                        
                                        dismiss()
                                    }
                                    
                                } catch {
                                    successMessage = ""
                                    message = AuthErrorMessage.text(for: error)
                                }
                            }
                        } label: {
                            Text(sendEmail ? "Send Code" : "Reset Password")
                                .font(.system(size: ViewHelper.buttonTextSize, weight: .bold))
                                .foregroundColor(ViewHelper.textImportant)
                                .frame(width: ViewHelper.buttonWidth, height: ViewHelper.buttonHeight)
                                .background(ViewHelper.accentBlue)
                                .cornerRadius(ViewHelper.componentRounding)
                        }
                        .padding(.top, ViewHelper.padding)
                    }
                    
                    Spacer()
                }
                
                Spacer()
                
                HStack {
                    
                    VStack(spacing: ViewHelper.smallPadding) {
                        
                        CIText("Remember Password?", color: ViewHelper.textImportant)
                        
                        CITextButton(text: "Back to Sign In") {
                            dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .navigationBarBackButtonHidden(true)
                .toolbar(.hidden, for: .navigationBar)
                
                }
                
        }
    }
}

#Preview {
    ForgotPasswordView(sessionManager: SessionManager())
}
