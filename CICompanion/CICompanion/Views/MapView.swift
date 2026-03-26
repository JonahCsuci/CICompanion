//
//  MapView.swift
//  CICompanion
//
//  Placeholder view for the future Campus Map feature.
//

import SwiftUI

struct MapView: View {
    
    private let bgColor = Color(red: 0.08, green: 0.10, blue: 0.15)
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Campus Map")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.12, green: 0.14, blue: 0.20))
                        .frame(height: 260)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "map.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color(red: 0.35, green: 0.55, blue: 0.95))
                                
                                Text("Campus Map Coming Soon")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        )
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About the Campus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineSpacing(4)
                        
                        Text("Key Locations")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.top, 8)
                        
                        ForEach(placeholderLocations, id: \.name) { location in
                            HStack(spacing: 12) {
                                Image(systemName: location.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(red: 0.35, green: 0.55, blue: 0.95))
                                    .frame(width: 32, height: 32)
                                    .background(Color(red: 0.15, green: 0.17, blue: 0.24))
                                    .cornerRadius(8)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(location.name)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text(location.detail)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                            }
                            .padding(12)
                            .background(Color(red: 0.12, green: 0.14, blue: 0.20))
                            .cornerRadius(10)
                        }
                        
                        Text("Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineSpacing(4)
                            .padding(.top, 8)
                    }
                }
                .padding(16)
            }
        }
    }
    
    private var placeholderLocations: [(name: String, detail: String, icon: String)] {
        [
            ("Main Library", "Building A, 1st Floor", "book.fill"),
            ("Science Hall", "Building C, Rooms 200-210", "flask.fill"),
            ("Student Center", "Central Campus", "person.3.fill"),
            ("Lecture Hall 101", "Building B, Ground Floor", "graduationcap.fill"),
            ("Athletic Complex", "East Campus", "figure.run")
        ]
    }
}

// MARK: - Preview

#Preview {
    MapView()
}
