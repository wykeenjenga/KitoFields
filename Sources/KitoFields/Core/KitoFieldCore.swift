//
//  KitoFieldCore.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// Internal assembler: turns a field's parts plus its options into a style configuration and
/// hands it to the current style.
struct KitoFieldCore<Input: View, Footer: View>: View {
    var options: KitoFieldOptions
    var isFocused: Bool
    var isEmpty: Bool
    var errors: [String]
    var isSuccess: Bool
    var leadingOverride: AnyView?
    var trailingExtras: [AnyView]
    var input: Input
    var footer: Footer?

    @Environment(\.kitoFieldStyle) private var style
    @Environment(\.kitoFieldTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        style.makeBody(configuration: configuration)
    }

    private var configuration: KitoFieldStyleConfiguration {
        KitoFieldStyleConfiguration(
            label: labelSlot,
            placeholder: options.placeholder,
            input: KitoFieldSlot(input),
            leading: leadingSlot,
            trailing: trailingSlot,
            footer: footer.map { KitoFieldSlot($0) },
            helperText: options.helperText,
            errorMessages: errors,
            isFocused: isFocused,
            isEnabled: isEnabled,
            isEmpty: isEmpty,
            isSuccess: isSuccess,
            theme: theme,
            reducesMotion: reduceMotion
        )
    }

    private var labelSlot: KitoFieldSlot? {
        guard let label = options.label else { return nil }
        var text = Text(label)
        if options.isRequired, let indicator = theme.requiredIndicator {
            text = text + Text(" \(indicator)").foregroundColor(theme.requiredIndicatorColor)
        } else if !options.isRequired, let optional = theme.optionalIndicator {
            text = text + Text(" \(optional)").font(theme.helperFont).foregroundColor(theme.helperColor)
        }
        return KitoFieldSlot(text)
    }

    private var leadingSlot: KitoFieldSlot? {
        if let override = leadingOverride { return KitoFieldSlot(override) }
        return options.leading.map { KitoFieldSlot($0.view(theme: theme)) }
    }

    private var trailingSlot: KitoFieldSlot? {
        let custom = options.trailing?.view(theme: theme)
        if custom == nil && trailingExtras.isEmpty { return nil }
        return KitoFieldSlot(
            HStack(spacing: theme.accessorySpacing * 0.6) {
                ForEach(Array(trailingExtras.enumerated()), id: \.offset) { $0.element }
                if let custom { custom }
            }
        )
    }
}

/// Small reusable trailing controls.
enum KitoFieldControls {
    static func clearButton(theme: KitoFieldTheme, action: @escaping () -> Void) -> AnyView {
        AnyView(
            Button(action: action) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: theme.iconSize))
                    .foregroundColor(theme.iconColor.opacity(0.8))
                    .frame(width: theme.iconSize + 8, height: theme.iconSize + 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Clear text")
        )
    }

    static func validationIcon(isError: Bool, theme: KitoFieldTheme) -> AnyView {
        AnyView(
            Image(systemName: isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: theme.iconSize))
                .foregroundColor(isError ? theme.errorColor : theme.successColor)
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel(isError ? "Invalid" : "Valid")
        )
    }
}
