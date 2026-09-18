//
//  KitoResendCodeButton.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 18/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// A "Resend code" link that disables itself and counts down after each tap, so you don't have to
/// hand-roll a cooldown timer next to `KitoCodeField`.
///
/// ```swift
/// KitoCodeField(code: $code, length: 6)
///     .onComplete { verify($0) }
///
/// KitoResendCodeButton(cooldown: 30) {
///     resend()
/// }
/// ```
public struct KitoResendCodeButton: View {
    private let cooldown: TimeInterval
    private let action: () -> Void
    private var font: Font?
    private var tint: Color?
    private var disabledTint: Color?

    @State private var remaining: Int
    @State private var countdownTask: Task<Void, Never>?

    @Environment(\.kitoFieldTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - cooldown: Seconds the button stays disabled after each tap.
    ///   - startsDisabled: Pass `true` if a code was already sent when this view first appears
    ///     (e.g. navigating onto an OTP screen), so the user can't immediately request another.
    ///   - action: Called once per tap, only while enabled.
    public init(cooldown: TimeInterval = 30, startsDisabled: Bool = false, action: @escaping () -> Void) {
        self.cooldown = cooldown
        self.action = action
        _remaining = State(initialValue: Self.seedRemaining(cooldown: cooldown, startsDisabled: startsDisabled))
    }

    /// Whole seconds to start counting down from; fractional cooldowns round up so the button
    /// never re-enables a moment before the promised cooldown has actually elapsed.
    static func seedRemaining(cooldown: TimeInterval, startsDisabled: Bool) -> Int {
        startsDisabled ? Int(cooldown.rounded(.up)) : 0
    }

    public var body: some View {
        Button(action: resend) {
            Text(title)
                .font(font ?? theme.helperFont)
                .foregroundColor(remaining > 0 ? (disabledTint ?? theme.helperColor) : (tint ?? theme.tintColor ?? theme.focusedBorderColor))
                .underline(remaining == 0)
        }
        .buttonStyle(.plain)
        .disabled(remaining > 0 || !isEnabled)
        .animation(reduceMotion ? nil : theme.animation, value: remaining)
        .onAppear { if remaining > 0 { startCountdown() } }
        .onDisappear { countdownTask?.cancel() }
        .accessibilityLabel(title)
    }

    private var title: String {
        remaining > 0
            ? KitoLocalization.format("code.resendIn", "Resend in %ds", remaining)
            : KitoLocalization.string("code.resend", "Resend code")
    }

    private func resend() {
        guard remaining == 0 else { return }
        action()
        remaining = Self.seedRemaining(cooldown: cooldown, startsDisabled: true)
        startCountdown()
    }

    private func startCountdown() {
        countdownTask?.cancel()
        countdownTask = Task { @MainActor in
            while remaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                remaining -= 1
            }
        }
    }

    // MARK: Configuration

    private func mutating(_ change: (inout KitoResendCodeButton) -> Void) -> KitoResendCodeButton {
        var copy = self
        change(&copy)
        return copy
    }

    public func font(_ font: Font) -> KitoResendCodeButton { mutating { $0.font = font } }
    /// Colour while enabled; defaults to the theme's tint (or focused border colour).
    public func tint(_ color: Color) -> KitoResendCodeButton { mutating { $0.tint = color } }
    /// Colour while counting down; defaults to the theme's helper colour.
    public func disabledTint(_ color: Color) -> KitoResendCodeButton { mutating { $0.disabledTint = color } }
}
