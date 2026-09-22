//
//  KitoFieldTheme.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// Drop shadow applied to a field's chrome.
public struct KitoShadow: Equatable, Sendable {
    public var color: Color
    public var radius: CGFloat
    public var x: CGFloat
    public var y: CGFloat

    public init(color: Color = .black.opacity(0.08), radius: CGFloat = 8, x: CGFloat = 0, y: CGFloat = 2) {
        self.color = color; self.radius = radius; self.x = x; self.y = y
    }
}

/// How validation errors are listed beneath a field.
public enum KitoErrorDisplay: Sendable {
    /// Only the first failing rule's message.
    case first
    /// Every failing rule's message, one per line.
    case all
    /// Never render error text (the border still turns red).
    case none
}

/// Visual tokens shared by every KitoFields field. Set once via `.kitoFieldTheme(...)` and
/// override per field or per screen as needed.
public struct KitoFieldTheme: Sendable {

    // MARK: Shape & chrome
    public var shape: KitoFieldShape = .rounded
    public var showsBorder: Bool = true
    public var borderWidth: CGFloat = 1
    public var focusedBorderWidth: CGFloat = 1.5
    public var shadow: KitoShadow? = nil
    public var minHeight: CGFloat = 48
    public var contentPadding: EdgeInsets = EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)

    // MARK: Colors
    public var backgroundColor: Color = .clear
    public var filledBackgroundColor: Color = KitoFieldTheme.platformFill
    public var focusedBackgroundColor: Color? = nil
    public var borderColor: Color = Color.gray.opacity(0.35)
    public var focusedBorderColor: Color = .accentColor
    public var errorColor: Color = .red
    public var successColor: Color = .green
    public var highlightsSuccessBorder: Bool = false
    public var textColor: Color = .primary
    public var placeholderColor: Color = Color.secondary.opacity(0.7)
    public var labelColor: Color = .secondary
    public var focusedLabelColor: Color? = nil
    public var helperColor: Color = .secondary
    public var iconColor: Color = .secondary
    /// Icon colour while focused; nil uses `focusedBorderColor`.
    public var focusedIconColor: Color? = nil
    public var tintColor: Color? = nil
    public var disabledOpacity: Double = 0.5

    // MARK: Typography
    public var font: Font = .body
    #if canImport(UIKit)
    /// Font for UIKit-backed inputs (the phone number field on iOS). SwiftUI's `Font` cannot be
    /// bridged to `UIFont`, so set this alongside `font` when you use a custom typeface.
    /// Nil uses the Dynamic Type body font.
    public var uiFont: UIFont? = nil
    #endif
    public var labelFont: Font = .subheadline.weight(.medium)
    public var helperFont: Font = .caption
    /// Font for error text; nil uses `helperFont`.
    public var errorFont: Font? = nil
    /// SF Symbol shown before each error line; nil hides the icon.
    public var errorIcon: String? = "exclamationmark.circle.fill"
    /// Font (size/weight) for the error icon; nil matches the error text.
    public var errorIconFont: Font? = nil
    public var iconSize: CGFloat = 17

    // MARK: Layout
    public var accessorySpacing: CGFloat = 10
    public var labelSpacing: CGFloat = 6
    public var helperSpacing: CGFloat = 6
    public var errorDisplay: KitoErrorDisplay = .first
    /// Inline text, floating bubble, bubble while focused, or none. Fields can override per instance.
    public var errorPresentation: KitoErrorPresentation = .inline
    /// Bubble colours for the floating presentations; nil uses `errorColor` and white.
    public var errorBubbleBackground: Color? = nil
    public var errorBubbleForeground: Color = .white
    /// Appended to the label of required fields. Set to nil to hide.
    public var requiredIndicator: String? = "*"
    public var requiredIndicatorColor: Color = .red
    /// Font for the required indicator; nil uses the label's own font.
    public var requiredIndicatorFont: Font? = nil
    /// Appended to the label of fields that are not required (e.g. "Optional"). Nil hides it.
    public var optionalIndicator: String? = nil
    /// Font for the optional indicator; nil uses `helperFont`.
    public var optionalIndicatorFont: Font? = nil
    /// Colour for the optional indicator; nil uses `helperColor`.
    public var optionalIndicatorColor: Color? = nil
    public var showsFocusHighlight: Bool = true

    // MARK: Motion
    /// All field animation timings (focus, error, label float, pops, shake).
    public var motion: KitoFieldMotion = .default
    /// Legacy single animation used by footers and pickers; defaults to `motion.focus`.
    public var animation: Animation? = .spring(response: 0.3, dampingFraction: 0.8)

    public init() {}

    /// The theme every field falls back to when nothing in its view hierarchy sets
    /// `.kitoFieldTheme(...)`. Set this **once**, e.g. in your `App`'s `init()`, to apply a look
    /// (a custom font, a brand tint) app-wide without wrapping every screen in a modifier:
    ///
    /// ```swift
    /// @main
    /// struct MyApp: App {
    ///     init() { KitoFieldTheme.default = .custom(myBrandFont) }
    ///     var body: some Scene { WindowGroup { ContentView() } }
    /// }
    /// ```
    ///
    /// An explicit `.kitoFieldTheme(...)` anywhere in the view hierarchy still overrides this for
    /// that subtree — including the built-in `.soft`/`.capsule`/`.sharp`/`.underline` presets,
    /// none of which carry a custom font. Build from `.default` instead of a preset if you need
    /// both: `KitoFieldTheme.default.shape = .capsule` (after setting `.default`), or start a
    /// per-screen override from `KitoFieldTheme.default` rather than `.capsule` directly.
    public static var `default` = KitoFieldTheme()

    /// Builds a theme where every text role — field text, labels, helper and error text — uses
    /// `family`, at the size/weight this theme would otherwise use for that role. Dynamic Type
    /// still scales, via `relativeTo:`.
    ///
    /// ```swift
    /// KitoFieldTheme.default = .custom(KitoFontFamily(regular: "Inter-Regular", semibold: "Inter-SemiBold"))
    /// ```
    public static func custom(_ family: KitoFontFamily, base: KitoFieldTheme = KitoFieldTheme()) -> KitoFieldTheme {
        var theme = base
        theme.font = family.font(size: 17, relativeTo: .body)
        theme.labelFont = family.font(size: 15, weight: .medium, relativeTo: .subheadline)
        theme.helperFont = family.font(size: 12, relativeTo: .caption)
        theme.errorFont = family.font(size: 13, relativeTo: .footnote)
        theme.errorIconFont = family.font(size: 12, relativeTo: .footnote)
        #if canImport(UIKit)
        theme.uiFont = family.uiFont(size: 17)
        #endif
        return theme
    }

    /// Rounded, subtle shadow, no visible border until focused.
    public static var soft: KitoFieldTheme {
        var t = KitoFieldTheme()
        t.shape = .roundedRectangle(cornerRadius: 14)
        t.borderColor = .clear
        t.shadow = KitoShadow()
        return t
    }

    /// Pill-shaped fields.
    public static var capsule: KitoFieldTheme {
        var t = KitoFieldTheme()
        t.shape = .capsule
        t.contentPadding = EdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 18)
        return t
    }

    /// Sharp corners with a heavier border.
    public static var sharp: KitoFieldTheme {
        var t = KitoFieldTheme()
        t.shape = .rectangle
        t.borderWidth = 1.5
        t.focusedBorderWidth = 2
        return t
    }

    /// Single underline, transparent background.
    public static var underline: KitoFieldTheme {
        var t = KitoFieldTheme()
        t.shape = .underline
        t.contentPadding = EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)
        return t
    }

    public static var platformFill: Color {
        #if os(iOS) || os(visionOS)
        return Color(UIColor.secondarySystemBackground)
        #elseif os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color.gray.opacity(0.12)
        #endif
    }
}
