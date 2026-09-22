//
//  KitoCodeField.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// One-time-code entry rendered as individual boxes, backed by a single hidden text field so
/// paste and SMS autofill work.
///
/// ```swift
/// KitoCodeField(code: $code, length: 6)
///     .onComplete { code in verify(code) }
/// ```
public struct KitoCodeField: View {
    @Binding private var code: String
    private let length: Int
    private var isSecure = false
    private var boxSize = CGSize(width: 46, height: 54)
    private var spacing: CGFloat = 10
    private var allowsLetters = false
    private var showsCaret = true
    private var digitFont: Font?
    var filledFill: Color?
    var filledBorderColor: Color?
    var filledBorderWidth: CGFloat?
    var filledShadow: KitoShadow?
    private var errorMessage: String?
    private var clearsOnErrorAfter: TimeInterval?
    private var onComplete: ((String) -> Void)?
    private var focusBinding: Binding<Bool>?

    @FocusState private var isFocused: Bool
    @Environment(\.kitoFieldTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(code: Binding<String>, length: Int = 6) {
        _code = code
        self.length = max(1, length)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.helperSpacing) {
            ZStack {
                HStack(spacing: spacing) {
                    ForEach(0..<length, id: \.self) { index in
                        box(at: index)
                    }
                }
                hiddenField
            }
            .contentShape(Rectangle())
            .modifier(FocusOnTap { isFocused = true })
            .kitoFieldShake(trigger: reduceMotion ? nil : errorMessage, animation: theme.motion.shake)
            if let errorMessage {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if let icon = theme.errorIcon {
                        Image(systemName: icon).font(theme.errorIconFont ?? theme.errorFont ?? theme.helperFont)
                    }
                    Text(errorMessage).font(theme.errorFont ?? theme.helperFont)
                }
                .foregroundColor(theme.errorColor)
            }
        }
        .opacity(isEnabled ? 1 : theme.disabledOpacity)
        .animation(reduceMotion ? .easeOut(duration: 0.1) : theme.animation, value: code)
        .animation(reduceMotion ? .easeOut(duration: 0.1) : theme.animation, value: isFocused)
        .onChange(of: code) { sanitize($0) }
        .onChange(of: errorMessage) { newValue in
            guard newValue != nil, let delay = clearsOnErrorAfter else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { code = "" }
        }
        .onChange(of: isFocused) { focused in
            if let focusBinding, focusBinding.wrappedValue != focused { focusBinding.wrappedValue = focused }
        }
        .onChange(of: focusBinding?.wrappedValue) { requested in
            if let requested, requested != isFocused { isFocused = requested }
        }
        .onAppear { if focusBinding?.wrappedValue == true { isFocused = true } }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(KitoLocalization.string("code.accessibilityLabel", "Verification code"))
        .accessibilityValue(code.map(String.init).joined(separator: " "))
    }

    private var hiddenField: some View {
        TextField("", text: $code)
            .focused($isFocused)
            .kitoKeyboard(allowsLetters ? .asciiCapable : .numberPad)
            .kitoContentType(.oneTimeCode)
            .kitoAutocapitalization(.characters)
            .disableAutocorrection(true)
            .foregroundColor(.clear)
            .accentColor(.clear)
            .frame(maxWidth: .infinity)
            .frame(height: boxSize.height)
            .opacity(0.02)
            .accessibilityHidden(true)
    }

    private func box(at index: Int) -> some View {
        let characters = Array(code)
        let hasValue = index < characters.count
        let isActive = isFocused && (index == characters.count || (characters.count == length && index == length - 1))
        let hasError = errorMessage != nil
        let baseFill = theme.backgroundColor == .clear ? theme.filledBackgroundColor : theme.backgroundColor
        let appearance = Self.boxAppearance(
            hasError: hasError,
            hasValue: hasValue,
            isActive: isActive,
            baseFill: baseFill,
            filledFill: filledFill,
            filledBorderColor: filledBorderColor,
            filledBorderWidth: filledBorderWidth,
            filledShadow: filledShadow,
            theme: theme
        )

        return ZStack {
            if hasValue {
                Text(isSecure ? "●" : String(characters[index]))
                    .font(digitFont ?? theme.font.weight(.semibold))
                    .foregroundColor(theme.textColor)
                    .transition(.scale.combined(with: .opacity))
            } else if isActive && showsCaret {
                Rectangle()
                    .fill(theme.focusedBorderColor)
                    .frame(width: 2, height: boxSize.height * 0.45)
                    .modifier(Blink())
            }
        }
        .frame(width: boxSize.width, height: boxSize.height)
        .modifier(KitoFieldChrome(
            shape: theme.shape,
            fill: appearance.fill,
            borderColor: appearance.borderColor,
            borderWidth: theme.showsBorder ? appearance.borderWidth : 0,
            shadow: appearance.shadow
        ))
    }

    static func boxAppearance(
        hasError: Bool,
        hasValue: Bool,
        isActive: Bool,
        baseFill: Color,
        filledFill: Color?,
        filledBorderColor: Color?,
        filledBorderWidth: CGFloat?,
        filledShadow: KitoShadow?,
        theme: KitoFieldTheme
    ) -> (fill: Color, borderColor: Color, borderWidth: CGFloat, shadow: KitoShadow?) {
        if hasError {
            return (baseFill, theme.errorColor, theme.focusedBorderWidth, theme.shadow)
        }
        if hasValue, filledFill != nil || filledBorderColor != nil || filledBorderWidth != nil || filledShadow != nil {
            return (
                filledFill ?? baseFill,
                filledBorderColor ?? (isActive ? theme.focusedBorderColor : theme.borderColor),
                filledBorderWidth ?? (isActive ? theme.focusedBorderWidth : theme.borderWidth),
                filledShadow ?? theme.shadow
            )
        }
        if isActive {
            return (baseFill, theme.focusedBorderColor, theme.focusedBorderWidth, theme.shadow)
        }
        return (baseFill, theme.borderColor, theme.borderWidth, theme.shadow)
    }

    private func sanitize(_ value: String) {
        var cleaned = value.filter { allowsLetters ? ($0.isLetter || $0.isNumber) : ($0.isASCII && $0.isNumber) }
        if allowsLetters { cleaned = cleaned.uppercased() }
        if cleaned.count > length { cleaned = String(cleaned.prefix(length)) }
        if cleaned != value {
            code = cleaned
            return
        }
        if cleaned.count == length {
            onComplete?(cleaned)
        }
    }

    // MARK: Configuration

    private func mutating(_ change: (inout KitoCodeField) -> Void) -> KitoCodeField {
        var copy = self
        change(&copy)
        return copy
    }

    /// Masks digits with dots.
    public func secure(_ enabled: Bool = true) -> KitoCodeField { mutating { $0.isSecure = enabled } }
    public func boxSize(_ size: CGSize) -> KitoCodeField { mutating { $0.boxSize = size } }
    public func spacing(_ value: CGFloat) -> KitoCodeField { mutating { $0.spacing = value } }
    /// Hide the blinking caret in the active box; the box then shows focus through its border only.
    public func showsCaret(_ enabled: Bool) -> KitoCodeField { mutating { $0.showsCaret = enabled } }
    /// Font for the entered digits; defaults to the theme font at semibold.
    public func digitFont(_ font: Font) -> KitoCodeField { mutating { $0.digitFont = font } }
    /// Styling for a box that already holds a character. Anything left nil falls back to the theme.
    public func filledBox(fill: Color? = nil, borderColor: Color? = nil, borderWidth: CGFloat? = nil, shadow: KitoShadow? = nil) -> KitoCodeField {
        mutating {
            $0.filledFill = fill
            $0.filledBorderColor = borderColor
            $0.filledBorderWidth = borderWidth
            $0.filledShadow = shadow
        }
    }
    /// Accepts letters as well as digits (uppercased).
    public func alphanumeric(_ enabled: Bool = true) -> KitoCodeField { mutating { $0.allowsLetters = enabled } }
    /// Error shown under the boxes (e.g. "Incorrect code").
    public func errorMessage(_ message: String?) -> KitoCodeField { mutating { $0.errorMessage = message } }
    /// Clears the entered code automatically `delay` seconds after `errorMessage` is set, once the
    /// shake has played. Without this, clearing the wrong code back out is on you (as in earlier
    /// versions of this field).
    public func clearsOnError(after delay: TimeInterval = 0.6) -> KitoCodeField { mutating { $0.clearsOnErrorAfter = delay } }
    public func onComplete(_ handler: @escaping (String) -> Void) -> KitoCodeField { mutating { $0.onComplete = handler } }
    public func focused(_ binding: Binding<Bool>) -> KitoCodeField { mutating { $0.focusBinding = binding } }

    private struct Blink: ViewModifier {
        @State private var visible = true
        func body(content: Content) -> some View {
            content
                .opacity(visible ? 1 : 0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { visible = false }
                }
        }
    }
}


/// `onTapGesture` does not exist on tvOS; focus comes from the remote there.
private struct FocusOnTap: ViewModifier {
    let action: () -> Void
    func body(content: Content) -> some View {
        #if os(tvOS)
        content
        #else
        content.onTapGesture(perform: action)
        #endif
    }
}
