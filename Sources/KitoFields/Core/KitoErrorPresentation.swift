//
//  KitoErrorPresentation.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// Where validation errors are shown.
public enum KitoErrorPresentation: Hashable, Sendable {
    /// Text under the field (default).
    case inline
    /// A floating bubble anchored above the field, visible whenever there is an error.
    case floating
    /// A floating bubble shown only while the field is focused; the border still turns red.
    case floatingWhenFocused
    /// Only the border and indicator change; no message text.
    case none
}

/// The bubble used by the floating presentations. Reuse it for your own tooltips.
public struct KitoErrorBubble: View {
    public var messages: [String]
    public var theme: KitoFieldTheme

    public init(messages: [String], theme: KitoFieldTheme) {
        self.messages = messages
        self.theme = theme
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(messages.enumerated()), id: \.offset) { _, message in
                Label { Text(message) } icon: { Image(systemName: "exclamationmark.circle.fill") }
                    .font(theme.helperFont.weight(.medium))
            }
        }
        .foregroundColor(theme.errorBubbleForeground)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(theme.errorBubbleBackground ?? theme.errorColor)
        )
        .overlay(alignment: .bottomLeading) {
            Triangle()
                .fill(theme.errorBubbleBackground ?? theme.errorColor)
                .frame(width: 14, height: 7)
                .offset(x: 18, y: 7)
        }
        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }

    private struct Triangle: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.closeSubpath()
            return p
        }
    }
}

/// Attaches the floating error bubble above a field row when the configuration asks for it.
struct KitoFloatingErrorModifier: ViewModifier {
    let configuration: KitoFieldStyleConfiguration
    @State private var bubbleHeight: CGFloat = 0

    private var shouldShow: Bool {
        guard !configuration.displayedErrors.isEmpty else { return false }
        switch configuration.errorPresentation {
        case .floating: return true
        case .floatingWhenFocused: return configuration.isFocused
        case .inline, .none: return false
        }
    }

    func body(content: Content) -> some View {
        content.overlay(alignment: .topLeading) {
            if shouldShow {
                KitoErrorBubble(messages: configuration.displayedErrors, theme: configuration.theme)
                    .background(GeometryReader { proxy in
                        Color.clear.preference(key: BubbleHeightKey.self, value: proxy.size.height)
                    })
                    .onPreferenceChange(BubbleHeightKey.self) { bubbleHeight = $0 }
                    // Sit fully above the row: move up by the bubble's own height plus the arrow gap.
                    .offset(y: -(bubbleHeight + 10))
                    .opacity(bubbleHeight == 0 ? 0 : 1)
                    .transition(.asymmetric(insertion: .scale(scale: 0.9, anchor: .bottomLeading).combined(with: .opacity), removal: .opacity))
                    .zIndex(1)
                    .allowsHitTesting(false)
            }
        }
        .animation(configuration.motion.error, value: shouldShow)
        .animation(configuration.motion.error, value: configuration.displayedErrors)
    }

    private struct BubbleHeightKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
    }
}
