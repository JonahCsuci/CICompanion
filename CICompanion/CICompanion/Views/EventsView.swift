//
//  EventsView.swift
//  CICompanion
//
//  Placeholder view for the campus Events feature.
//  Replace with a real events list once the API is integrated.
//

import SwiftUI

// MARK: - EventsView

/// Placeholder screen for the future campus Events list.
struct EventsView: View {

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            Text("Events coming soon")
                .font(AppTheme.Fonts.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    EventsView()
}
