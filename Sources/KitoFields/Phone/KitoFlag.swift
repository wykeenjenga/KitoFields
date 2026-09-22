//
//  KitoFlag.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// How a country is depicted in selectors and lists.
public enum KitoFlagStyle: Hashable, Sendable {
    /// Regional-indicator emoji flag, as-is.
    case emoji
    /// Emoji flag clipped to a filled circle. The default everywhere.
    case circle
    /// Emoji flag clipped to a rounded rectangle.
    case rounded
    /// Emoji flag on a soft tinted background tile.
    case tile
    /// Two-letter ISO code in a small badge.
    case isoCode
    /// Nothing.
    case hidden
}

/// Precedence for how a flag is drawn: what the field was asked for, else the theme's app-wide
/// choice, else the package default — a filled circle. Kept as a free function so the precedence
/// is testable on its own.
public func kitoResolvedFlagStyle(_ override: KitoFlagStyle?, themeStyle: KitoFlagStyle?) -> KitoFlagStyle {
    override ?? themeStyle ?? .circle
}

public struct KitoFlag: View {
    public var country: KitoCountry
    public var style: KitoFlagStyle = .circle
    public var size: CGFloat = 22
    /// Background used by `.tile`, and behind `.circle` / `.rounded` where the emoji has gaps.
    public var background: Color = Color.secondary.opacity(0.15)

    public init(country: KitoCountry, style: KitoFlagStyle = .circle, size: CGFloat = 22, background: Color = Color.secondary.opacity(0.15)) {
        self.country = country
        self.style = style
        self.size = size
        self.background = background
    }

    public var body: some View {
        switch style {
        case .emoji:
            Text(country.flag)
                .font(.system(size: size))
                .accessibilityHidden(true)
        case .circle:
            clipped(Circle())
        case .rounded:
            clipped(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        case .tile:
            Text(country.flag)
                .font(.system(size: size * 0.8))
                .frame(width: size * 1.4, height: size * 1.4)
                .background(RoundedRectangle(cornerRadius: size * 0.3, style: .continuous).fill(background))
                .accessibilityHidden(true)
        case .isoCode:
            Text(country.isoCode)
                .font(.system(size: size * 0.55, weight: .semibold, design: .rounded))
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 4).fill(background))
                .accessibilityHidden(true)
        case .hidden:
            EmptyView()
        }
    }

    /// Emoji flag glyphs carry their own internal padding and don't fill their font's em-box, so a
    /// modest scale-up (as before) still leaves a visible ring of `background` inside the shape.
    /// Render well oversized, crop once to a still-oversized square, then crop again down to the
    /// final `size × size` shape — two crops guarantee full bleed with no gaps on any platform.
    private func clipped<S: Shape>(_ shape: S) -> some View {
        ZStack {
            shape.fill(background)
            Text(country.flag)
                .font(.system(size: size * 2.2))
                .frame(width: size * 1.8, height: size * 1.8)
                .clipped()
        }
        .frame(width: size, height: size)
        .clipShape(shape)
        .accessibilityHidden(true)
    }
}
