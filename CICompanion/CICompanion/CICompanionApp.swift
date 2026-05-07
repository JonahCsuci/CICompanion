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

    // Tab tags. The Map tab is special: selecting it presents a fullscreen
    // map and immediately reverts the selection back to the previous tab so
    // the back button returns the user where they came from.
    private enum Tab: Int { case today = 0, discover = 1, messages = 2, map = 3 }

    @State private var selectedTab: Int = Tab.today.rawValue
    @State private var previousTab: Int = Tab.today.rawValue
    @State private var showMap: Bool = false

    init(container: AppContainer) {
        self.container = container
        self.conversationsViewModel = container.conversationsViewModel
        self.sessionManager = container.sessionManager
    }

    var body: some View {
        TabView(selection: tabSelection) {
            // Today tab (Day / Week / Month modes live inside)
            TodayView(
                viewModel: container.myAcademicCalendarViewModel,
                studentRepository: container.studentRepository,
                courseRepository: container.courseRepository,
                sessionManager: container.sessionManager,
                tutorViewModel: container.tutorViewModel
                
            )
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Today")
                }
                .tag(Tab.today.rawValue)

            DiscoveryView(
                tutorViewModel: container.tutorViewModel
            )
            .tabItem {
                Image(systemName: "newspaper.fill")
                Text("Discover")
            }
            .tag(Tab.discover.rawValue)
            
            // Messages tab
            MessagesView(
                viewModel: conversationsViewModel,
                studentRepository: container.studentRepository,
                messagingRepository: container.messagingRepository,
                courseRepository: container.courseRepository,
                sessionManager: container.sessionManager,
                tutorViewModel: container.tutorViewModel
            )
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Messages")
                }
                .badge(conversationsViewModel.totalUnreadCount)
                .tag(Tab.messages.rawValue)

            // Map tab — selecting this tab triggers a fullscreen cover via
            // the `tabSelection` binding below. The view body itself is never
            // actually displayed because we revert the selection immediately.
            Color.clear
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Map")
                }
                .tag(Tab.map.rawValue)

            // Settings moved into a top-left gear button on each main view;
            // no longer a standalone tab.

            /**#if DEBUG
            APITestView(viewModel: container.apiTestViewModel)
                .tabItem {
                    Image(systemName: "wrench.and.screwdriver.fill")
                    Text("API Test")
                }
            #endif**/
        }
        .fullScreenCover(isPresented: $showMap) {
            MapView(onDismiss: { showMap = false })
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

    /// Binding that intercepts taps on the Map tab: it presents the fullscreen
    /// map and reverts the tab selection so dismissing returns to the prior tab.
    private var tabSelection: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                if newValue == Tab.map.rawValue {
                    showMap = true
                    // Keep the tab bar pointing at the previous tab so the
                    // Back button visually "returns" to where the user was.
                    selectedTab = previousTab
                } else {
                    previousTab = newValue
                    selectedTab = newValue
                }
            }
        )
    }
}
