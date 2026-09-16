//
//  KitoCountry.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import Foundation

/// A calling region: ISO 3166-1 alpha-2 code, dial code and national number formatting metadata.
public struct KitoCountry: Identifiable, Codable, Sendable {
    /// ISO 3166-1 alpha-2, uppercase (e.g. "KE").
    public let isoCode: String
    /// Country calling code without "+" (e.g. "254").
    public let dialCode: String
    public let englishName: String
    /// Format masks for the national significant number, shortest first. `#` = digit.
    public let formats: [String]
    /// Allowed digit counts for the national significant number.
    public let nationalNumberLengths: ClosedRange<Int>
    /// Domestic trunk prefix stripped before formatting/E.164 (e.g. "0" in the UK, "8" in Russia).
    public let trunkPrefix: String?
    /// A plausible national number used for placeholders.
    public let exampleNumber: String
    /// National-number prefixes that identify this region when several share a dial code
    /// (NANP area codes, Kazakhstan's 6/7 under +7, etc.).
    public let leadingDigits: [String]
    /// The region chosen when a shared dial code cannot be disambiguated.
    public let isMainCountryForDialCode: Bool

    public init(isoCode: String, dialCode: String, englishName: String, formats: [String] = [], nationalNumberLengths: ClosedRange<Int>? = nil, trunkPrefix: String? = nil, exampleNumber: String? = nil, leadingDigits: [String] = [], isMainCountryForDialCode: Bool = true) {
        self.isoCode = isoCode.uppercased()
        self.dialCode = dialCode
        self.englishName = englishName
        self.formats = formats.sorted { $0.digitCount < $1.digitCount }
        if let nationalNumberLengths {
            self.nationalNumberLengths = nationalNumberLengths
        } else if let shortest = self.formats.first, let longest = self.formats.last {
            self.nationalNumberLengths = shortest.digitCount...longest.digitCount
        } else {
            self.nationalNumberLengths = 4...max(4, 15 - dialCode.count)
        }
        self.trunkPrefix = trunkPrefix
        self.exampleNumber = exampleNumber ?? String("2345678901234".prefix(self.nationalNumberLengths.upperBound))
        self.leadingDigits = leadingDigits
        self.isMainCountryForDialCode = isMainCountryForDialCode
    }

    public var id: String { isoCode }

    /// Regional-indicator emoji flag derived from the ISO code.
    public var flag: String {
        isoCode.unicodeScalars.compactMap { UnicodeScalar(127397 + $0.value) }.map(String.init).joined()
    }

    /// "+254"
    public var formattedDialCode: String { "+\(dialCode)" }

    /// Name in the user's current locale, falling back to English.
    public var localizedName: String { localizedName(in: .autoupdatingCurrent) }

    public func localizedName(in locale: Locale) -> String {
        locale.localizedString(forRegionCode: isoCode) ?? englishName
    }

    // MARK: Currency (derived from the system locale database, no hand-curated table)

    /// ISO 4217 currency code for the region, e.g. "KES", "USD". Nil for regions without one.
    public var currencyCode: String? {
        let locale = Locale(identifier: "en_\(isoCode)")
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return locale.currency?.identifier
        } else {
            return locale.currencyCode
        }
    }

    /// Currency symbol as shown in the user's locale, e.g. "Ksh", "$", "€".
    public var currencySymbol: String? {
        guard let code = currencyCode else { return nil }
        // NumberFormatter resolves the symbol for an arbitrary currency in the user's locale;
        // Locale.currencySymbol only knows the locale's own currency.
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .autoupdatingCurrent
        formatter.currencyCode = code
        if let symbol = formatter.currencySymbol, symbol != code { return symbol }
        return Locale(identifier: "en_\(isoCode)").currencySymbol
    }

    /// Currency name in the user's locale, e.g. "Kenyan Shilling".
    public var localizedCurrencyName: String? {
        guard let code = currencyCode else { return nil }
        return Locale.autoupdatingCurrent.localizedString(forCurrencyCode: code)
    }

    /// Formats an amount in the region's currency, e.g. `format(1250)` → "KSh 1,250.00".
    public func formatCurrency(_ amount: Decimal, locale: Locale = .autoupdatingCurrent) -> String? {
        guard let code = currencyCode else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.locale = locale
        return formatter.string(from: amount as NSDecimalNumber)
    }

    /// Everything an app usually wants back from a country selection, in one value.
    public var summary: KitoCountrySummary {
        KitoCountrySummary(country: self)
    }

    public var minNationalNumberLength: Int { nationalNumberLengths.lowerBound }
    public var maxNationalNumberLength: Int { nationalNumberLengths.upperBound }

    /// Example number formatted nationally, e.g. "(201) 555-0123".
    public var formattedExampleNumber: String {
        KitoPhoneFormatter().formatNational(exampleNumber, country: self)
    }
}

extension KitoCountry: Hashable {
    public static func == (lhs: KitoCountry, rhs: KitoCountry) -> Bool { lhs.isoCode == rhs.isoCode }
    public func hash(into hasher: inout Hasher) { hasher.combine(isoCode) }
}

extension String {
    var digitCount: Int { filter { $0 == "#" }.count }
    /// ASCII digits only.
    var asciiDigits: String { filter { $0.isASCII && $0.isNumber } }
}


/// Flat, ready-to-use snapshot of a country: flag, names, dial code and currency.
public struct KitoCountrySummary: Hashable, Sendable {
    public let isoCode: String
    public let flag: String
    public let name: String
    public let englishName: String
    public let dialCode: String
    public let formattedDialCode: String
    public let currencyCode: String?
    public let currencySymbol: String?
    public let currencyName: String?

    public init(country: KitoCountry) {
        isoCode = country.isoCode
        flag = country.flag
        name = country.localizedName
        englishName = country.englishName
        dialCode = country.dialCode
        formattedDialCode = country.formattedDialCode
        currencyCode = country.currencyCode
        currencySymbol = country.currencySymbol
        currencyName = country.localizedCurrencyName
    }
}
