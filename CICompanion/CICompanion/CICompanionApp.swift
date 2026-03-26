//
//  CICompanionApp.swift
//  CICompanion
//
//  Created by Wummiez on 3/6/26.
//

import SwiftUI

/// The root of the CICompanion application.
@main
struct CICompanionApp: App {
    
    /// The dependency injection container for repositories & view models.
    let container = AppContainer()
    
    init() {
        setupTabBarAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            TabView {
                // Today tab
                TodayView(viewModel: container.myAcademicCalendarViewModel)
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Today")
                    }
                
                // Schedule tab
                ScheduleGridView(viewModel: AcademicCalendarViewModel(
                    courseRepository: container.courseRepository,
                    studentRepository: container.studentRepository
                ))
                    .tabItem {
                        Image(systemName: "square.grid.3x3.fill")
                        Text("Schedule")
                    }
                
                // Remove the comments below to turn on the Map feature
//                MapView()
//                    .tabItem {
//                        Image(systemName: "map.fill")
//                        Text("Map")
//                    }
                
                // Settings tab
                SettingsView(
                    courseRepository: container.courseRepository,
                    studentRepository: container.studentRepository
                )
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
            }
            .tint(Color(red: 0.6, green: 0.8, blue: 1.0))
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
