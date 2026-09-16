//
//  KitoFlag.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// How a country is depicted in selectors and lists.
public enum KitoFlagStyle: Sendable {
    /// Regional-indicator emoji flag.
    case emoji
    /// Two-letter ISO code in a small badge.
    case isoCode
    /// Nothing.
    case hidden
}

public struct KitoFlag: View {
    public var country: KitoCountry
    public var style: KitoFlagStyle = .emoji
    public var size: CGFloat = 22

    public init(country: KitoCountry, style: KitoFlagStyle = .emoji, size: CGFloat = 22) {
        self.country = country
        self.style = style
        self.size = size
    }

    public var body: some View {
        switch style {
        case .emoji:
            Text(country.flag)
                .font(.system(size: size))
                .accessibilityHidden(true)
        case .isoCode:
            Text(country.isoCode)
                .font(.system(size: size * 0.55, weight: .semibold, design: .rounded))
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.15)))
                .accessibilityHidden(true)
        case .hidden:
            EmptyView()
        }
    }
}
