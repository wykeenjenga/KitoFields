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

/// Unfocused fields show the grouped display form; focused ones show plain editable digits.
final class KitoNumberDisplayTests: XCTestCase {
    private func currency(_ value: Double?, focused: Bool) -> String {
        let field = KitoCurrencyField("Amount", value: .constant(value), currencyCode: "USD")
        return KitoNumberField.text(for: value ?? 0, focused: focused, display: field.base.formatter, editing: Self.editing(field.base))
    }

    private static func editing(_ field: KitoNumberField) -> NumberFormatter {
        let f = NumberFormatter()
        f.locale = .autoupdatingCurrent
        f.numberStyle = .decimal
        f.usesGroupingSeparator = false
        f.maximumFractionDigits = 2
        return f
    }

    func testAnUnfocusedCurrencyFieldShowsTheGroupedForm() {
        let field = KitoCurrencyField("Amount", value: .constant(100000), currencyCode: "USD").locale(Locale(identifier: "en_US"))
        XCTAssertEqual(KitoNumberField.text(for: 100000, focused: false, display: field.base.formatter, editing: Self.editing(field.base)), "100,000.00")
    }

    func testAnUnfocusedCurrencyFieldShowsFixedDecimals() {
        let field = KitoCurrencyField("Amount", value: .constant(1250.5), currencyCode: "USD").locale(Locale(identifier: "en_US"))
        XCTAssertEqual(KitoNumberField.text(for: 1250.5, focused: false, display: field.base.formatter, editing: Self.editing(field.base)), "1,250.50")
    }

    func testAPlainNumberFieldKeepsItsOwnFractionDigits() {
        let field = KitoNumberField("Count", value: .constant(1250.5)).fractionDigits(0...2).locale(Locale(identifier: "en_US"))
        XCTAssertEqual(KitoNumberField.text(for: 1250.5, focused: false, display: field.formatter, editing: Self.editing(field)), "1,250.5")
    }

    /// Focusing switches to plain digits so the formatter never fights typing.
    func testAFocusedFieldShowsPlainEditableDigits() {
        let field = KitoCurrencyField("Amount", value: .constant(1250.5), currencyCode: "USD").locale(Locale(identifier: "en_US"))
        let editing = NumberFormatter()
        editing.locale = Locale(identifier: "en_US")
        editing.numberStyle = .decimal
        editing.usesGroupingSeparator = false
        editing.maximumFractionDigits = 2
        XCTAssertEqual(KitoNumberField.text(for: 1250.5, focused: true, display: field.base.formatter, editing: editing), "1250.5")
    }
}

/// `formatsAsYouType(true)` regroups the integer part after each keystroke.
final class KitoFormatsAsYouTypeTests: XCTestCase {
    private func group(_ s: String) -> String {
        KitoNumberField.groupIntegerPart(s, decimalSeparator: ".", groupingSeparator: ",")
    }

    func testDigitsRegroupAsTheyAreTyped() {
        XCTAssertEqual(group("1"), "1")
        XCTAssertEqual(group("12"), "12")
        XCTAssertEqual(group("123"), "123")
        XCTAssertEqual(group("1234"), "1,234")
        XCTAssertEqual(group("1234567"), "1,234,567")
    }

    func testATrailingDecimalSeparatorIsKeptMidEntry() {
        XCTAssertEqual(group("1234."), "1,234.")
        XCTAssertEqual(group("1234.5"), "1,234.5")
    }

    func testTheFractionIsNeverGrouped() {
        XCTAssertEqual(group("1234.5678"), "1,234.5678")
    }

    func testNegativeAmounts() {
        XCTAssertEqual(group("-1234"), "-1,234")
    }

    /// A regrouped string must survive the next keystroke's normalisation unchanged, or typing
    /// would fight itself.
    func testRegroupedTextIsAFixedPointOfTheTransform() {
        for typed in ["1234", "1234567", "1234.5", "20000"] {
            let once = group(KitoNumberField.normalizeNumericInput(typed, decimalSeparator: ".", groupingSeparator: ",", maximumFractionDigits: 2))
            let twice = group(KitoNumberField.normalizeNumericInput(once, decimalSeparator: ".", groupingSeparator: ",", maximumFractionDigits: 2))
            XCTAssertEqual(once, twice, "\(typed) regrouped to \(once) but then to \(twice)")
        }
    }

    func testTheModifierIsStoredAndForwarded() {
        XCTAssertFalse(KitoNumberField("N", value: .constant(nil)).formatsAsYouTypeValue)
        XCTAssertTrue(KitoNumberField("N", value: .constant(nil)).formatsAsYouType().formatsAsYouTypeValue)
        XCTAssertTrue(KitoCurrencyField("Amount", text: .constant(""), currencyCode: "USD").formatsAsYouType().base.formatsAsYouTypeValue)
    }
}

/// The grouped display form must survive the field's own input transform, whatever focus state
/// that transform happened to capture — otherwise blur writes "1,200.00" and it is immediately
/// sanitised back to "1200.00".
final class KitoDisplayFixedPointTests: XCTestCase {
    private let display: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US")
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.currencySymbol = ""
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()
    private let editing: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US")
        f.numberStyle = .decimal
        f.usesGroupingSeparator = false
        f.maximumFractionDigits = 2
        return f
    }()

    private func isDisplay(_ raw: String) -> Bool {
        let normalized = KitoNumberField.normalizeNumericInput(raw, decimalSeparator: ".", groupingSeparator: ",", maximumFractionDigits: 2)
        return KitoNumberField.isDisplayForm(raw, normalized: normalized, display: display, editing: editing)
    }

    func testTheGroupedDisplayFormIsRecognised() {
        XCTAssertTrue(isDisplay("1,200.00"))
        XCTAssertTrue(isDisplay("100,000.00"))
        XCTAssertTrue(isDisplay("5.00"))
    }

    /// What someone types is not the display form, so it still gets sanitised as input.
    func testTypedInputIsNotMistakenForTheDisplayForm() {
        XCTAssertFalse(isDisplay("1200"))
        XCTAssertFalse(isDisplay("1200.5"))
        XCTAssertFalse(isDisplay("20,5"))
        XCTAssertFalse(isDisplay(""))
    }
}
