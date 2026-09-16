//
//  KitoFieldStyle.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// Type-erased piece of a field handed to a style (label, input, accessories, footer).
public struct KitoFieldSlot: View {
    private let content: AnyView
    public init<V: View>(_ view: V) { content = AnyView(view) }
    public var body: some View { content }
}

/// Everything a style needs to draw a field. Styles decide layout and chrome; fields supply the parts.
public struct KitoFieldStyleConfiguration {
    /// Unstyled label text, or nil when the field has no label.
    public let label: KitoFieldSlot?
    /// Placeholder text shown while the field is empty. Styles draw it themselves so they can
    /// position it freely (e.g. floating labels).
    public let placeholder: String?
    /// The editable control (TextField / SecureField / composite). Never nil.
    public let input: KitoFieldSlot
    public let leading: KitoFieldSlot?
    public let trailing: KitoFieldSlot?
    /// Extra content under the field (password strength, requirement checklist, counters).
    public let footer: KitoFieldSlot?
    public let helperText: String?
    /// Errors that should currently be visible. Empty when nothing should be shown.
    public let errorMessages: [String]
    public let isFocused: Bool
    public let isEnabled: Bool
    public let isEmpty: Bool
    /// True when the value is non-empty and passes every rule, and the field wants success shown.
    public let isSuccess: Bool
    public let theme: KitoFieldTheme

    public init(label: KitoFieldSlot?, placeholder: String?, input: KitoFieldSlot, leading: KitoFieldSlot?, trailing: KitoFieldSlot?, footer: KitoFieldSlot?, helperText: String?, errorMessages: [String], isFocused: Bool, isEnabled: Bool, isEmpty: Bool, isSuccess: Bool, theme: KitoFieldTheme) {
        self.label = label; self.placeholder = placeholder; self.input = input
        self.leading = leading; self.trailing = trailing; self.footer = footer
        self.helperText = helperText; self.errorMessages = errorMessages
        self.isFocused = isFocused; self.isEnabled = isEnabled; self.isEmpty = isEmpty
        self.isSuccess = isSuccess; self.theme = theme
    }

    public var hasError: Bool { !errorMessages.isEmpty }

    /// Border color resolved from error / focus / success / idle state.
    public var borderColor: Color {
        if hasError { return theme.errorColor }
        if isFocused && theme.showsFocusHighlight { return theme.focusedBorderColor }
        if isSuccess && theme.highlightsSuccessBorder { return theme.successColor }
        return theme.borderColor
    }

    public var borderWidth: CGFloat {
        guard theme.showsBorder else { return 0 }
        return (isFocused || hasError) ? theme.focusedBorderWidth : theme.borderWidth
    }

    public var backgroundColor: Color {
        if isFocused, let focused = theme.focusedBackgroundColor { return focused }
        return theme.backgroundColor
    }

    /// Errors filtered by the theme's `errorDisplay` policy.
    public var displayedErrors: [String] {
        switch theme.errorDisplay {
        case .first: return Array(errorMessages.prefix(1))
        case .all: return errorMessages
        case .none: return []
        }
    }

    public var labelColor: Color {
        if hasError { return theme.errorColor }
        if isFocused, let c = theme.focusedLabelColor { return c }
        return theme.labelColor
    }
}

/// Implement to fully control how fields are drawn. Apply with `.kitoFieldStyle(_:)`.
public protocol KitoFieldStyle {
    associatedtype Body: View
    @ViewBuilder func makeBody(configuration: KitoFieldStyleConfiguration) -> Body
}

public extension KitoFieldStyle {
    typealias Configuration = KitoFieldStyleConfiguration
}

/// Type-erased style stored in the environment.
public struct AnyKitoFieldStyle: KitoFieldStyle {
    private let make: (KitoFieldStyleConfiguration) -> AnyView

    public init<S: KitoFieldStyle>(_ style: S) {
        make = { AnyView(style.makeBody(configuration: $0)) }
    }

    public func makeBody(configuration: KitoFieldStyleConfiguration) -> AnyView {
        make(configuration)
    }
}

// MARK: - Environment plumbing

private struct KitoFieldStyleKey: EnvironmentKey {
    static let defaultValue = AnyKitoFieldStyle(KitoOutlinedFieldStyle())
}

private struct KitoFieldThemeKey: EnvironmentKey {
    static let defaultValue = KitoFieldTheme.default
}

public extension EnvironmentValues {
    var kitoFieldStyle: AnyKitoFieldStyle {
        get { self[KitoFieldStyleKey.self] }
        set { self[KitoFieldStyleKey.self] = newValue }
    }

    var kitoFieldTheme: KitoFieldTheme {
        get { self[KitoFieldThemeKey.self] }
        set { self[KitoFieldThemeKey.self] = newValue }
    }
}

public extension View {
    /// Sets the drawing style for every KitoFields field in this hierarchy.
    func kitoFieldStyle<S: KitoFieldStyle>(_ style: S) -> some View {
        environment(\.kitoFieldStyle, AnyKitoFieldStyle(style))
    }

    /// Replaces the theme for every KitoFields field in this hierarchy.
    func kitoFieldTheme(_ theme: KitoFieldTheme) -> some View {
        environment(\.kitoFieldTheme, theme)
    }

    /// Tweaks individual theme tokens while inheriting the rest.
    func kitoFieldTheme(_ transform: @escaping (inout KitoFieldTheme) -> Void) -> some View {
        transformEnvironment(\.kitoFieldTheme, transform: transform)
    }

    /// Convenience for the most common tweak.
    func kitoFieldShape(_ shape: KitoFieldShape) -> some View {
        transformEnvironment(\.kitoFieldTheme) { $0.shape = shape }
    }
}
