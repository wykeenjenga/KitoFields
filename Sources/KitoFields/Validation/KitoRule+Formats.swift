//
//  KitoRule+Formats.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import Foundation

public extension KitoRule {
    /// Luhn checksum for card numbers (ignores spaces).
    static func luhn(message: String = KitoLocalization.string("card.invalid", "Enter a valid card number")) -> KitoRule {
        KitoRule(id: "inputkit.luhn", message: message) { KitoCardBrand.passesLuhn($0) }
    }

    /// A real calendar date in the given format, e.g. "dd/MM/yyyy".
    static func date(format: String, message: String = KitoLocalization.string("date.invalid", "Enter a valid date")) -> KitoRule {
        KitoRule(id: "inputkit.date.\(format)", message: message) { KitoDateField.parse($0, format: format) != nil }
    }

    /// MM/YY card expiry that is not in the past.
    static func cardExpiry(message: String = KitoLocalization.string("card.expiry.invalid", "Enter a valid expiry date"), expiredMessage: String = KitoLocalization.string("card.expired", "This card has expired")) -> [KitoRule] {
        [
            KitoRule(id: "inputkit.expiry.format", message: message) { KitoCardExpiryField.components($0) != nil },
            KitoRule(id: "inputkit.expiry.future", message: expiredMessage) { value in
                guard let (month, year) = KitoCardExpiryField.components(value) else { return true }
                return !KitoCardExpiryField.isExpired(month: month, year: year)
            },
        ]
    }

    /// Numeric value within a range, parsed with the given locale.
    static func range(_ range: ClosedRange<Double>, locale: Locale = .autoupdatingCurrent, minMessage: String? = nil, maxMessage: String? = nil) -> [KitoRule] {
        let formatter = NumberFormatter(); formatter.locale = locale; formatter.numberStyle = .decimal
        func parse(_ s: String) -> Double? { formatter.number(from: s)?.doubleValue ?? Double(s.replacingOccurrences(of: ",", with: ".")) }
        func format(_ d: Double) -> String { formatter.string(from: d as NSNumber) ?? "\(d)" }
        return [
            KitoRule(id: "inputkit.range.min", message: minMessage ?? KitoLocalization.format("number.min", "Must be at least %@", format(range.lowerBound))) { parse($0).map { $0 >= range.lowerBound } ?? true },
            KitoRule(id: "inputkit.range.max", message: maxMessage ?? KitoLocalization.format("number.max", "Must be at most %@", format(range.upperBound))) { parse($0).map { $0 <= range.upperBound } ?? true },
        ]
    }

    /// Letters, spaces, hyphens and apostrophes only (names).
    static func personName(message: String = KitoLocalization.string("name.invalid", "Enter a valid name")) -> KitoRule {
        KitoRule(id: "inputkit.personName", message: message) { value in
            value.allSatisfy { $0.isLetter || $0 == " " || $0 == "-" || $0 == "'" || $0 == "’" || $0 == "." } && value.contains { $0.isLetter }
        }
    }

    /// 3–20 letters, digits or underscores.
    static func username(message: String = KitoLocalization.string("username.invalid", "Use 3–20 letters, numbers or underscores")) -> KitoRule {
        KitoRule(id: "inputkit.username", message: message) { $0.range(of: "^[A-Za-z0-9_]{3,20}$", options: .regularExpression) != nil }
    }
}
