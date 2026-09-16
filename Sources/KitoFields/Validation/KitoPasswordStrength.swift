//
//  KitoPasswordStrength.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// Coarse password strength buckets.
public enum KitoPasswordStrength: Int, CaseIterable, Comparable, Sendable {
    case veryWeak = 0, weak, fair, strong, veryStrong

    public static func < (lhs: KitoPasswordStrength, rhs: KitoPasswordStrength) -> Bool { lhs.rawValue < rhs.rawValue }

    public var label: String {
        switch self {
        case .veryWeak: return L10n.s("strength.veryWeak", "Very weak")
        case .weak: return L10n.s("strength.weak", "Weak")
        case .fair: return L10n.s("strength.fair", "Fair")
        case .strong: return L10n.s("strength.strong", "Strong")
        case .veryStrong: return L10n.s("strength.veryStrong", "Very strong")
        }
    }

    public var color: Color {
        switch self {
        case .veryWeak: return .red
        case .weak: return .orange
        case .fair: return .yellow
        case .strong: return .green
        case .veryStrong: return Color(red: 0.0, green: 0.55, blue: 0.3)
        }
    }

    /// Number of filled segments out of four.
    public var segments: Int { rawValue }
}

/// Heuristic strength scorer: length, character classes, and penalties for repetition,
/// sequences and common passwords.
public struct KitoPasswordStrengthEvaluator: Sendable {
    public var commonPasswords: Set<String> = [
        "password", "123456", "12345678", "qwerty", "abc123", "111111", "123123", "letmein",
        "welcome", "admin", "iloveyou", "monkey", "dragon", "football", "baseball", "passw0rd",
        "password1", "qwerty123", "1q2w3e4r", "sunshine", "princess", "master", "shadow"
    ]

    public init() {}

    public func evaluate(_ password: String) -> KitoPasswordStrength {
        if password.isEmpty { return .veryWeak }
        let lower = password.lowercased()
        if commonPasswords.contains(lower) { return .veryWeak }

        var score = 0.0
        let length = password.count
        score += min(Double(length) * 0.5, 6)                           // up to 6 for length 12+

        var classes = 0
        if password.contains(where: { $0.isLowercase }) { classes += 1 }
        if password.contains(where: { $0.isUppercase }) { classes += 1 }
        if password.contains(where: { $0.isNumber }) { classes += 1 }
        if password.contains(where: { !$0.isLetter && !$0.isNumber }) { classes += 1 }
        score += Double(classes - 1) * 1.5                              // up to 4.5

        // Penalties
        let unique = Set(password).count
        if unique <= max(2, length / 3) { score -= 3 }                  // heavy repetition
        if isSequential(lower) { score -= 3 }                           // abcdef / 123456
        if length < 8 { score -= 2 }

        switch score {
        case ..<2: return .veryWeak
        case 2..<4.5: return .weak
        case 4.5..<7: return .fair
        case 7..<9: return .strong
        default: return .veryStrong
        }
    }

    private func isSequential(_ s: String) -> Bool {
        let scalars = s.unicodeScalars.map { Int($0.value) }
        guard scalars.count >= 4 else { return false }
        var ascending = 0, descending = 0
        for i in 1..<scalars.count {
            let d = scalars[i] - scalars[i - 1]
            if d == 1 { ascending += 1 } else { ascending = 0 }
            if d == -1 { descending += 1 } else { descending = 0 }
            if ascending >= 3 || descending >= 3 { return true }
        }
        return false
    }
}

/// Four-segment strength bar with a label.
public struct KitoStrengthMeter: View {
    public var strength: KitoPasswordStrength
    public var showsLabel = true
    @Environment(\.kitoFieldTheme) private var theme

    public init(strength: KitoPasswordStrength, showsLabel: Bool = true) {
        self.strength = strength
        self.showsLabel = showsLabel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                ForEach(1...4, id: \.self) { index in
                    Capsule()
                        .fill(index <= strength.segments ? strength.color : theme.borderColor.opacity(0.6))
                        .frame(height: 4)
                }
            }
            if showsLabel {
                Text(strength.label)
                    .font(theme.helperFont)
                    .foregroundColor(strength.segments == 0 ? theme.helperColor : strength.color)
            }
        }
        .animation(theme.animation, value: strength)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.f("strength.accessibility", "Password strength: %@", strength.label))
    }
}

/// Live checklist of rules, ticking each as the value satisfies it.
public struct KitoRequirementChecklist: View {
    public var rules: [KitoRule]
    public var value: String
    @Environment(\.kitoFieldTheme) private var theme

    public init(rules: [KitoRule], value: String) {
        self.rules = rules
        self.value = value
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(rules) { rule in
                let met = !value.isEmpty && rule.validate(value)
                Label {
                    Text(rule.message)
                } icon: {
                    Image(systemName: met ? "checkmark.circle.fill" : "circle")
                }
                .font(theme.helperFont)
                .foregroundColor(met ? theme.successColor : theme.helperColor)
            }
        }
        .animation(theme.animation, value: value)
    }
}
