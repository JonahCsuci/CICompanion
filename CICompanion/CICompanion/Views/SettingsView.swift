//
//  SettingsView.swift
//  CICompanion
//
//  The Settings tab — provides app preferences and account actions.
//

import SwiftUI

struct SettingsView: View {
    
    // MARK: - Dependencies
    
    let courseRepository: CourseRepositoryProtocol
    let studentRepository: StudentRepositoryProtocol
    
    let tutorViewModel: TutorViewModel
    
    @ObservedObject var sessionManager: SessionManager
    
    // MARK: - Local State
    
    @State private var showSignOutToast = false
    private let bgColor = Color(red: 0.08, green: 0.10, blue: 0.15)
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()
                
                List {
                    Section {
                        NavigationLink {
                            NotificationSettingsView(courses: [])
                        } label: {
                            Label("Notifications", systemImage: "bell.fill")
                        }
                    } header: {
                        Text("Preferences")
                    }
                    
                    Section {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("5.0.0")
                                .foregroundColor(.gray)
                        }
                    } header: {
                        Text("About")
                    }
                    
                    if sessionManager.isSignedIn {
                        Section {
                            Button {
                                Task {
                                    await sessionManager.signOut()
                                    withAnimation {
                                        showSignOutToast = true
                                    }
                                    try? await Task.sleep(for: .seconds(2))
                                    withAnimation {
                                        showSignOutToast = false
                                    }
                                }
                            } label: {
                                Label("Sign Out", systemImage: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .overlay(alignment: .bottom) {
                if showSignOutToast {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                        Text("Signed out successfully")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.12, green: 0.14, blue: 0.20))
                    .cornerRadius(25)
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Settings")
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SettingsView(
        courseRepository: CourseRepository(studentRepository: StudentRepository()),
        studentRepository: StudentRepository(),
        tutorViewModel: TutorViewModel(tutorRepository: TutorRepository()),
        sessionManager: SessionManager()
    )
}
