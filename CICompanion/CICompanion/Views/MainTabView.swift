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
    
    var body: some View {
        TabView {
            StudentCoursesView(viewModel: container.studentCoursesViewModel, addClassViewModel: container.addClassViewModel)
                .tabItem {
                    Label("My Courses", systemImage: "book")
                }
            
        }
    }
}

#Preview {
    MainTabView(container: AppContainer())
}
