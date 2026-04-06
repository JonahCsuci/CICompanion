//
//  MapView.swift
//  CICompanion
//
//  Placeholder view for the future Campus Map feature.
//  Shows a "coming soon" card and a list of key campus locations.
//

import SwiftUI

// MARK: - MapView

/// Placeholder campus-map screen shown in the Map tab.
///
/// Currently displays static content (a "coming soon" hero, an
/// about section, and a list of key campus locations).
/// Replace with a real `Map` view in a future iteration.
struct MapView: View {

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    screenTitle
                    comingSoonHero
                    aboutSection
                }
                .padding(AppTheme.Spacing.screen)
            }
        }
    }
}

private extension MapView {

    /// "Campus Map" title at the top of the screen.
    var screenTitle: some View {
        Text("Campus Map")
            .font(AppTheme.Fonts.screenTitle)
            .foregroundColor(AppTheme.Colors.textPrimary)
    }

    /// Large placeholder card with a map icon and "Coming Soon" label.
    var comingSoonHero: some View {
        RoundedRectangle(cornerRadius: AppTheme.Spacing.screen)
            .fill(AppTheme.Colors.cardBackground)
            .frame(height: 260)
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: "map.fill")
                        .font(AppTheme.Fonts.iconHero)
                        .foregroundColor(AppTheme.Colors.actionPrimary)

                    Text("Campus Map Coming Soon")
                        .font(AppTheme.Fonts.toolbarActionBold)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
            )
    }

    /// About text + key location list.
    var aboutSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.screen) {
            Text("About the Campus")
                .font(AppTheme.Fonts.sectionHeader)
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.")
                .font(AppTheme.Fonts.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .lineSpacing(4)

            Text("Key Locations")
                .font(AppTheme.Fonts.subsectionHeader)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .padding(.top, 8)

            ForEach(placeholderLocations, id: \.name) { location in
                locationRow(location)
            }

            Text("Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
                .font(AppTheme.Fonts.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .lineSpacing(4)
                .padding(.top, 8)
        }
    }

    /// A single key-location row with an icon badge, name, and detail text.
    func locationRow(_ location: (name: String, detail: String, icon: String)) -> some View {
        HStack(spacing: 12) {
            Image(systemName: location.icon)
                .font(AppTheme.Fonts.body)
                .foregroundColor(AppTheme.Colors.actionPrimary)
                .frame(width: 32, height: 32)
                .background(AppTheme.Colors.surfaceElevated)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(location.name)
                    .font(AppTheme.Fonts.subheadline)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text(location.detail)
                    .font(AppTheme.Fonts.smallCaption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(12)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.Spacing.fieldCornerRadius)
    }
}

private extension MapView {

    /// Placeholder locations shown until the real map is implemented.
    var placeholderLocations: [(name: String, detail: String, icon: String)] {
        [
            ("Main Library",      "Building A, 1st Floor",       "book.fill"),
            ("Science Hall",      "Building C, Rooms 200-210",   "flask.fill"),
            ("Student Center",    "Central Campus",              "person.3.fill"),
            ("Lecture Hall 101",  "Building B, Ground Floor",    "graduationcap.fill"),
            ("Athletic Complex",  "East Campus",                 "figure.run")
        ]
    }
}

// MARK: - Preview

#Preview {
    MapView()
}
