//
//  ScheduleBottomBannerView.swift
//  CICompanion
//
//  Created by Codex on 3/24/26.
//

import SwiftUI

struct ScheduleBottomBannerView: View {
    
    let isShowingCalendar: Bool
    let onScheduleTapped: () -> Void
    let onCalendarTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            bottomButton(
                title: "My Schedule",
                systemImage: "list.bullet.rectangle",
                isSelected: !isShowingCalendar,
                action: onScheduleTapped
            )
            
            bottomButton(
                title: "Calendar",
                systemImage: "calendar",
                isSelected: isShowingCalendar,
                action: onCalendarTapped
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }
    
    private func bottomButton(
        title: String,
        systemImage: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(isSelected ? Color.accentColor : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(isSelected)
    }
}
