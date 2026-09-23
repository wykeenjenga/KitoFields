//
//  KitoNumberInputTests.swift
//  KitoFieldsTests
//
//  Created by Wycliff Njenga on 23/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import XCTest
@testable import KitoFields

/// `reformat()` writes a grouped string on blur, which then goes back through the field's own
/// input transform. Folding every "." and "," into the decimal separator turned "20,000.00" into
/// "20.00" — a payment of 20,000 silently became 20.
final class KitoNumberInputTests: XCTestCase {
    private func normalize(_ raw: String, decimal: String = ".", grouping: String = ",", fractionDigits: Int = 2) -> String {
        KitoNumberField.normalizeNumericInput(raw, decimalSeparator: decimal, groupingSeparator: grouping, maximumFractionDigits: fractionDigits)
    }

    func testTheReportedCase() {
        XCTAssertEqual(normalize("20,000.00"), "20000.00")
    }

    func testGroupedValuesSurviveTheRoundTrip() {
        XCTAssertEqual(normalize("1,250.50"), "1250.50")
        XCTAssertEqual(normalize("20,000"), "20000")
        XCTAssertEqual(normalize("1,234,567.89"), "1234567.89")
    }

    /// The forgiving behaviour that the old mapping existed for: a comma where this locale wants a
    /// full stop is still read as a decimal separator, because "5" is not a group of three.
    func testACommaUsedAsADecimalSeparatorStillWorks() {
        XCTAssertEqual(normalize("20,5"), "20.5")
        XCTAssertEqual(normalize("0,75"), "0.75")
    }

    func testPlainInputIsUntouched() {
        XCTAssertEqual(normalize("20000"), "20000")
        XCTAssertEqual(normalize("20000.50"), "20000.50")
        XCTAssertEqual(normalize(""), "")
    }

    func testCommaDecimalLocales() {
        // de_DE: "20.000,00" — grouping ".", decimal ","
        XCTAssertEqual(normalize("20.000,00", decimal: ",", grouping: "."), "20000,00")
        XCTAssertEqual(normalize("1.250,50", decimal: ",", grouping: "."), "1250,50")
        XCTAssertEqual(normalize("20.5", decimal: ",", grouping: "."), "20,5", "a full stop where this locale wants a comma is still a decimal separator")
    }

    /// A separator repeated in one string can only be grouping — there is no such thing as two
    /// decimal points. Same rule that lets someone paste "1.234.567" into an en_US field.
    func testARepeatedSeparatorIsAlwaysGrouping() {
        XCTAssertEqual(normalize("20.00.50"), "200050")
        XCTAssertEqual(normalize("1.234.567"), "1234567")
        XCTAssertEqual(normalize("1,234,567"), "1234567")
    }

    func testFractionDigitsAreCapped() {
        XCTAssertEqual(normalize("20.12345"), "20.12")
        XCTAssertEqual(normalize("20.12345", fractionDigits: 0), "2012345", "with no fraction digits the separator is dropped entirely")
    }

    func testMinusIsKeptOnlyAtTheFront() {
        XCTAssertEqual(normalize("-20,000.00"), "-20000.00")
        XCTAssertEqual(normalize("20-000"), "20000")
    }

    func testLettersAndSymbolsAreStripped() {
        XCTAssertEqual(normalize("KSh 20,000.00"), "20000.00")
        XCTAssertEqual(normalize("$1,250.50"), "1250.50")
    }

    /// The whole point: what the display formatter writes must survive re-parsing unchanged.
    func testDisplayOutputRoundTripsThroughTheTransform() {
        let display = NumberFormatter()
        display.locale = Locale(identifier: "en_US")
        display.numberStyle = .currency
        display.currencyCode = "USD"
        display.currencySymbol = ""
        display.minimumFractionDigits = 2
        display.maximumFractionDigits = 2

        let editing = NumberFormatter()
        editing.locale = Locale(identifier: "en_US")
        editing.numberStyle = .decimal
        editing.usesGroupingSeparator = false
        editing.maximumFractionDigits = 2

        for amount in [20000.0, 1250.5, 999.0, 1_234_567.89, 0.5] {
            let shown = display.string(from: amount as NSNumber)!.trimmingCharacters(in: .whitespaces)
            let normalized = normalize(shown)
            XCTAssertEqual(editing.number(from: normalized)?.doubleValue, amount, "\(shown) must re-parse as \(amount), got \(normalized)")
        }
    }
}
