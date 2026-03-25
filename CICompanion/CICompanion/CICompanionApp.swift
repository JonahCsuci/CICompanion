//
//  CICompanionApp.swift
//  CICompanion
//
//  Created by Wummiez on 3/6/26.
//

import SwiftUI

@main
struct CICompanionApp: App {
    
    let container = AppContainer()
    
    var body: some Scene {
        WindowGroup {
            StudentCoursesView(
                viewModel: container.studentCoursesViewModel,
                coursesListViewModel: container.coursesListViewModel,
                myAcademicCalendarViewModel: container.myAcademicCalendarViewModel
            )
        }
    }
}
