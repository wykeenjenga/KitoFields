//
//  KitoFieldMotion.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// Motion presets for fields. Exposed as computed presets so the whole form animates consistently;
/// tune via `KitoFieldTheme.motion`.
public struct KitoFieldMotion: Sendable {
    /// Border colour/width, background and scale changes on focus.
    public var focus: Animation = .spring(response: 0.3, dampingFraction: 0.8)
    /// Error text appearing/disappearing, border turning red.
    public var error: Animation = .easeInOut(duration: 0.18)
    /// Floating-label lift.
    public var label: Animation = .spring(response: 0.3, dampingFraction: 0.75)
    /// Success tick, clear button, flag and counter pops.
    public var pop: Animation = .spring(response: 0.3, dampingFraction: 0.55)
    /// Horizontal shake when an error first appears.
    public var shake: Animation = .linear(duration: 0.4)
    /// Shake when validation fails. Set false for reduced motion.
    public var shakesOnError: Bool = true
    /// Scale applied to the whole field while focused (1 = none). 1.02 gives a gentle "lift".
    public var focusScale: CGFloat = 1
    /// Shadow used while focused; nil keeps the theme shadow.
    public var focusedShadow: KitoShadow? = nil

    public init() {}

    public static var `default`: KitoFieldMotion { KitoFieldMotion() }

    /// Springy, with a subtle lift and glow on focus.
    public static var lively: KitoFieldMotion {
        var m = KitoFieldMotion()
        m.focus = .spring(response: 0.28, dampingFraction: 0.6)
        m.focusScale = 1.02
        m.focusedShadow = KitoShadow(color: Color.accentColor.opacity(0.25), radius: 12, y: 4)
        m.pop = .spring(response: 0.25, dampingFraction: 0.45)
        return m
    }

    /// Minimal motion.
    public static var subtle: KitoFieldMotion {
        var m = KitoFieldMotion()
        m.focus = .easeOut(duration: 0.12)
        m.label = .easeOut(duration: 0.15)
        m.pop = .easeOut(duration: 0.12)
        m.shakesOnError = false
        return m
    }
}

/// Horizontal shake. Increase `shakes` by one inside `withAnimation` to trigger.
public struct KitoFieldShakeEffect: GeometryEffect {
    public var shakes: CGFloat
    public var amplitude: CGFloat

    public init(shakes: CGFloat, amplitude: CGFloat = 8) {
        self.shakes = shakes
        self.amplitude = amplitude
    }

    public var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    public func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amplitude * sin(shakes * .pi * 4), y: 0))
    }
}

struct KitoFieldShakeOnChange<Trigger: Equatable>: ViewModifier {
    var trigger: Trigger
    var animation: Animation
    @State private var shakes: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .modifier(KitoFieldShakeEffect(shakes: shakes))
            .onChange(of: trigger) { _ in withAnimation(animation) { shakes += 1 } }
    }
}

public extension View {
    /// Shakes the view each time `trigger` changes (e.g. a failed-submit counter).
    func kitoFieldShake<T: Equatable>(trigger: T, animation: Animation = KitoFieldMotion.default.shake) -> some View {
        modifier(KitoFieldShakeOnChange(trigger: trigger, animation: animation))
    }
}
