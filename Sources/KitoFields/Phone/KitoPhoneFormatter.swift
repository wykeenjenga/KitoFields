//
//  KitoPhoneFormatter.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import Foundation

/// Output formats for a phone number.
public enum KitoPhoneFormat: Sendable {
    /// "+254712123456"
    case e164
    /// "+254 712 123456"
    case international
    /// "712 123456"
    case national
    /// "0712 123456" (national with the trunk prefix where the region uses one)
    case nationalWithTrunkPrefix
    /// "tel:+254-712-123456"
    case rfc3966
}

/// Mask-based formatter. Masks use `#` for digits; any other character is a literal separator.
public struct KitoPhoneFormatter: Sendable {
    public init() {}

    /// Picks the shortest mask that can hold `digits`, falling back to the longest.
    public func mask(for digits: String, country: KitoCountry) -> String? {
        guard !country.formats.isEmpty else { return nil }
        return country.formats.first { $0.digitCount >= digits.count } ?? country.formats.last
    }

    /// Fills `mask` with `digits`, stopping at the last typed digit (no dangling separators).
    /// Digits beyond the mask's capacity are appended unformatted.
    public func apply(mask: String, to digits: String) -> String {
        var result = ""
        var pending = ""
        var iterator = digits.makeIterator()
        var next = iterator.next()
        for char in mask {
            guard next != nil else { break }
            if char == "#" {
                result += pending + String(next!)
                pending = ""
                next = iterator.next()
            } else {
                pending.append(char)
            }
        }
        if let remaining = next {
            result.append(remaining)
            while let d = iterator.next() { result.append(d) }
        }
        return result
    }

    /// National significant number formatted for display, e.g. "(201) 555-0123".
    public func formatNational(_ nationalNumber: String, country: KitoCountry) -> String {
        let digits = nationalNumber.asciiDigits
        guard !digits.isEmpty else { return "" }
        if let mask = mask(for: digits, country: country) {
            return apply(mask: mask, to: digits)
        }
        return groupGenerically(digits)
    }

    /// "+1 (201) 555-0123"
    public func formatInternational(_ nationalNumber: String, country: KitoCountry) -> String {
        let national = formatNational(nationalNumber, country: country)
        return national.isEmpty ? country.formattedDialCode : "\(country.formattedDialCode) \(national)"
    }

    /// "+12015550123"
    public func formatE164(_ nationalNumber: String, country: KitoCountry) -> String {
        "+\(country.dialCode)\(nationalNumber.asciiDigits)"
    }

    public func format(_ nationalNumber: String, country: KitoCountry, as style: KitoPhoneFormat) -> String {
        switch style {
        case .e164:
            return formatE164(nationalNumber, country: country)
        case .international:
            return formatInternational(nationalNumber, country: country)
        case .national:
            return formatNational(nationalNumber, country: country)
        case .nationalWithTrunkPrefix:
            let national = formatNational(nationalNumber, country: country)
            guard let trunk = country.trunkPrefix, !national.isEmpty else { return national }
            // Keep "(" grouping intact: "0 (11) 9..." is unusual, so only prefix when the mask
            // starts with a digit slot.
            return national.hasPrefix("(") ? national : trunk + national
        case .rfc3966:
            let national = formatNational(nationalNumber, country: country)
                .replacingOccurrences(of: "[^0-9]+", with: "-", options: .regularExpression)
                .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
            return "tel:+\(country.dialCode)-\(national)"
        }
    }

    /// Groups of three, with a trailing group of four when the count leaves a remainder of one.
    public func groupGenerically(_ digits: String) -> String {
        var groups: [String] = []
        var rest = Substring(digits)
        while !rest.isEmpty {
            let take = (rest.count == 4) ? 4 : min(3, rest.count)
            groups.append(String(rest.prefix(take)))
            rest = rest.dropFirst(take)
        }
        return groups.joined(separator: " ")
    }

    /// Removes the region's trunk prefix ("0", "8", "06") from raw national digits when present
    /// and the remainder is still a plausible number.
    public func stripTrunkPrefix(_ digits: String, country: KitoCountry) -> String {
        guard let trunk = country.trunkPrefix, digits.hasPrefix(trunk), digits.count > trunk.count else { return digits }
        return String(digits.dropFirst(trunk.count))
    }
}
