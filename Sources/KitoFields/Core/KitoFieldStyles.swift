//
//  KitoFieldStyles.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

// MARK: - Shared building blocks (public so custom styles can reuse them)

/// Draws background, border (or underline) and shadow for a field row according to the theme.
public struct KitoFieldChrome: ViewModifier {
    public var shape: KitoFieldShape
    public var fill: Color
    public var borderColor: Color
    public var borderWidth: CGFloat
    public var shadow: KitoShadow?

    public init(shape: KitoFieldShape, fill: Color, borderColor: Color, borderWidth: CGFloat, shadow: KitoShadow? = nil) {
        self.shape = shape; self.fill = fill; self.borderColor = borderColor
        self.borderWidth = borderWidth; self.shadow = shadow
    }

    public func body(content: Content) -> some View {
        content
            .background(background)
            .overlay(border)
            .modifier(ShadowModifier(shadow: shadow))
    }

    @ViewBuilder private var background: some View {
        if shape.isUnderline {
            Rectangle().fill(fill)
        } else {
            KitoFieldOutline(shape).fill(fill)
        }
    }

    @ViewBuilder private var border: some View {
        if borderWidth > 0 {
            if shape.isUnderline {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Rectangle().fill(borderColor).frame(height: borderWidth)
                }
            } else {
                KitoFieldOutline(shape).strokeBorder(borderColor, lineWidth: borderWidth)
            }
        }
    }

    private struct ShadowModifier: ViewModifier {
        var shadow: KitoShadow?
        func body(content: Content) -> some View {
            if let s = shadow {
                content.shadow(color: s.color, radius: s.radius, x: s.x, y: s.y)
            } else {
                content
            }
        }
    }
}

public extension View {
    func kitoFieldChrome(_ configuration: KitoFieldStyleConfiguration, fill: Color? = nil, borderWidth: CGFloat? = nil, shape: KitoFieldShape? = nil) -> some View {
        modifier(KitoFloatingErrorModifier(configuration: configuration))
        .modifier(KitoFieldChrome(
            shape: shape ?? configuration.theme.shape,
            fill: fill ?? configuration.backgroundColor,
            borderColor: configuration.borderColor,
            borderWidth: borderWidth ?? configuration.borderWidth,
            shadow: (configuration.isFocused ? configuration.theme.motion.focusedShadow : nil) ?? configuration.theme.shadow
        ))
    }
}

/// Placeholder text drawn over an empty input.
public struct KitoFieldPlaceholder: View {
    let configuration: KitoFieldStyleConfiguration
    public init(_ configuration: KitoFieldStyleConfiguration) { self.configuration = configuration }
    public var body: some View {
        if configuration.isEmpty, let text = configuration.placeholder {
            Text(text)
                .font(configuration.theme.font)
                .foregroundColor(configuration.theme.placeholderColor)
                .lineLimit(1)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

/// Leading accessory, input (with placeholder), trailing accessory in a row with theme padding.
public struct KitoFieldRow: View {
    let configuration: KitoFieldStyleConfiguration
    var showsPlaceholder = true

    public init(_ configuration: KitoFieldStyleConfiguration, showsPlaceholder: Bool = true) {
        self.configuration = configuration
        self.showsPlaceholder = showsPlaceholder
    }

    public var body: some View {
        let theme = configuration.theme
        HStack(spacing: theme.accessorySpacing) {
            if let leading = configuration.leading { leading }
            ZStack(alignment: .leading) {
                if showsPlaceholder { KitoFieldPlaceholder(configuration) }
                configuration.input
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let trailing = configuration.trailing { trailing }
        }
        .padding(theme.contentPadding)
        .frame(minHeight: theme.minHeight)
    }
}

/// Error messages (or helper text when there are none).
public struct KitoFieldMessages: View {
    let configuration: KitoFieldStyleConfiguration
    public init(_ configuration: KitoFieldStyleConfiguration) { self.configuration = configuration }

    public var body: some View {
        let theme = configuration.theme
        let errors = configuration.inlineErrors
        if !errors.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(errors.enumerated()), id: \.offset) { _, message in
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        if let icon = theme.errorIcon {
                            Image(systemName: icon).font(theme.errorIconFont ?? theme.errorFont ?? theme.helperFont)
                        }
                        Text(message).font(theme.errorFont ?? theme.helperFont)
                    }
                    .foregroundColor(theme.errorColor)
                }
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        } else if let helper = configuration.helperText {
            Text(helper)
                .font(theme.helperFont)
                .foregroundColor(theme.helperColor)
        }
    }
}

/// Label above, then content, then messages and footer. Used by all built-in styles.
/// Also owns the field-level motion: focus scale, error shake and animated messages.
public struct KitoFieldStack<Content: View>: View {
    let configuration: KitoFieldStyleConfiguration
    var showsLabel = true
    let content: Content
    @State private var shakes: CGFloat = 0

    public init(_ configuration: KitoFieldStyleConfiguration, showsLabel: Bool = true, @ViewBuilder content: () -> Content) {
        self.configuration = configuration
        self.showsLabel = showsLabel
        self.content = content()
    }

