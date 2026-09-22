//
//  KitoCodeFieldStyle.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 22/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// Everything a style needs to draw one `KitoCodeField` box. The field still owns all behaviour
/// (typing, paste, focus, secure masking) — a style only decides how one box looks.
public struct KitoCodeBoxStyleConfiguration {
    public let index: Int
    /// The character to show, already masked/revealed per `.secure`/`.maskCharacter`/
    /// `.revealLastEntered`; nil while this box is still empty.
    public let character: Character?
    public let isActive: Bool
    public let hasError: Bool
    public let isFocused: Bool
    public let isEnabled: Bool
    public let boxSize: CGSize
    public let theme: KitoFieldTheme

    public init(index: Int, character: Character?, isActive: Bool, hasError: Bool, isFocused: Bool, isEnabled: Bool, boxSize: CGSize, theme: KitoFieldTheme) {
        self.index = index
        self.character = character
        self.isActive = isActive
        self.hasError = hasError
        self.isFocused = isFocused
        self.isEnabled = isEnabled
        self.boxSize = boxSize
        self.theme = theme
    }
}

/// Implement to fully replace how `KitoCodeField` draws one box — everything else (the hidden
/// input, paste handling, focus, VoiceOver) stays as-is. Apply with `.style(_:)`.
///
/// ```swift
/// struct DiceBoxStyle: KitoCodeFieldStyle {
///     func makeBox(_ configuration: KitoCodeBoxStyleConfiguration) -> some View {
///         Text(configuration.character.map(String.init) ?? "")
///             .font(.title.bold())
///             .frame(width: configuration.boxSize.width, height: configuration.boxSize.height)
///             .background(RoundedRectangle(cornerRadius: 6).fill(.white))
///             .rotationEffect(configuration.isActive ? .degrees(-4) : .zero)
///     }
/// }
///
/// KitoCodeField(code: $code, length: 6).style(DiceBoxStyle())
/// ```
public protocol KitoCodeFieldStyle {
    associatedtype Body: View
    @ViewBuilder func makeBox(_ configuration: KitoCodeBoxStyleConfiguration) -> Body
}

public extension KitoCodeFieldStyle {
    typealias Configuration = KitoCodeBoxStyleConfiguration
}

/// Type-erased style, stored on the field itself (not the environment — a code field's chrome is
/// almost always specific to that one field, unlike `KitoFieldStyle`).
public struct AnyKitoCodeFieldStyle: KitoCodeFieldStyle {
    private let make: (KitoCodeBoxStyleConfiguration) -> AnyView

    public init<S: KitoCodeFieldStyle>(_ style: S) {
        make = { AnyView(style.makeBox($0)) }
    }

    public func makeBox(_ configuration: KitoCodeBoxStyleConfiguration) -> AnyView {
        make(configuration)
    }
}

/// A single bottom line under the digit, no surrounding box. The same look as
/// `.boxStyle(.underline)` — shipped as a worked example of the protocol.
public struct KitoCodeUnderlineBoxStyle: KitoCodeFieldStyle {
    public init() {}

    public func makeBox(_ configuration: KitoCodeBoxStyleConfiguration) -> some View {
        let color = configuration.hasError
            ? configuration.theme.errorColor
            : (configuration.isActive ? configuration.theme.focusedBorderColor : configuration.theme.borderColor)
        return VStack(spacing: 4) {
            Text(configuration.character.map(String.init) ?? "")
                .font(configuration.theme.font.weight(.semibold))
                .foregroundColor(configuration.theme.textColor)
                .frame(maxHeight: .infinity)
            Rectangle()
                .fill(color)
                .frame(height: configuration.isActive || configuration.hasError ? 2 : 1)
        }
        .frame(width: configuration.boxSize.width, height: configuration.boxSize.height)
    }
}

/// A fully rounded pill per box. Shipped as a worked example of the protocol.
public struct KitoCodePillBoxStyle: KitoCodeFieldStyle {
    public init() {}

    public func makeBox(_ configuration: KitoCodeBoxStyleConfiguration) -> some View {
        let borderColor = configuration.hasError
            ? configuration.theme.errorColor
            : (configuration.isActive ? configuration.theme.focusedBorderColor : Color.clear)
        return Text(configuration.character.map(String.init) ?? "")
            .font(configuration.theme.font.weight(.semibold))
            .foregroundColor(configuration.theme.textColor)
            .frame(width: configuration.boxSize.width, height: configuration.boxSize.height)
            .background(Capsule().fill(configuration.theme.filledBackgroundColor))
            .overlay(Capsule().strokeBorder(borderColor, lineWidth: 2))
    }
}
