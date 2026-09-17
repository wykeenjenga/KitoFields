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
    public enum ArrowEdge: Sendable { case bottom, top }

    public var messages: [String]
    public var theme: KitoFieldTheme
    /// `.bottom` when the bubble floats above the field (arrow points down), `.top` when below.
    public var arrowEdge: ArrowEdge = .bottom

    public init(messages: [String], theme: KitoFieldTheme, arrowEdge: ArrowEdge = .bottom) {
        self.messages = messages
        self.theme = theme
        self.arrowEdge = arrowEdge
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(messages.enumerated()), id: \.offset) { _, message in
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if let icon = theme.errorIcon {
                        Image(systemName: icon).font(theme.errorIconFont ?? theme.errorFont ?? theme.helperFont)
                    }
                    Text(message).font((theme.errorFont ?? theme.helperFont).weight(.medium))
                }
            }
        }
        .foregroundColor(theme.errorBubbleForeground)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(theme.errorBubbleBackground ?? theme.errorColor)
        )
        .overlay(alignment: arrowEdge == .bottom ? .bottomLeading : .topLeading) {
            Triangle()
                .fill(theme.errorBubbleBackground ?? theme.errorColor)
                .frame(width: 14, height: 7)
                .rotationEffect(.degrees(arrowEdge == .bottom ? 0 : 180))
                .offset(x: 18, y: arrowEdge == .bottom ? 7 : -7)
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

/// Attaches the floating error bubble to a field row when the configuration asks for it. The bubble
/// floats above the row and never covers the input; when the row is too close to the top of the
/// screen it flips below the row instead.
struct KitoFloatingErrorModifier: ViewModifier {
    let configuration: KitoFieldStyleConfiguration
    @State private var bubbleHeight: CGFloat = 0
    @State private var rowFrame: CGRect = .zero

    /// Space needed above the row (bubble + arrow + a margin for the status bar / navigation bar).
    private let minimumTopSpace: CGFloat = 96

    private var shouldShow: Bool {
        guard !configuration.displayedErrors.isEmpty else { return false }
        switch configuration.errorPresentation {
        case .floating: return true
        case .floatingWhenFocused: return configuration.isFocused
        case .inline, .none: return false
        }
    }

    private var placesBelow: Bool {
        rowFrame != .zero && rowFrame.minY - bubbleHeight - 10 < minimumTopSpace
    }

    func body(content: Content) -> some View {
        content
            .background(GeometryReader { proxy in
                Color.clear.preference(key: RowFrameKey.self, value: proxy.frame(in: .global))
            })
            .onPreferenceChange(RowFrameKey.self) { rowFrame = $0 }
            .overlay(alignment: placesBelow ? .bottomLeading : .topLeading) {
                if shouldShow {
                    KitoErrorBubble(messages: configuration.displayedErrors, theme: configuration.theme, arrowEdge: placesBelow ? .top : .bottom)
                        .background(GeometryReader { proxy in
                            Color.clear.preference(key: BubbleHeightKey.self, value: proxy.size.height)
                        })
                        .onPreferenceChange(BubbleHeightKey.self) { bubbleHeight = $0 }
                        // Fully outside the row: above (default) or below when space is short.
                        .offset(y: placesBelow ? (bubbleHeight + 10) : -(bubbleHeight + 10))
                        .opacity(bubbleHeight == 0 ? 0 : 1)
                        .transition(.asymmetric(insertion: .scale(scale: 0.9, anchor: placesBelow ? .topLeading : .bottomLeading).combined(with: .opacity), removal: .opacity))
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

    private struct RowFrameKey: PreferenceKey {
        static var defaultValue: CGRect = .zero
        static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
    }
}
