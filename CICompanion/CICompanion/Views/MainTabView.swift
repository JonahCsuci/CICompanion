//
//  MainTabView.swift
//  CICompanion
//
//  Created by Wummiez on 3/24/26.
//

import SwiftUI

struct MainTabView: View {
    
    let container: AppContainer
    
    init(container: AppContainer) {
        self.container = container
    }
    
    // Displays selected View (Defaults to Student Courses View)
    var body: some View {
        TabView {
            StudentCoursesView(viewModel: container.studentCoursesViewModel, coursesListViewModel: container.coursesListViewModel)
                .tabItem {
                    Label("My Courses", systemImage: "book")
                }
            APITestView(viewModel: container.apiTestViewModel)
                .tabItem {
                    Label("Dummy tab", systemImage: "list.bullet")
                }
            
        }
    }
}

#Preview {
    MainTabView(container: AppContainer())
}
