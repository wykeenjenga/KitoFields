//
//  KitoPhoneNumber.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import Foundation

/// A parsed phone number: a region plus the national significant number (digits only, no trunk prefix).
public struct KitoPhoneNumber: Hashable, Sendable, CustomStringConvertible {
    public var country: KitoCountry
    public var nationalNumber: String

    public init(country: KitoCountry, nationalNumber: String) {
        self.country = country
        self.nationalNumber = KitoPhoneFormatter().stripTrunkPrefix(nationalNumber.asciiDigits, country: country)
    }

    /// Parses "+254 712 123456", "00254712123456" or a national number in `defaultCountry`.
    public init?(parsing input: String, defaultCountry: KitoCountry? = nil) {
        guard let parsed = KitoPhoneParser().parse(input, defaultCountry: defaultCountry) else { return nil }
        self = parsed
    }

    /// Parses an E.164 string such as "+12015550123".
    public init?(e164: String) {
        guard e164.hasPrefix("+"), let parsed = KitoPhoneParser().parse(e164) else { return nil }
        self = parsed
    }

    public var isEmpty: Bool { nationalNumber.isEmpty }

    public var e164: String { formatted(.e164) }
    public var international: String { formatted(.international) }
    public var national: String { formatted(.national) }
    public var rfc3966: String { formatted(.rfc3966) }

    public func formatted(_ style: KitoPhoneFormat = .international) -> String {
        KitoPhoneFormatter().format(nationalNumber, country: country, as: style)
    }

    public var validationState: KitoPhoneState {
        KitoPhoneValidator().validate(nationalNumber: nationalNumber, country: country)
    }

    public var isValid: Bool { validationState == .valid }

    /// `tel:` URL suitable for `openURL`.
    public var url: URL? { URL(string: "tel:\(e164)") }

    public var description: String { international }
}

// Encodes as {"isoCode": "KE", "nationalNumber": "712123456"} so stored values survive metadata updates.
extension KitoPhoneNumber: Codable {
    private enum CodingKeys: String, CodingKey { case isoCode, nationalNumber }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let iso = try container.decode(String.self, forKey: .isoCode)
        guard let country = KitoCountryDatabase.country(isoCode: iso) else {
            throw DecodingError.dataCorruptedError(forKey: .isoCode, in: container, debugDescription: "Unknown region \(iso)")
        }
        self.init(country: country, nationalNumber: try container.decode(String.self, forKey: .nationalNumber))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(country.isoCode, forKey: .isoCode)
        try container.encode(nationalNumber, forKey: .nationalNumber)
    }
}
