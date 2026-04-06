//
//  AppTheme.swift
//  CICompanion
//
//  Centralizes every design token (colors, fonts, spacing, corner radii)
//  so every view draws from a single source of truth.
//  Values are mapped directly from the Figma design-system page.
//
//  Changing a value here updates the entire app — no magic numbers elsewhere.
//

import SwiftUI

/// A namespace that holds every visual constant used across the app.
///
/// Tokens are organized into nested enums (`Colors`, `Fonts`, `Spacing`)
/// and re-exported at the top level for convenience.
/// Each color token includes the Figma hex in a trailing comment.
enum AppTheme {

    // ╔══════════════════════════════════════════════════════════════════╗
    // ║  Colors                                                          ║
    // ╚══════════════════════════════════════════════════════════════════╝

    enum Colors {

        // Text  (Figma: theme.colors.text)
        static let textPrimary   = Color.white                                    // #FFFFFF
        static let textSecondary = Color(hex: 0xE8E8F5).opacity(0.60)             // #E8E8F5 @ 60%
        static let textOnLight   = Color(hex: 0x010618)                           // #010618

        // Backgrounds  (Figma: theme.colors.background)
        static let background      = Color(hex: 0x010618)                         // #010618
        static let cardBackground  = Color(hex: 0x141927)                         // #141927
        static let surfaceElevated = Color(hex: 0x2D344B)                         // #2D344B

        // Actions  (Figma: theme.colors.actions)
        static let actionPrimary   = Color(hex: 0xA0ADD8)                         // #A0ADD8
        static let actionSecondary = Color(hex: 0x7B88B7)                         // #7B88B7

        // Semantic  (Figma: theme.colors.success / warning / error)
        static let success = Color(hex: 0x00B0AD)                                 // #00B0AD
        static let warning = Color(hex: 0xFFB656)                                 // #FFB656
        static let error   = Color(hex: 0xFE7171)                                 // #FE7171

        // Accent
        static let accentPurple = Color(hex: 0xC44EFB)                            // #C44EFB

        // Derived
        static let tabBarTint       = actionPrimary
        static let tabBarBackground = cardBackground
        static let gridLine         = surfaceElevated

        // Course palette — used to color-code courses app-wide.
        static let coursePalette: [Color] = [
            Color(red: 1.0,  green: 0.65, blue: 0.0),   // orange
            Color(red: 0.2,  green: 0.85, blue: 0.8),    // teal
            Color(red: 0.85, green: 0.35, blue: 0.90),   // purple
            Color(red: 0.4,  green: 0.65, blue: 1.0),    // blue
            Color(red: 1.0,  green: 0.4,  blue: 0.6),    // pink
            Color(red: 0.3,  green: 0.85, blue: 0.45)    // green
        ]

        static func courseColor(for index: Int) -> Color {
            coursePalette[index % coursePalette.count]
        }
    }

    // ╔══════════════════════════════════════════════════════════════════╗
    // ║  Fonts                                                           ║
    // ╚══════════════════════════════════════════════════════════════════╝

    enum Fonts {
        static let title           = Font.system(size: 26, weight: .bold)
        static let sectionHeader   = Font.system(size: 20, weight: .semibold)
        static let headline        = Font.system(size: 17, weight: .semibold)
        static let subheadline     = Font.system(size: 14, weight: .semibold)
        static let courseName      = Font.system(size: 15, weight: .bold)
        static let body            = Font.system(size: 15)
        static let caption         = Font.system(size: 13, weight: .regular)
        static let captionMedium   = Font.system(size: 13, weight: .medium)
        static let smallCaption    = Font.system(size: 12)
        static let smallMedium     = Font.system(size: 12, weight: .medium)
        static let micro           = Font.system(size: 11)
        static let microMedium     = Font.system(size: 11, weight: .medium)
        static let daySelector     = Font.system(size: 18, weight: .bold)
        static let gridBlockTitle  = Font.system(size: 11, weight: .bold)
        static let gridBlockDetail = Font.system(size: 9)
        static let badge           = Font.system(size: 10, weight: .bold)
        static let calendarCaptionBold   = Font.system(size: 13, weight: .bold)
        static let calendarDetail        = Font.system(size: 11)

        // Screen-level
        static let screenTitle       = Font.system(size: 28, weight: .bold)
        static let subsectionHeader  = Font.system(size: 18, weight: .semibold)
        static let toolbarAction     = Font.system(size: 16, weight: .medium)
        static let toolbarActionBold = Font.system(size: 16, weight: .semibold)
        static let bodyMedium        = Font.system(size: 15, weight: .medium)
        static let bodySemibold      = Font.system(size: 15, weight: .semibold)

        // Icon sizing (applied to SF Symbols via .font())
        static let iconHero          = Font.system(size: 40)
        static let iconCheckbox      = Font.system(size: 20)
        static let iconCheckboxSmall = Font.system(size: 18)
        static let iconAction        = Font.system(size: 14)
        static let iconChevron       = Font.system(size: 12, weight: .semibold)
    }

    // ╔══════════════════════════════════════════════════════════════════╗
    // ║  Spacing & Sizing                                                ║
    // ╚══════════════════════════════════════════════════════════════════╝

    enum Spacing {
        static let screen: CGFloat              = 16
        static let cardCornerRadius: CGFloat     = 12
        static let fieldCornerRadius: CGFloat    = 10
        static let selectorCornerRadius: CGFloat = 14
        static let cardInternal: CGFloat         = 14
        static let hourRowHeight: CGFloat        = 80
        static let timeColumnWidth: CGFloat      = 40
        static let badgeSize: CGFloat            = 18
        static let daySelectorHeight: CGFloat    = 58
        static let swipeDeleteThreshold: CGFloat = -60
        static let courseBarWidth: CGFloat        = 3
        static let courseTimeColumnWidth: CGFloat = 72
        static let gridBlockCornerRadius: CGFloat  = 6
        static let gridHeaderPadding: CGFloat      = 8
        static let gridHeaderBottomPadding: CGFloat = 6

        /// Inter-section vertical gap (used in month-placeholder, etc.).
        static let sectionGap: CGFloat             = 12
        /// Horizontal space between Mon–Fri day-selector buttons.
        static let daySelectorSpacing: CGFloat      = 8

        /// Calendar-specific sizing (wider columns for the full-week view).
        static let calendarHourRowHeight: CGFloat  = 72
        static let calendarTimeColumnWidth: CGFloat = 74
        static let calendarDayColumnWidth: CGFloat  = 150
    }

    // ╔══════════════════════════════════════════════════════════════════╗
    // ║  Animation                                                       ║
    // ╚══════════════════════════════════════════════════════════════════╝

    static let defaultAnimationDuration: Double = 0.2
}

// MARK: - Color Hex Initializer

extension Color {
    /// Creates a `Color` from a hex integer (e.g. `0xA0ADD8`).
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >>  8) & 0xFF) / 255,
            blue:  Double( hex        & 0xFF) / 255,
            opacity: opacity
        )
    }
}
