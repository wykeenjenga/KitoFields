//
//  KitoFieldShape.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// The outline shape used to draw a field's background and border.
public enum KitoFieldShape: Hashable, Sendable {
    /// Sharp-cornered rectangle.
    case rectangle
    /// Rounded rectangle with a continuous corner curve.
    case roundedRectangle(cornerRadius: CGFloat)
    /// Fully rounded pill.
    case capsule
    /// No enclosing outline; only a single line under the field ("one-line" style).
    case underline

    /// Rounded rectangle with a 12pt radius. The default.
    public static let rounded = KitoFieldShape.roundedRectangle(cornerRadius: 12)

    public var isUnderline: Bool { self == .underline }
}

/// Insettable shape that renders every `KitoFieldShape` except `.underline`.
public struct KitoFieldOutline: InsettableShape {
    public var shape: KitoFieldShape
    public var insetAmount: CGFloat = 0

    public init(_ shape: KitoFieldShape) { self.shape = shape }

    public func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let maxRadius = min(r.width, r.height) / 2
        switch shape {
        case .rectangle, .underline:
            return Path(r)
        case .roundedRectangle(let radius):
            return Path(roundedRect: r, cornerRadius: min(radius, maxRadius), style: .continuous)
        case .capsule:
            return Path(roundedRect: r, cornerRadius: maxRadius, style: .circular)
        }
    }

    public func inset(by amount: CGFloat) -> KitoFieldOutline {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}
