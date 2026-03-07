//
//  CICompanionApp.swift
//  CICompanion
//
//  Created by Wummiez on 3/6/26.
//

import SwiftUI

// App entry point.
// This is where the AppContainer is created,
// and the first view is given its ViewModel.
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
            
            // Pass the studentCoursesViewModel object from AppContainer into StudentCoursesView
            // studentCoursesViewModel is an instance of StudentCoursesViewModel,
            // and it already contains the ClassRepository object used to load the student’s courses.
            // sorry if i didnt explain that well :(
            StudentCoursesView(viewModel: container.studentCoursesViewModel)
        }
    }
}
