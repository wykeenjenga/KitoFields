//
//  KitoPhoneValidator.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import Foundation

public enum KitoPhoneError: Error, Equatable, Sendable {
    case tooShort
    case tooLong
    case invalidLeadingDigits
    case custom(String)

    public var message: String {
        switch self {
        case .tooShort: return "Phone number is too short"
        case .tooLong: return "Phone number is too long"
        case .invalidLeadingDigits: return "Phone number is not valid for this country"
        case .custom(let text): return text
        }
    }
}

public enum KitoPhoneState: Equatable, Sendable {
    case empty
    /// Fewer digits than the region's minimum; not yet an error while typing.
    case incomplete
    case valid
    case invalid(KitoPhoneError)

    public var isValid: Bool { self == .valid }
}

/// Length- and prefix-based validation using the built-in metadata, plus an optional custom rule.
public struct KitoPhoneValidator: Sendable {
    /// Return an error to reject numbers that pass the built-in checks (e.g. mobile-only).
    public var customRule: (@Sendable (KitoPhoneNumber) -> KitoPhoneError?)?

    public init(customRule: (@Sendable (KitoPhoneNumber) -> KitoPhoneError?)? = nil) {
        self.customRule = customRule
    }

    public func validate(nationalNumber: String, country: KitoCountry) -> KitoPhoneState {
        let digits = nationalNumber.asciiDigits
        if digits.isEmpty { return .empty }
        if digits.count < country.minNationalNumberLength { return .incomplete }
        if digits.count > country.maxNationalNumberLength { return .invalid(.tooLong) }

        // NANP: area code and exchange must start with 2–9.
        if country.dialCode == "1" {
            let chars = Array(digits)
            if chars.count == 10, ("01".contains(chars[0]) || "01".contains(chars[3])) {
                return .invalid(.invalidLeadingDigits)
            }
        }

        // Regions identified by leading digits must actually start with one of them.
        if !country.isMainCountryForDialCode, !country.leadingDigits.isEmpty,
           !country.leadingDigits.contains(where: { digits.hasPrefix($0) }) {
            return .invalid(.invalidLeadingDigits)
        }

        if let customRule, let error = customRule(KitoPhoneNumber(country: country, nationalNumber: digits)) {
            return .invalid(error)
        }
        return .valid
    }

    public func validate(_ number: KitoPhoneNumber) -> KitoPhoneState {
        validate(nationalNumber: number.nationalNumber, country: number.country)
    }
}
