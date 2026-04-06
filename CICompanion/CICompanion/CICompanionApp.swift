//
//  CICompanionApp.swift
//  CICompanion
//
//  Root entry point — configures the main TabView and global appearance.
//

import SwiftUI
import Amplify
import AWSCognitoAuthPlugin

// MARK: - CICompanionApp

/// The root of the CICompanion application.
@main
struct CICompanionApp: App {

    /// Shared dependency-injection container for repositories & view models.
    let container = AppContainer()

    /// Controls whether the main UI is shown (false = splash screen).
    @State private var appReady = false

    init() {
        configureAmplify()
        configureTabBarAppearance()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if appReady {
                    TabView {
                        calendarTab

                        // Uncomment to enable the Map feature:
                        // mapTab

                        settingsTab
                    }
                    .tint(AppTheme.Colors.actionPrimary)
                } else {
                    LaunchLoadingView()
                }
            }
            .task {
                await container.sessionManager.loadCurrentUser()

                if container.sessionManager.isSignedIn {
                    do {
                        _ = try await container.studentRepository.loadStudent()
                    } catch {
                        print("Load student failed in main: ", error)
                    }
                }

                // Brief delay so the launch screen is visible.
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                appReady = true
            }
        }
    }
}

// MARK: - Tab Definitions

private extension CICompanionApp {

    /// Calendar tab — Day / Week / Month views, switchable via a filter menu.
    var calendarTab: some View {
        TodayView(
            viewModel: container.myAcademicCalendarViewModel,
            studentRepository: container.studentRepository,
            sessionManager: container.sessionManager
        )
        .tabItem {
            Image(systemName: "calendar")
            Text("Calendar")
        }
    }

    /// Campus map tab (currently hidden behind a feature flag).
    var mapTab: some View {
        MapView()
            .tabItem {
                Image(systemName: "map.fill")
                Text("Map")
            }
    }

    /// Settings / preferences tab.
    var settingsTab: some View {
        SettingsView(
            courseRepository: container.courseRepository,
            studentRepository: container.studentRepository,
            sessionManager: container.sessionManager
        )
        .tabItem {
            Image(systemName: "gearshape.fill")
            Text("Settings")
        }
    }
}

// MARK: - Configuration

private extension CICompanionApp {

    /// Initializes Amplify with the Cognito auth plugin.
    func configureAmplify() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.configure(with: .amplifyOutputs)
        } catch {
            print("Failed to configure Amplify: \(error)")
        }
    }

    /// Applies the dark-theme tab bar appearance using AppTheme tokens.
    func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppTheme.Colors.tabBarBackground)

        let normalColor  = UIColor(AppTheme.Colors.textSecondary)
        let selectedColor = UIColor(AppTheme.Colors.actionPrimary)

        let normalAttrs:   [NSAttributedString.Key: Any] = [.foregroundColor: normalColor]
        let selectedAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: selectedColor]

        appearance.stackedLayoutAppearance.normal.titleTextAttributes   = normalAttrs
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttrs
        appearance.stackedLayoutAppearance.normal.iconColor   = normalColor
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor

        UITabBar.appearance().standardAppearance   = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

