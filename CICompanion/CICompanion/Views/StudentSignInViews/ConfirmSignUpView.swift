import SwiftUI
import Amplify

struct ConfirmSignUpView: View {
    @Environment(\.dismiss) private var dismiss
    
    let email: String
    let name: String
    let sessionManager: SessionManager
    
    @State private var code = ""
    @State private var message = ""
    
    var body: some View {
        CIView {
            VStack(alignment: .leading, spacing: ViewHelper.biggerSpacing) {
                CIPageTitle("Verify Email")
                
                VStack(alignment: .leading) {
                    CIText("Enter the code sent to " + email, color: ViewHelper.textImportant)
                }
                
                CITextField(placeholder: "Verification Code", text: $code, lines: 1)
                    .keyboardType(.numberPad)
                
                if !message.isEmpty {
                    Text(message)
                        .foregroundColor(.blue)
                }
                
                Button("Verify", role: .confirm, action: {
                    Task {
                        do {
                            let result = try await Amplify.Auth.confirmSignUp(
                                for: email,
                                confirmationCode: code
                            )
                            
                            if result.isSignUpComplete {
                                message = "Account verified!"
                                // Ensure student exists in SQL backend
                                do {
                                    let repo = APIStudentRepository(sessionManager: sessionManager)
                                    _ = try await repo.ensureStudentExists()
                                } catch {
                                    print("ensureStudentExists failed:", error)
                                }
                                dismiss()
                            }
                        } catch {
                            message = error.localizedDescription
                            print("Confirm error: ", error)
                        }
                    }
                })
                .frame(width: .infinity)
                
                Button("Resend Code", role: .cancel, action: {
                    Task {
                        do {
                            let result = try await Amplify.Auth.resendSignUpCode(for: email)
                            message = "Code resent to \(result.destination)"
                        } catch {
                            message = "Failed to resend code"
                            print("Resend error:", error)
                        }
                    }
                })
                .frame(width: .infinity)
                
                Button("Close", role: .destructive, action: {
                    dismiss()
                })
                .frame(width: .infinity)
                
                Spacer()
            }
        }
        .padding()
    }
}
