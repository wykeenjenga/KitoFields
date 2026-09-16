//
//  KitoAccessory.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// Content placed at the leading or trailing edge of a field: an icon, text, a button, or any view.
public struct KitoAccessory {
    private let builder: (KitoFieldTheme) -> AnyView

    init(_ builder: @escaping (KitoFieldTheme) -> AnyView) {
        self.builder = builder
    }

    func view(theme: KitoFieldTheme) -> AnyView { builder(theme) }

    /// An SF Symbol tinted with the theme's icon color.
    public static func systemImage(_ name: String, color: Color? = nil) -> KitoAccessory {
        KitoAccessory { theme in
            AnyView(
                Image(systemName: name)
                    .font(.system(size: theme.iconSize, weight: .regular))
                    .foregroundColor(color ?? theme.iconColor)
                    .frame(width: theme.iconSize + 6)
            )
        }
    }

    /// Any `Image`, resized to the theme's icon size.
    public static func image(_ image: Image, color: Color? = nil) -> KitoAccessory {
        KitoAccessory { theme in
            AnyView(
                image.resizable().scaledToFit()
                    .frame(width: theme.iconSize, height: theme.iconSize)
                    .foregroundColor(color ?? theme.iconColor)
            )
        }
    }

    /// Short text such as a unit or currency symbol.
    public static func text(_ text: String, color: Color? = nil) -> KitoAccessory {
        KitoAccessory { theme in
            AnyView(
                Text(text)
                    .font(theme.font)
                    .foregroundColor(color ?? theme.iconColor)
            )
        }
    }

    /// A tappable SF Symbol.
    public static func button(systemImage: String, accessibilityLabel: String, color: Color? = nil, action: @escaping () -> Void) -> KitoAccessory {
        KitoAccessory { theme in
            AnyView(
                Button(action: action) {
                    Image(systemName: systemImage)
                        .font(.system(size: theme.iconSize))
                        .foregroundColor(color ?? theme.iconColor)
                        .frame(width: theme.iconSize + 6, height: theme.iconSize + 6)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityLabel)
            )
        }
    }

    /// Arbitrary SwiftUI content.
    public static func custom<V: View>(@ViewBuilder _ content: @escaping () -> V) -> KitoAccessory {
        KitoAccessory { _ in AnyView(content()) }
    }

    /// Arbitrary content that can read the current theme.
    public static func themed<V: View>(@ViewBuilder _ content: @escaping (KitoFieldTheme) -> V) -> KitoAccessory {
        KitoAccessory { theme in AnyView(content(theme)) }
    }
}
