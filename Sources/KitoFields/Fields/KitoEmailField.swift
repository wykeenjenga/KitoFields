//
//  KitoEmailField.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// Email preset: email keyboard and autofill, no autocapitalization or autocorrection,
/// whitespace stripped as you type, `.email` rule applied on blur.
///
/// ```swift
/// KitoEmailField(text: $email)
///     .required()
///     .leadingIcon("envelope")
/// ```
public struct KitoEmailField: View, KitoFieldConfigurable {
    private var base: KitoTextField
    private var suggestionDomains: [String]? = nil
    @Binding private var text: String

    public var options: KitoFieldOptions {
        get { base.options }
        set { base.options = newValue }
    }

    public init(_ label: String? = "Email", text: Binding<String>, prompt: String? = "name@example.com") {
        _text = text
        base = KitoTextField(label, text: text, prompt: prompt)
        base.options.keyboard = .emailAddress
        base.options.contentType = .emailAddress
        base.options.autocapitalization = .never
        base.options.disablesAutocorrection = true
        base.options.rules = [.email]
        base.options.validationTrigger = .onBlur
        base.options.transform = { $0.filter { !$0.isWhitespace } }
    }

    public var body: some View {
        guard let domains = suggestionDomains, let suggestion = Self.suggestion(for: text, domains: domains) else { return AnyView(base) }
        var field = base
        field.options.helperText = KitoLocalization.format("email.suggestion", "Did you mean %@?", suggestion)
        field.options.trailing = .button(systemImage: "wand.and.stars", accessibilityLabel: KitoLocalization.format("email.suggestion", "Did you mean %@?", suggestion)) {
            text = suggestion
        }
        return AnyView(field)
    }

    /// Common providers used for typo suggestions.
    public static let commonDomains = ["gmail.com", "yahoo.com", "outlook.com", "hotmail.com", "icloud.com", "live.com", "protonmail.com", "me.com", "aol.com", "yahoo.co.uk", "googlemail.com"]

    /// Suggests "name@gmail.com" for "name@gmial.com" when the typed domain is one or two edits from a known one.
    public static func suggestion(for email: String, domains: [String] = commonDomains) -> String? {
        guard let at = email.lastIndex(of: "@") else { return nil }
        let local = String(email[..<at]); let domain = String(email[email.index(after: at)...]).lowercased()
        guard !local.isEmpty, domain.contains("."), !domains.contains(domain) else { return nil }
        let best = domains.map { ($0, Self.distance(domain, $0)) }.min { $0.1 < $1.1 }
        guard let (match, d) = best, d > 0, d <= 2 else { return nil }
        return "\(local)@\(match)"
    }

    static func distance(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        var prev = Array(0...b.count)
        for i in 1...max(a.count, 1) where i <= a.count {
            var cur = [i] + Array(repeating: 0, count: b.count)
            for j in 1...max(b.count, 1) where j <= b.count {
                cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1))
            }
            prev = cur
        }
        return prev[b.count]
    }

    /// Suggest a fix when the domain looks like a typo of a common provider ("gmial.com" → "gmail.com").
    public func suggestsDomainCorrections(_ domains: [String] = KitoEmailField.commonDomains) -> KitoEmailField {
        var c = self; c.suggestionDomains = domains; return c
    }

    /// Lowercases input as it is typed.
    public func lowercased(_ enabled: Bool = true) -> KitoEmailField {
        var copy = self
        copy.base.options.transform = enabled
            ? { $0.filter { !$0.isWhitespace }.lowercased() }
            : { $0.filter { !$0.isWhitespace } }
        return copy
    }
}
