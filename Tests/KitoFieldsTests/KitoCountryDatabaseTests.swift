//
//  KitoCountryDatabaseTests.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import XCTest
@testable import KitoFields

final class CountryDatabaseTests: XCTestCase {
    func testISOCodesAreUniqueAndWellFormed() {
        let codes = KitoCountryDatabase.all.map(\.isoCode)
        XCTAssertEqual(codes.count, Set(codes).count, "duplicate ISO codes")
        for code in codes {
            XCTAssertEqual(code.count, 2, code)
            XCTAssertTrue(code.allSatisfy { $0.isUppercase }, code)
        }
        XCTAssertGreaterThan(codes.count, 200)
    }

    func testDialCodesAreNumeric() {
        for country in KitoCountryDatabase.all {
            XCTAssertFalse(country.dialCode.isEmpty, country.isoCode)
            XCTAssertTrue(country.dialCode.allSatisfy(\.isNumber), country.isoCode)
            XCTAssertLessThanOrEqual(country.dialCode.count, 3, country.isoCode)
        }
    }

    func testExactlyOneMainCountryPerDialCode() {
        for code in KitoCountryDatabase.dialCodes {
            let mains = KitoCountryDatabase.countries(dialCode: code).filter(\.isMainCountryForDialCode)
            XCTAssertEqual(mains.count, 1, "dial code +\(code) has \(mains.count) main regions: \(mains.map(\.isoCode))")
        }
    }

    func testNonMainCountriesHaveLeadingDigits() {
        for country in KitoCountryDatabase.all where !country.isMainCountryForDialCode {
            XCTAssertFalse(country.leadingDigits.isEmpty, "\(country.isoCode) shares +\(country.dialCode) but has no leading digits")
        }
    }

    func testFormatsFitLengthRanges() {
        for country in KitoCountryDatabase.all {
            for mask in country.formats {
                XCTAssertTrue(country.nationalNumberLengths.contains(mask.digitCount), "\(country.isoCode) mask '\(mask)' outside \(country.nationalNumberLengths)")
            }
            XCTAssertLessThanOrEqual(country.dialCode.count + country.maxNationalNumberLength, 15, "\(country.isoCode) exceeds E.164 length")
        }
    }

    func testExampleNumbersAreValid() {
        let validator = KitoPhoneValidator()
        for country in KitoCountryDatabase.all {
            let state = validator.validate(nationalNumber: country.exampleNumber, country: country)
            XCTAssertEqual(state, .valid, "\(country.isoCode) example \(country.exampleNumber) -> \(state)")
        }
    }

    func testFlagsAndLookups() {
        let kenya = KitoCountryDatabase.country(isoCode: "ke")
        XCTAssertEqual(kenya?.flag, "🇰🇪")
        XCTAssertEqual(kenya?.formattedDialCode, "+254")
        XCTAssertEqual(kenya?.localizedName(in: Locale(identifier: "en")), "Kenya")
        XCTAssertEqual(kenya?.localizedName(in: Locale(identifier: "fr")), "Kenya")
        XCTAssertEqual(KitoCountryDatabase.country(isoCode: "DE")?.localizedName(in: Locale(identifier: "de")), "Deutschland")
    }

    func testInternationalMatching() {
        XCTAssertEqual(KitoCountryDatabase.match(internationalDigits: "12015550123")?.country.isoCode, "US")
        XCTAssertEqual(KitoCountryDatabase.match(internationalDigits: "14165550123")?.country.isoCode, "CA")
        XCTAssertEqual(KitoCountryDatabase.match(internationalDigits: "18765550123")?.country.isoCode, "JM")
        XCTAssertEqual(KitoCountryDatabase.match(internationalDigits: "447400123456")?.country.isoCode, "GB")
        XCTAssertEqual(KitoCountryDatabase.match(internationalDigits: "447797712345")?.country.isoCode, "JE")
        XCTAssertEqual(KitoCountryDatabase.match(internationalDigits: "79123456789")?.country.isoCode, "RU")
        XCTAssertEqual(KitoCountryDatabase.match(internationalDigits: "77710009998")?.country.isoCode, "KZ")
        XCTAssertEqual(KitoCountryDatabase.match(internationalDigits: "254712123456")?.country.isoCode, "KE")
        XCTAssertEqual(KitoCountryDatabase.match(internationalDigits: "254712123456")?.nationalNumber, "712123456")
        XCTAssertEqual(KitoCountryDatabase.match(internationalDigits: "61412345678")?.country.isoCode, "AU")
        XCTAssertEqual(KitoCountryDatabase.match(internationalDigits: "35818123456")?.country.isoCode, "AX")
        XCTAssertNil(KitoCountryDatabase.match(internationalDigits: "0"))
    }
}

final class KitoCountryDataTests: XCTestCase {
    func testCurrencies() {
        XCTAssertEqual(KitoCountryDatabase.country(isoCode: "KE")?.currencyCode, "KES")
        XCTAssertEqual(KitoCountryDatabase.country(isoCode: "US")?.currencyCode, "USD")
        XCTAssertEqual(KitoCountryDatabase.country(isoCode: "FR")?.currencyCode, "EUR")
        XCTAssertNotNil(KitoCountryDatabase.country(isoCode: "KE")?.currencySymbol)
        XCTAssertNotEqual(KitoCountryDatabase.country(isoCode: "KE")?.currencySymbol, "$", "KES must not borrow the device currency symbol")
        XCTAssertEqual(KitoCountryDatabase.country(isoCode: "GB")?.currencySymbol, "£")
        XCTAssertTrue(KitoCountryDatabase.country(isoCode: "US")!.formatCurrency(1250, locale: Locale(identifier: "en_US"))!.contains("1,250"))
    }

    func testSummaryCarriesEverything() {
        let summary = KitoCountryDatabase.country(isoCode: "KE")!.summary
        XCTAssertEqual(summary.flag, "🇰🇪")
        XCTAssertEqual(summary.formattedDialCode, "+254")
        XCTAssertEqual(summary.currencyCode, "KES")
        XCTAssertEqual(summary.englishName, "Kenya")
    }

    func testRecentsRoundTrip() {
        let key = "test.recents.\(UUID().uuidString)"
        defer { KitoCountryRecents.clear(key: key) }
        XCTAssertTrue(KitoCountryRecents.load(key: key).isEmpty)
        KitoCountryRecents.record(KitoCountryDatabase.country(isoCode: "KE")!, key: key, limit: 2)
        KitoCountryRecents.record(KitoCountryDatabase.country(isoCode: "US")!, key: key, limit: 2)
        KitoCountryRecents.record(KitoCountryDatabase.country(isoCode: "KE")!, key: key, limit: 2)
        XCTAssertEqual(KitoCountryRecents.load(key: key, limit: 2).map(\.isoCode), ["KE", "US"])
        KitoCountryRecents.record(KitoCountryDatabase.country(isoCode: "GB")!, key: key, limit: 2)
        XCTAssertEqual(KitoCountryRecents.load(key: key, limit: 2).map(\.isoCode), ["GB", "KE"])
    }

    func testDiacriticInsensitiveFolding() {
        XCTAssertEqual(KitoCountryPicker.fold("Côte d'Ivoire"), "cote d'ivoire")
        XCTAssertEqual(KitoCountryPicker.fold("Réunion"), "reunion")
    }
}
