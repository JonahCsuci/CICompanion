//
//  CICompanionApp.swift
//  CICompanion
//
//  Created by Wummiez on 3/6/26.
//

import SwiftUI

@main
struct CICompanionApp: App {
    
    // AppContainer creates and stores shared objects that other parts of the app need.
    // Instead of each ViewModel creating its own objects (like repositories or services),
    // they receive them from here. This keeps object creation in one place and makes the
    // code easier to organize, reuse, and update later.
    let container = AppContainer()
    
    // Calls on the StudentCoursesView from entry point because
    // that will be the first view the user will see when opening the app
    var body: some Scene {
        WindowGroup {
            StudentCoursesView(
                viewModel: container.studentCoursesViewModel,
                addClassViewModel: container.addClassViewModel
            )
        }
    }
}
