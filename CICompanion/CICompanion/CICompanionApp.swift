//
//  CICompanionApp.swift
//  CICompanion
//
//  Root entry point — configures the main TabView and global appearance.
//

import SwiftUI

// MARK: - CICompanionApp

/// The root of the CICompanion application.
@main
struct CICompanionApp: App {

    /// Shared dependency-injection container for repositories & view models.
    let container = AppContainer()

    init() {
        configureTabBarAppearance()
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                calendarTab

                // Uncomment to enable the Map feature:
                // mapTab

                settingsTab
            }
            .tint(AppTheme.Colors.actionPrimary)
        }
    }
}

private extension CICompanionApp {

    /// Calendar tab — Day / Week / Month views, switchable via a filter menu.
    var calendarTab: some View {
        TodayView(viewModel: container.myAcademicCalendarViewModel)
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
            studentRepository: container.studentRepository
        )
        .tabItem {
            Image(systemName: "gearshape.fill")
            Text("Settings")
        }
    }
}

private extension CICompanionApp {

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
