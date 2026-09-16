//
//  KitoAccessory.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// State handed to accessories so they can react to the field.
public struct KitoAccessoryContext {
    public let theme: KitoFieldTheme
    public let isFocused: Bool
    public let isEmpty: Bool
    public let hasError: Bool
    public let isSuccess: Bool
    public let reducesMotion: Bool

    public init(theme: KitoFieldTheme, isFocused: Bool = false, isEmpty: Bool = true, hasError: Bool = false, isSuccess: Bool = false, reducesMotion: Bool = false) {
        self.theme = theme; self.isFocused = isFocused; self.isEmpty = isEmpty
        self.hasError = hasError; self.isSuccess = isSuccess; self.reducesMotion = reducesMotion
    }

    /// Icon colour for the current state: error, focused, success or idle.
    public var iconColor: Color {
        if hasError { return theme.errorColor }
        if isFocused { return theme.focusedIconColor ?? theme.focusedBorderColor }
        if isSuccess { return theme.successColor }
        return theme.iconColor
    }
}

/// How an animated icon reacts when the field gains focus.
public enum KitoIconMotion: Sendable {
    /// Crossfade/scale between the idle and focused symbol.
    case swap
    /// Swap plus a small bounce.
    case bounce
    /// Swap plus a quick wiggle.
    case wiggle
    /// Swap plus a pulse ring behind the icon.
    case pulse
}

/// Content placed at the leading or trailing edge of a field: an icon, text, a button, or any view.
public struct KitoAccessory {
    private let builder: (KitoAccessoryContext) -> AnyView

    init(_ builder: @escaping (KitoAccessoryContext) -> AnyView) {
        self.builder = builder
    }

    func view(theme: KitoFieldTheme) -> AnyView { builder(KitoAccessoryContext(theme: theme)) }
    func view(_ context: KitoAccessoryContext) -> AnyView { builder(context) }

    /// An SF Symbol tinted with the theme's icon colour (turns red on error, accent on focus).
    public static func systemImage(_ name: String, color: Color? = nil) -> KitoAccessory {
        KitoAccessory { ctx in
            AnyView(
                Image(systemName: name)
                    .font(.system(size: ctx.theme.iconSize, weight: .regular))
                    .foregroundColor(color ?? ctx.iconColor)
                    .frame(width: ctx.theme.iconSize + 6)
                    .animation(ctx.theme.motion.focus, value: ctx.isFocused)
            )
        }
    }

    /// An SF Symbol that swaps to `focused` (e.g. "person" → "person.fill") and animates when the
    /// field is focused, wiggles on error and pops on success.
    public static func animatedSymbol(_ idle: String, focused: String? = nil, error: String? = nil, motion: KitoIconMotion = .bounce, color: Color? = nil) -> KitoAccessory {
        KitoAccessory { ctx in
            AnyView(KitoAnimatedIcon(idle: idle, focused: focused ?? idle, error: error, motion: motion, color: color, context: ctx))
        }
    }

    /// Any `Image`, resized to the theme's icon size.
    public static func image(_ image: Image, color: Color? = nil) -> KitoAccessory {
        KitoAccessory { ctx in
            AnyView(
                image.resizable().scaledToFit()
                    .frame(width: ctx.theme.iconSize, height: ctx.theme.iconSize)
                    .foregroundColor(color ?? ctx.iconColor)
            )
        }
    }

    /// Short text such as a unit or currency symbol.
    public static func text(_ text: String, color: Color? = nil) -> KitoAccessory {
        KitoAccessory { ctx in
            AnyView(
                Text(text)
                    .font(ctx.theme.font)
                    .foregroundColor(color ?? ctx.theme.iconColor)
            )
        }
    }

    /// A tappable SF Symbol.
    public static func button(systemImage: String, accessibilityLabel: String, color: Color? = nil, action: @escaping () -> Void) -> KitoAccessory {
        KitoAccessory { ctx in
            AnyView(
                Button(action: action) {
                    Image(systemName: systemImage)
                        .font(.system(size: ctx.theme.iconSize))
                        .foregroundColor(color ?? ctx.theme.iconColor)
                        .frame(width: ctx.theme.iconSize + 6, height: ctx.theme.iconSize + 6)
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
        KitoAccessory { ctx in AnyView(content(ctx.theme)) }
    }

    /// Arbitrary content that can read the field state (focus, error, success, emptiness).
    public static func reactive<V: View>(@ViewBuilder _ content: @escaping (KitoAccessoryContext) -> V) -> KitoAccessory {
        KitoAccessory { ctx in AnyView(content(ctx)) }
    }
}

/// Symbol that swaps, bounces, wiggles or pulses with the field state.
public struct KitoAnimatedIcon: View {
    let idle: String
    let focused: String
    let error: String?
    let motion: KitoIconMotion
    let color: Color?
    let context: KitoAccessoryContext

    @State private var bounce: CGFloat = 1
    @State private var wiggle: CGFloat = 0
    @State private var pulse: CGFloat = 0

    private var symbolName: String {
        if context.hasError, let error { return error }
        return (context.isFocused || !context.isEmpty) ? focused : idle
    }

    public var body: some View {
        let size = context.theme.iconSize
        ZStack {
            if motion == .pulse {
                Circle()
                    .stroke((color ?? context.iconColor).opacity(Double(1 - pulse) * 0.6), lineWidth: 2)
                    .frame(width: size + 6 + pulse * 18, height: size + 6 + pulse * 18)
            }
            Image(systemName: symbolName)
                .font(.system(size: size, weight: .regular))
                .foregroundColor(color ?? context.iconColor)
                .id(symbolName)
                .transition(.scale(scale: 0.6).combined(with: .opacity))
                .scaleEffect(bounce)
                .rotationEffect(.degrees(Double(wiggle)))
        }
        .frame(width: size + 6, height: size + 6)
        .animation(context.theme.motion.pop, value: symbolName)
        .onChange(of: context.isFocused) { isFocused in if isFocused { play() } }
        .onChange(of: context.hasError) { hasError in if hasError { shake() } }
        .onChange(of: context.isSuccess) { ok in if ok { play() } }
        .accessibilityHidden(true)
    }

    private func play() {
        guard !context.reducesMotion else { return }
        switch motion {
        case .swap:
            break
        case .bounce:
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) { bounce = 1.25 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { bounce = 1 } }
        case .wiggle:
            shake()
        case .pulse:
            pulse = 0
            withAnimation(.easeOut(duration: 0.6)) { pulse = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { pulse = 0 }
        }
    }

    private func shake() {
        guard !context.reducesMotion else { return }
        let steps: [(Double, CGFloat)] = [(0, 12), (0.08, -10), (0.16, 6), (0.24, -3), (0.32, 0)]
        for (delay, angle) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { withAnimation(.easeInOut(duration: 0.08)) { wiggle = angle } }
        }
    }
}