    public var body: some View {
        let theme = configuration.theme
        let motion = configuration.motion
        VStack(alignment: .leading, spacing: 0) {
            if showsLabel, let label = configuration.label {
                label
                    .font(theme.labelFont)
                    .foregroundColor(configuration.labelColor)
                    .padding(.bottom, theme.labelSpacing)
            }
            content
                .scaleEffect(configuration.isFocused ? motion.focusScale : 1)
                .modifier(KitoFieldShakeEffect(shakes: shakes))
            KitoFieldMessages(configuration)
                .padding(.top, (configuration.inlineErrors.isEmpty && configuration.helperText == nil) ? 0 : theme.helperSpacing)
            if let footer = configuration.footer {
                footer.padding(.top, theme.helperSpacing)
            }
        }
        .opacity(configuration.isEnabled ? 1 : theme.disabledOpacity)
        .animation(motion.focus, value: configuration.isFocused)
        .animation(motion.error, value: configuration.errorMessages)
        .animation(motion.pop, value: configuration.isSuccess)
        .animation(motion.pop, value: configuration.isEmpty)
        .onChange(of: configuration.errorMessages.isEmpty) { isEmpty in
            guard !isEmpty, motion.shakesOnError else { return }
            withAnimation(motion.shake) { shakes += 1 }
        }
    }
}

// MARK: - Built-in styles

/// Bordered field with a transparent (or themed) background. The default.
public struct KitoOutlinedFieldStyle: KitoFieldStyle {
    public init() {}
    public func makeBody(configuration c: Configuration) -> some View {
        KitoFieldStack(c) {
            KitoFieldRow(c).kitoFieldChrome(c)
        }
    }
}

/// Solid fill, no border at rest; a thin border appears on focus or error.
public struct KitoFilledFieldStyle: KitoFieldStyle {
    public init() {}
    public func makeBody(configuration c: Configuration) -> some View {
        KitoFieldStack(c) {
            KitoFieldRow(c)
                .kitoFieldChrome(
                    c,
                    fill: c.isFocused ? (c.theme.focusedBackgroundColor ?? c.theme.filledBackgroundColor) : c.theme.filledBackgroundColor,
                    borderWidth: (c.isFocused || c.hasError) && c.theme.showsBorder ? c.theme.focusedBorderWidth : 0
                )
        }
    }
}

/// Single line under the text, regardless of the theme's shape.
public struct KitoUnderlinedFieldStyle: KitoFieldStyle {
    public init() {}
    public func makeBody(configuration c: Configuration) -> some View {
        KitoFieldStack(c) {
            KitoFieldRow(c).kitoFieldChrome(c, shape: .underline)
        }
    }
}

/// No chrome at all; you supply the container.
public struct KitoPlainFieldStyle: KitoFieldStyle {
    public init() {}
    public func makeBody(configuration c: Configuration) -> some View {
        KitoFieldStack(c) {
            KitoFieldRow(c)
        }
    }
}

/// Material-style floating label: the label sits in the field while empty and lifts to the
/// top edge when focused or filled.
public struct KitoFloatingLabelFieldStyle: KitoFieldStyle {
    public init() {}
    public func makeBody(configuration c: Configuration) -> some View {
        let theme = c.theme
        let floating = c.isFocused || !c.isEmpty
        KitoFieldStack(c, showsLabel: false) {
            HStack(spacing: theme.accessorySpacing) {
                if let leading = c.leading { leading }
                ZStack(alignment: .leading) {
                    if let label = c.label {
                        label
                            .font(floating ? theme.helperFont : theme.font)
                            .foregroundColor(floating ? c.labelColor : theme.placeholderColor)
                            .offset(y: floating ? -13 : 0)
                            .allowsHitTesting(false)
                    }
                    ZStack(alignment: .leading) {
                        if floating { KitoFieldPlaceholder(c) }
                        c.input
                    }
                    .offset(y: c.label == nil ? 0 : 9)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if let trailing = c.trailing { trailing }
            }
            .padding(theme.contentPadding)
            .frame(minHeight: max(theme.minHeight, 56))
            .kitoFieldChrome(c)
            .animation(c.motion.label, value: floating)
        }
    }
}

// MARK: - Dot-syntax accessors

public extension KitoFieldStyle where Self == KitoOutlinedFieldStyle {
    static var outlined: KitoOutlinedFieldStyle { KitoOutlinedFieldStyle() }
}
public extension KitoFieldStyle where Self == KitoFilledFieldStyle {
    static var filled: KitoFilledFieldStyle { KitoFilledFieldStyle() }
}
public extension KitoFieldStyle where Self == KitoUnderlinedFieldStyle {
    static var underlined: KitoUnderlinedFieldStyle { KitoUnderlinedFieldStyle() }
}
public extension KitoFieldStyle where Self == KitoPlainFieldStyle {
    static var plain: KitoPlainFieldStyle { KitoPlainFieldStyle() }
}
public extension KitoFieldStyle where Self == KitoFloatingLabelFieldStyle {
    static var floatingLabel: KitoFloatingLabelFieldStyle { KitoFloatingLabelFieldStyle() }
}
