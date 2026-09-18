//
//  KitoFontFamily.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 18/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// A custom typeface's PostScript names, one per weight.
///
/// Most custom fonts (Inter, Poppins, a brand's own typeface) ship as separate font files with
/// distinct PostScript names per weight — `"Inter-Regular"`, `"Inter-SemiBold"`, `"Inter-Bold"` —
/// rather than one name SwiftUI can re-weight with `.weight()`. Passing just a family name to
/// `Font.custom` and calling `.weight(.semibold)` on it silently does nothing for most such fonts;
/// this type makes the per-weight name explicit so bold and semibold text actually looks bold.
///
/// ```swift
/// let brand = KitoFontFamily(regular: "Inter-Regular", medium: "Inter-Medium", semibold: "Inter-SemiBold", bold: "Inter-Bold")
/// KitoFieldTheme.default = .custom(brand)
/// ```
///
/// If your font truly is a single variable-weight name that `.weight()` works with, pass it as
/// `regular` only — every role falls back to `regular` when a heavier name isn't given.
public struct KitoFontFamily: Sendable, Equatable {
    public var regular: String
    public var medium: String?
    public var semibold: String?
    public var bold: String?

    public init(regular: String, medium: String? = nil, semibold: String? = nil, bold: String? = nil) {
        self.regular = regular
        self.medium = medium
        self.semibold = semibold
        self.bold = bold
    }

    /// The PostScript name to use for `weight`, falling back progressively toward `regular`.
    public func name(for weight: Font.Weight) -> String {
        switch weight {
        case .bold, .heavy, .black: return bold ?? semibold ?? medium ?? regular
        case .semibold: return semibold ?? medium ?? regular
        case .medium: return medium ?? regular
        default: return regular
        }
    }

    /// A Dynamic-Type-aware custom `Font` at `size`, scaling relative to `style` the way a system
    /// font would.
    public func font(size: CGFloat, weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(name(for: weight), size: size, relativeTo: style)
    }

    #if canImport(UIKit)
    /// A `UIFont` at `size` for the UIKit-backed inputs (`KitoFieldTheme.uiFont`). Falls back to
    /// the Dynamic Type body font if the named font isn't actually installed/bundled.
    public func uiFont(size: CGFloat, weight: Font.Weight = .regular) -> UIFont {
        let uiWeight: UIFont.Weight
        switch weight {
        case .bold, .heavy, .black: uiWeight = .bold
        case .semibold: uiWeight = .semibold
        case .medium: uiWeight = .medium
        default: uiWeight = .regular
        }
        guard let font = UIFont(name: name(for: weight), size: size) else {
            return UIFont.systemFont(ofSize: size, weight: uiWeight)
        }
        let metrics = UIFontMetrics(forTextStyle: .body)
        return metrics.scaledFont(for: font)
    }
    #endif
}
