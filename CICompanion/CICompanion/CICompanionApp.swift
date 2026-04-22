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
                    RootTabView(container: container)
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
            .foregroundColor: UIColor(ViewHelper.text)
        ]
        let selectedAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(ViewHelper.accentBlue)
        ]

        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttrs
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttrs
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(ViewHelper.text)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(ViewHelper.accentBlue)

        // Make unread-count badges match the app accent instead of the iOS-default red.
        appearance.stackedLayoutAppearance.normal.badgeBackgroundColor = UIColor(ViewHelper.accentBlue)
        appearance.stackedLayoutAppearance.selected.badgeBackgroundColor = UIColor(ViewHelper.accentBlue)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

/// Hosts the main tab bar. Pulled into its own view so we can observe the shared
/// `ConversationsViewModel` and drive the unread badge on the Messages tab.
private struct RootTabView: View {
    let container: AppContainer
    @ObservedObject var conversationsViewModel: ConversationsViewModel
    @ObservedObject var sessionManager: SessionManager

    // Matches the in-Messages-tab poll cadence so the badge feels equally responsive from any tab.
    private let badgePollIntervalSeconds: Int = 3

    init(container: AppContainer) {
        self.container = container
        self.conversationsViewModel = container.conversationsViewModel
        self.sessionManager = container.sessionManager
    }

    var body: some View {
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
                viewModel: conversationsViewModel,
                studentRepository: container.studentRepository,
                messagingRepository: container.messagingRepository,
                courseRepository: container.courseRepository,
                sessionManager: container.sessionManager
            )
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Messages")
                }
                .badge(conversationsViewModel.totalUnreadCount)

            // Remove the comments below to turn on the Map feature
//            MapView()
//                .tabItem {
//                    Image(systemName: "map.fill")
//                    Text("Map")
//                }

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
        .tint(ViewHelper.accentBlue)
        // Keep the unread badge live from any tab — MessagesView's own poll only runs while it's visible.
        .task(id: sessionManager.isSignedIn) {
            guard sessionManager.isSignedIn else { return }
            conversationsViewModel.loadConversations()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(badgePollIntervalSeconds))
                guard !Task.isCancelled, sessionManager.isSignedIn else { break }
                await conversationsViewModel.refreshConversationsSilently()
            }
        }
    }
}
