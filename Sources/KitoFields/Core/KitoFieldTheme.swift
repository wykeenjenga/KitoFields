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
    public var tintColor: Color? = nil
    public var disabledOpacity: Double = 0.5

    // MARK: Typography
    public var font: Font = .body
    public var labelFont: Font = .subheadline.weight(.medium)
    public var helperFont: Font = .caption
    public var iconSize: CGFloat = 17

    // MARK: Layout
    public var accessorySpacing: CGFloat = 10
    public var labelSpacing: CGFloat = 6
    public var helperSpacing: CGFloat = 6
    public var errorDisplay: KitoErrorDisplay = .first
    /// Appended to the label of required fields. Set to nil to hide.
    public var requiredIndicator: String? = "*"
    public var requiredIndicatorColor: Color = .red
    /// Appended to the label of fields that are not required (e.g. "Optional"). Nil hides it.
    public var optionalIndicator: String? = nil
    public var showsFocusHighlight: Bool = true

    // MARK: Motion
    /// All field animation timings (focus, error, label float, pops, shake).
    public var motion: KitoFieldMotion = .default
    /// Legacy single animation used by footers and pickers; defaults to `motion.focus`.
    public var animation: Animation? = .spring(response: 0.3, dampingFraction: 0.8)

    public init() {}

    public static let `default` = KitoFieldTheme()

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
        #if os(iOS)
        return Color(UIColor.secondarySystemBackground)
        #elseif os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color.gray.opacity(0.12)
        #endif
    }
}
