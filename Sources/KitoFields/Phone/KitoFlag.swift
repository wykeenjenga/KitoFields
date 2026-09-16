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
    /// Emoji flag clipped to a filled circle.
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

public struct KitoFlag: View {
    public var country: KitoCountry
    public var style: KitoFlagStyle = .emoji
    public var size: CGFloat = 22
    /// Background used by `.tile`, and behind `.circle` / `.rounded` where the emoji has gaps.
    public var background: Color = Color.secondary.opacity(0.15)

    public init(country: KitoCountry, style: KitoFlagStyle = .emoji, size: CGFloat = 22, background: Color = Color.secondary.opacity(0.15)) {
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

    /// Emoji flags are wider than tall; scale up and clip so the shape is fully covered.
    private func clipped<S: Shape>(_ shape: S) -> some View {
        ZStack {
            shape.fill(background)
            Text(country.flag)
                .font(.system(size: size * 1.35))
                .frame(width: size * 1.1, height: size * 1.1)
                .clipped()
        }
        .frame(width: size * 1.1, height: size * 1.1)
        .clipShape(shape)
        .accessibilityHidden(true)
    }
}
