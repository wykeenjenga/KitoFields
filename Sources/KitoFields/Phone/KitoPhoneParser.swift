//
//  KitoPhoneParser.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import Foundation

/// Turns free-form input into a `KitoPhoneNumber`.
public struct KitoPhoneParser: Sendable {
    public init() {}

    /// International input (leading "+" or "00") resolves its own region; anything else is treated
    /// as a national number in `defaultCountry` (device region when nil).
    public func parse(_ input: String, defaultCountry: KitoCountry? = nil) -> KitoPhoneNumber? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let international = internationalDigits(from: trimmed) {
            guard let (country, national) = KitoCountryDatabase.match(internationalDigits: international) else { return nil }
            return KitoPhoneNumber(country: country, nationalNumber: national)
        }

        let country = defaultCountry ?? KitoCountryDatabase.current
        let digits = trimmed.asciiDigits
        guard !digits.isEmpty else { return nil }
        return KitoPhoneNumber(country: country, nationalNumber: digits)
    }

    /// Digits following a "+" or "00" international prefix, or nil when the input is national.
    public func internationalDigits(from input: String) -> String? {
        let compact = input.filter { !$0.isWhitespace && $0 != "-" && $0 != "(" && $0 != ")" && $0 != "." }
        if compact.hasPrefix("+") {
            return String(compact.dropFirst()).asciiDigits
        }
        if compact.hasPrefix("00"), compact.count > 4 {
            return String(compact.dropFirst(2)).asciiDigits
        }
        return nil
    }
}
