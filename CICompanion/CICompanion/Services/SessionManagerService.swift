//
//  SessionManager.swift
//  CICompanion
//
//  Created by Wummiez on 3/30/26.
//

import Foundation
import Amplify
import Combine

@MainActor
class SessionManager: ObservableObject {
    
    @Published var userId: String?
    @Published var isSignedIn = false
    @Published var name: String?
    @Published var email: String?
    
    func loadCurrentUser() async {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            isSignedIn = session.isSignedIn
            
            if session.isSignedIn {
                let user = try await Amplify.Auth.getCurrentUser()
                userId = user.userId
                
                // attributes contains id, name and email
                let attributes = try await Amplify.Auth.fetchUserAttributes()
                
                for attribute in attributes {
                    if attribute.key == .name {
                        name = attribute.value
                    }
                    
                    if attribute.key == .email {
                        email = attribute.value
                    }
                }
              
            // If session was fetched but no user associated with it
            } else {
                userId = nil
                name = nil
                email = nil
            }
            
        // Error occured during fetching session
        } catch {
            isSignedIn = false
            userId = nil
            name = nil
            email = nil
            print("Failed to load current user: \(error)")
        }
    }
    
    /*
    func setSignedInUser(id: String, name: String? = nil, email: String? = nil) {
        isSignedIn = true
        userId = id
        self.name = name
        self.email = email
    }
    */
    
    func signOut() async {
        do {
            _ = await Amplify.Auth.signOut()
            isSignedIn = false
            userId = nil
            name = nil
            email = nil
        }
    }
}
