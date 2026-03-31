import SwiftUI
import Amplify

/*
struct ConfirmSignUpView: View {
    @Environment(\.dismiss) private var dismiss

    let email: String

    @State private var code = ""
    @State private var message = ""

    var body: some View {
        VStack(spacing: 16) {
            
            Text("Verify Email")
                .font(.title)
                .bold()

            Text("Enter the code sent to:")
            Text(email)
                .fontWeight(.semibold)

            TextField("Verification Code", text: $code)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)

            if !message.isEmpty {
                Text(message)
                    .foregroundColor(.blue)
            }
            
            Button("Verify") {
                Task {
                    do {
                        let result = try await Amplify.Auth.confirmSignUp(
                            for: email,
                            confirmationCode: code
                        )

                        if result.isSignUpComplete {
                            message = "Account verified!"
                            dismiss()
                        }
                    } catch {
                        message = error.localizedDescription
                        print("Confirm error:", error)
                    }
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Resend Code") {
                Task {
                    do {
                        let result = try await Amplify.Auth.resendSignUpCode(for: email)
                        message = "Code resent to \(result.destination)"
                    } catch {
                        message = "Failed to resend code"
                        print("Resend error:", error)
                    }
                }
            }
            .buttonStyle(.bordered)

            Button("Close") {
                dismiss()
            }

            Spacer()
        }
        .padding()
    }
}
*/
