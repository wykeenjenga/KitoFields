//
//  KitoRule.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import Foundation

/// A single validation rule: a predicate plus the message shown when it fails.
public struct KitoRule: Identifiable {
    public let id: String
    public let message: String
    /// When true (the default for everything except `.required`), the rule passes on empty input
    /// so optional fields do not complain until something is typed.
    public let skipsWhenEmpty: Bool
    private let predicate: (String) -> Bool

    public init(id: String, message: String, skipsWhenEmpty: Bool = true, predicate: @escaping (String) -> Bool) {
        self.id = id
        self.message = message
        self.skipsWhenEmpty = skipsWhenEmpty
        self.predicate = predicate
    }

    public func validate(_ value: String) -> Bool {
        if skipsWhenEmpty && value.isEmpty { return true }
        return predicate(value)
    }

    static let requiredID = "inputkit.required"

    // MARK: Presets

    public static func required(message: String = "This field is required") -> KitoRule {
        KitoRule(id: requiredID, message: message, skipsWhenEmpty: false) {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    public static var required: KitoRule { required() }

    public static func minLength(_ length: Int, message: String? = nil) -> KitoRule {
        KitoRule(id: "inputkit.minLength.\(length)", message: message ?? "Must be at least \(length) characters") {
            $0.count >= length
        }
    }

    public static func maxLength(_ length: Int, message: String? = nil) -> KitoRule {
        KitoRule(id: "inputkit.maxLength.\(length)", message: message ?? "Must be at most \(length) characters") {
            $0.count <= length
        }
    }

    public static func exactLength(_ length: Int, message: String? = nil) -> KitoRule {
        KitoRule(id: "inputkit.exactLength.\(length)", message: message ?? "Must be exactly \(length) characters") {
            $0.count == length
        }
    }

    public static func email(message: String = "Enter a valid email address") -> KitoRule {
        KitoRule(id: "inputkit.email", message: message) { KitoEmailValidator.isValid($0) }
    }
    public static var email: KitoRule { email() }

    public static func url(message: String = "Enter a valid URL") -> KitoRule {
        KitoRule(id: "inputkit.url", message: message) { value in
            guard let url = URL(string: value), let scheme = url.scheme, let host = url.host else { return false }
            return ["http", "https"].contains(scheme.lowercased()) && host.contains(".")
        }
    }

    public static func numeric(message: String = "Digits only") -> KitoRule {
        KitoRule(id: "inputkit.numeric", message: message) { $0.allSatisfy { $0.isASCII && $0.isNumber } }
    }

    public static func decimal(message: String = "Enter a valid number") -> KitoRule {
        KitoRule(id: "inputkit.decimal", message: message) { Double($0.replacingOccurrences(of: ",", with: ".")) != nil }
    }

    public static func alphanumeric(message: String = "Letters and digits only") -> KitoRule {
        KitoRule(id: "inputkit.alphanumeric", message: message) { $0.allSatisfy { $0.isLetter || $0.isNumber } }
    }

    public static func containsUppercase(message: String = "At least one uppercase letter") -> KitoRule {
        KitoRule(id: "inputkit.uppercase", message: message) { $0.contains { $0.isUppercase } }
    }

    public static func containsLowercase(message: String = "At least one lowercase letter") -> KitoRule {
        KitoRule(id: "inputkit.lowercase", message: message) { $0.contains { $0.isLowercase } }
    }

    public static func containsDigit(message: String = "At least one number") -> KitoRule {
        KitoRule(id: "inputkit.digit", message: message) { $0.contains { $0.isNumber } }
    }

    public static func containsSymbol(message: String = "At least one symbol") -> KitoRule {
        KitoRule(id: "inputkit.symbol", message: message) { $0.contains { !$0.isLetter && !$0.isNumber && !$0.isWhitespace } }
    }

    public static func noWhitespace(message: String = "Spaces are not allowed") -> KitoRule {
        KitoRule(id: "inputkit.noWhitespace", message: message) { !$0.contains { $0.isWhitespace } }
    }

    public static func regex(_ pattern: String, message: String) -> KitoRule {
        KitoRule(id: "inputkit.regex.\(pattern)", message: message) { value in
            value.range(of: pattern, options: .regularExpression) != nil
        }
    }

    /// Passes when the value equals the value produced by `other()` at validation time
    /// (e.g. confirm-password).
    public static func matches(_ other: @escaping () -> String, message: String = "Values do not match") -> KitoRule {
        KitoRule(id: "inputkit.matches", message: message) { $0 == other() }
    }

    public static func custom(id: String = UUID().uuidString, message: String, skipsWhenEmpty: Bool = true, _ predicate: @escaping (String) -> Bool) -> KitoRule {
        KitoRule(id: id, message: message, skipsWhenEmpty: skipsWhenEmpty, predicate: predicate)
    }

    /// A sensible strong-password bundle.
    public static func strongPassword(minLength: Int = 8) -> [KitoRule] {
        [.minLength(minLength), .containsUppercase(), .containsLowercase(), .containsDigit(), .containsSymbol()]
    }
}

public enum KitoValidator {
    /// Runs every rule and collects failure messages in rule order.
    public static func validate(_ value: String, rules: [KitoRule]) -> KitoValidationState {
        guard !rules.isEmpty else { return .idle }
        let failures = rules.filter { !$0.validate(value) }.map(\.message)
        return failures.isEmpty ? .valid : .invalid(failures)
    }
}

public enum KitoEmailValidator {
    // Practical RFC 5322 subset: local part, single @, dotted domain with a 2+ letter TLD.
    private static let pattern = #"^[A-Z0-9a-z._%+\-']+@[A-Za-z0-9](?:[A-Za-z0-9\-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9\-]{0,61}[A-Za-z0-9])?)*\.[A-Za-z]{2,}$"#

    public static func isValid(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count <= 254, !trimmed.contains(".."),
              let at = trimmed.firstIndex(of: "@"),
              trimmed.distance(from: trimmed.startIndex, to: at) <= 64 else { return false }
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }
}
