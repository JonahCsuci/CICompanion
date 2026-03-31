//
//  SessionManager.swift
//  CICompanion
//
//  Created by Wummiez on 3/30/26.
//

import Foundation
import Amplify
import Combine

/*
@MainActor
class SessionManager: ObservableObject {
    @Published var userId: String?
    @Published var isSignedIn = false
    
    func loadCurrentUser() async {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            isSignedIn = session.isSignedIn
            
            if session.isSignedIn {
                let user = try await Amplify.Auth.getCurrentUser()
                userId = user.userId
            } else {
                userId = nil
            }
        } catch {
            isSignedIn = false
            userId = nil
            print("Failed to load current user: \(error)")
        }
    }
    
    func setSignedInUser(id: String) {
        isSignedIn = true
        userId = id
    }
    
    func clear() {
        isSignedIn = false
        userId = nil
    }
}

*/
