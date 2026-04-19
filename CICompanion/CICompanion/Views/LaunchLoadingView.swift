//
//  LaunchLoadingView.swift
//  CICompanion
//
//  Created by Wummiez on 3/31/26.
//

import SwiftUI

import SwiftUI

struct LaunchLoadingView: View {
    
    private let cardBgColor = Color(red: 0.12, green: 0.14, blue: 0.20)
    
    
    var body: some View {
        CIView {
            HStack {
                Spacer()
                VStack(spacing: 0) {
                    HStack(spacing: 16) {
                        Image("dolphin")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 58, height: 58)
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.65))
                            .frame(width: 1, height: 58)
                        
                        CIPageTitle("CI Companion App")
                    }
                    
                    VStack {
                        Spacer()
                        VStack {
                            CILoadingPage()
                            CIText("Loading...", color: ViewHelper.text)
                        }
                        Spacer()
                    }
                    
                }
                Spacer()
            }
        }
    }
}

#Preview {
    LaunchLoadingView()
}
