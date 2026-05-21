//
//  AuthErrorMessage.swift
//  CICompanion
//

import Amplify
import AWSCognitoAuthPlugin

/// Translates an Amplify authentication error into a short, user-facing message.
///
/// The sign-in, password-reset, and verification screens previously collapsed
/// every failure into a single hard-coded string, which hid the real cause —
/// wrong password, unverified account, expired code, a new password that fails
/// the user pool's policy, an already-active session, and so on.
enum AuthErrorMessage {

    static func text(for error: Error) -> String {
        guard let authError = error as? AuthError else {
            return genericFailure
        }

        if let cognitoMessage = cognitoMessage(for: authError.underlyingError) {
            return cognitoMessage
        }

        switch authError {
        case .notAuthorized:
            return "Incorrect email or password."
        case .invalidState:
            return "Someone is already signed in. Please try again."
        case .validation:
            return "Please fill in all required fields."
        case .signedOut, .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .service, .configuration, .unknown:
            return genericFailure
        }
    }

    /// True when the failure means the email is already registered. Callers
    /// should route the user to email verification instead of showing an error.
    static func isAccountAlreadyExists(_ error: Error) -> Bool {
        guard let cognitoError = (error as? AuthError)?.underlyingError as? AWSCognitoAuthError else {
            return false
        }

        switch cognitoError {
        case .usernameExists, .aliasExists:
            return true
        default:
            return false
        }
    }

    private static func cognitoMessage(for underlyingError: Error?) -> String? {
        guard let cognitoError = underlyingError as? AWSCognitoAuthError else {
            return nil
        }

        switch cognitoError {
        case .userNotConfirmed:
            return "Your account isn't verified yet. Check your email for a verification code."
        case .userNotFound:
            return "Incorrect email or password."
        case .invalidPassword:
            return "Password must be at least 8 characters and include an uppercase letter, a lowercase letter, a number, and a symbol."
        case .codeMismatch:
            return "Incorrect verification code."
        case .codeExpired:
            return "That code has expired. Request a new one."
        case .usernameExists, .aliasExists:
            return "An account with that email already exists."
        case .limitExceeded, .failedAttemptsLimitExceeded, .requestLimitExceeded, .limitExceededException:
            return "Too many attempts. Please wait a moment and try again."
        case .network:
            return "No internet connection. Check your network and try again."
        default:
            return nil
        }
    }

    private static let genericFailure = "Something went wrong. Please try again."
}
