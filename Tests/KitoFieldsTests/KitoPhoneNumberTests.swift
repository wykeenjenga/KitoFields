//
//  KitoPhoneNumberTests.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import XCTest
@testable import KitoFields

final class PhoneNumberTests: XCTestCase {
    let formatter = KitoPhoneFormatter()
    var us: KitoCountry { KitoCountryDatabase.country(isoCode: "US")! }
    var gb: KitoCountry { KitoCountryDatabase.country(isoCode: "GB")! }
    var ke: KitoCountry { KitoCountryDatabase.country(isoCode: "KE")! }
    var de: KitoCountry { KitoCountryDatabase.country(isoCode: "DE")! }

    func testMaskAppliesProgressively() {
        XCTAssertEqual(formatter.formatNational("2", country: us), "(2")
        XCTAssertEqual(formatter.formatNational("201", country: us), "(201")
        XCTAssertEqual(formatter.formatNational("2015", country: us), "(201) 5")
        XCTAssertEqual(formatter.formatNational("2015550123", country: us), "(201) 555-0123")
        XCTAssertEqual(formatter.formatNational("", country: us), "")
    }

    func testOverflowDigitsAreAppended() {
        XCTAssertEqual(formatter.formatNational("201555012399", country: us), "(201) 555-012399")
    }

    func testBrazilPicksMaskByLength() {
        let br = KitoCountryDatabase.country(isoCode: "BR")!
        XCTAssertEqual(formatter.formatNational("1140041234", country: br), "(11) 4004-1234")
        XCTAssertEqual(formatter.formatNational("11961234567", country: br), "(11) 96123-4567")
    }

    func testGenericGrouping() {
        XCTAssertEqual(formatter.groupGenerically("1234567"), "123 4567")
        XCTAssertEqual(formatter.groupGenerically("123456"), "123 456")
        XCTAssertEqual(formatter.groupGenerically("12345"), "123 45")
    }

    func testTrunkPrefixHandling() {
        XCTAssertEqual(formatter.stripTrunkPrefix("07400123456", country: gb), "7400123456")
        XCTAssertEqual(formatter.stripTrunkPrefix("7400123456", country: gb), "7400123456")
        XCTAssertEqual(formatter.stripTrunkPrefix("0", country: gb), "0")
        XCTAssertEqual(formatter.stripTrunkPrefix("2015550123", country: us), "2015550123")
        XCTAssertEqual(KitoPhoneNumber(country: gb, nationalNumber: "07400 123456").nationalNumber, "7400123456")
    }

    func testFormats() {
        let number = KitoPhoneNumber(country: ke, nationalNumber: "0712123456")
        XCTAssertEqual(number.e164, "+254712123456")
        XCTAssertEqual(number.international, "+254 712 123456")
        XCTAssertEqual(number.national, "712 123456")
        XCTAssertEqual(number.formatted(.nationalWithTrunkPrefix), "0712 123456")
        XCTAssertEqual(number.rfc3966, "tel:+254-712-123456")
        XCTAssertEqual(number.url?.absoluteString, "tel:+254712123456")
        XCTAssertTrue(number.isValid)
    }

    func testParsing() {
        XCTAssertEqual(KitoPhoneNumber(parsing: "+1 (416) 555-0123")?.country.isoCode, "CA")
        XCTAssertEqual(KitoPhoneNumber(parsing: "+1 (416) 555-0123")?.nationalNumber, "4165550123")
        XCTAssertEqual(KitoPhoneNumber(parsing: "00254 712 123456")?.e164, "+254712123456")
        XCTAssertEqual(KitoPhoneNumber(parsing: "07400 123456", defaultCountry: gb)?.e164, "+447400123456")
        XCTAssertEqual(KitoPhoneNumber(e164: "+4915123456789")?.country.isoCode, "DE")
        XCTAssertNil(KitoPhoneNumber(e164: "4915123456789"))
        XCTAssertNil(KitoPhoneNumber(parsing: "   "))
        XCTAssertNil(KitoPhoneNumber(parsing: "abc", defaultCountry: us))
    }

    func testValidation() {
        let v = KitoPhoneValidator()
        XCTAssertEqual(v.validate(nationalNumber: "", country: us), .empty)
        XCTAssertEqual(v.validate(nationalNumber: "20155", country: us), .incomplete)
        XCTAssertEqual(v.validate(nationalNumber: "2015550123", country: us), .valid)
        XCTAssertEqual(v.validate(nationalNumber: "20155501234", country: us), .invalid(.tooLong))
        XCTAssertEqual(v.validate(nationalNumber: "1015550123", country: us), .invalid(.invalidLeadingDigits))
        XCTAssertEqual(v.validate(nationalNumber: "2010550123", country: us), .invalid(.invalidLeadingDigits))
        XCTAssertEqual(v.validate(nationalNumber: "15123456789", country: de), .valid)
        XCTAssertEqual(v.validate(nationalNumber: "30123", country: de), .valid)

        let jersey = KitoCountryDatabase.country(isoCode: "JE")!
        XCTAssertEqual(v.validate(nationalNumber: "7400123456", country: jersey), .invalid(.invalidLeadingDigits))
        XCTAssertEqual(v.validate(nationalNumber: "7797712345", country: jersey), .valid)
    }

    func testCustomRule() {
        let mobileOnly = KitoPhoneValidator { number in
            number.country.isoCode == "KE" && !number.nationalNumber.hasPrefix("7") && !number.nationalNumber.hasPrefix("1")
                ? .custom("Enter a mobile number") : nil
        }
        XCTAssertEqual(mobileOnly.validate(nationalNumber: "712123456", country: ke), .valid)
        XCTAssertEqual(mobileOnly.validate(nationalNumber: "202123456", country: ke), .invalid(.custom("Enter a mobile number")))
    }

    func testCodableRoundTrip() throws {
        let number = KitoPhoneNumber(country: gb, nationalNumber: "7400123456")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(number)
        XCTAssertEqual(String(data: data, encoding: .utf8), #"{"isoCode":"GB","nationalNumber":"7400123456"}"#)
        let decoded = try JSONDecoder().decode(KitoPhoneNumber.self, from: data)
        XCTAssertEqual(decoded, number)
        XCTAssertThrowsError(try JSONDecoder().decode(KitoPhoneNumber.self, from: Data(#"{"isoCode":"ZZ","nationalNumber":"1"}"#.utf8)))
    }

    func testEqualityIgnoresMetadata() {
        let a = KitoCountry(isoCode: "US", dialCode: "1", englishName: "United States")
        XCTAssertEqual(a, us)
        XCTAssertEqual(Set([a, us]).count, 1)
    }
}

final class KitoDefaultCountryTests: XCTestCase {
    func testDefaultIsUnitedStates() {
        let config = KitoPhoneFieldConfiguration()
        XCTAssertEqual(config.defaultCountry, "US")
        XCTAssertEqual(config.resolvedDefaultCountry().isoCode, "US")
    }

    func testDeviceRegionFallsBackWhenNotAllowed() {
        var config = KitoPhoneFieldConfiguration()
        config.defaultCountry = nil
        config.allowedCountries = ["KE"]
        XCTAssertEqual(config.resolvedDefaultCountry().isoCode, "KE")
    }
}
