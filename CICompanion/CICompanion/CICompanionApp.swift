//
//  CICompanionApp.swift
//  CICompanion
//
//  Created by Wummiez on 3/6/26.
//

import SwiftUI
import Amplify
import AWSCognitoAuthPlugin

/// The root of the CICompanion application.
@main
struct CICompanionApp: App {
    
    /// The dependency injection container for repositories & view models.
    let container = AppContainer()
    
    @State private var appReady = false
    
    init() {
        configureAmplify()
        setupTabBarAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if appReady {
                    TabView {
                        // Today tab
                        TodayView(
                            viewModel: container.myAcademicCalendarViewModel,
                            studentRepository: container.studentRepository,
                            sessionManager: container.sessionManager
                        )
                            .tabItem {
                                Image(systemName: "calendar")
                                Text("Today")
                            }
                        
                        // Schedule tab
                        ScheduleGridView(viewModel: AcademicCalendarViewModel(
                            courseRepository: container.courseRepository,
                            studentRepository: container.studentRepository
                        ),
                            sessionManager: container.sessionManager)
                            .tabItem {
                                Image(systemName: "square.grid.3x3.fill")
                                Text("Schedule")
                            }
                        
                        // Messages tab
                        MessagesView(
                            viewModel: container.conversationsViewModel,
                            studentRepository: container.studentRepository,
                            messagingRepository: container.messagingRepository,
                            courseRepository: container.courseRepository,
                            sessionManager: container.sessionManager
                        )
                            .tabItem {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                Text("Messages")
                            }

                        // Remove the comments below to turn on the Map feature
//                        MapView()
//                            .tabItem {
//                                Image(systemName: "map.fill")
//                                Text("Map")
//                            }
                        
                        // Settings tab
                        SettingsView(
                            courseRepository: container.courseRepository,
                            studentRepository: container.studentRepository,
                            sessionManager: container.sessionManager
                        )
                            .tabItem {
                                Image(systemName: "gearshape.fill")
                                Text("Settings")
                            }

                        /**#if DEBUG
                        APITestView(viewModel: container.apiTestViewModel)
                            .tabItem {
                                Image(systemName: "wrench.and.screwdriver.fill")
                                Text("API Test")
                            }
                        #endif**/
                    }
                    .tint(Color(red: 0.6, green: 0.8, blue: 1.0))
                    
                } else {
                    LaunchLoadingView()
                }
            }.preferredColorScheme(.dark)
                .background(ViewHelper.bgColor)
            // On app launch, tries to load previous session from the user
            .task {
                await container.sessionManager.loadCurrentUser()
                
                // If successfully loaded, checks to see if exist in DB
                if container.sessionManager.isSignedIn {
                    do {
                        _ = try await container.studentRepository.loadStudent()
                    } catch {
                        print("Load student failed in main: ", error)
                    }
                }
                
                // Slows down app launch by 1.5sec so we can see loading screen, teehee ;)
                // Otherwise goes by too fast, can take out if want, dont care tbh
                try? await Task.sleep(for: .seconds(1.5))
                
                appReady = true
            }
        }
    }
    
    // Sets up user authentication
    private func configureAmplify() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.configure(with: .amplifyOutputs)
        } catch {
            print("Failed to configure Amplify: \(error)")
        }
    }
    
    /// Customizes the tab bar appearance for our dark theme.
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.10, green: 0.12, blue: 0.18, alpha: 1.0)
        
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(white: 0.45, alpha: 1.0)
        ]
        let selectedAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0)
        ]
        
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttrs
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttrs
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(white: 0.45, alpha: 1.0)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
