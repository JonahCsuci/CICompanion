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
        ZStack {
            Image("appbackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            Color.black.opacity(0.25)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 150)
                
                HStack(spacing: 16) {
                    
                    Image("dolphin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 58, height: 58)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.65))
                        .frame(width: 1, height: 58)
                    
                    Text("Channel  Islands")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(
                            LinearGradient (
                                colors: [
                                    Color(red: 0.6, green: 0.8, blue: 1.0),
                                    Color.blue
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
            }
        }
    }
}
