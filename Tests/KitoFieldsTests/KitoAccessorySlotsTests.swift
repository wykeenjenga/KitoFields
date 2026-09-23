//
//  KitoAccessorySlotsTests.swift
//  KitoFieldsTests
//
//  Created by Wycliff Njenga on 22/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import XCTest
import SwiftUI
@testable import KitoFields

final class KitoAccessoryPlacementTests: XCTestCase {
    /// `.accessory(_:placement:)` and friends live on the `KitoFieldConfigurable` protocol
    /// extension, so they're exercised through a concrete field (any of them share the same
    /// implementation) rather than `KitoFieldOptions` directly.
    private func field() -> KitoTextField { KitoTextField(text: .constant("")) }

    func testEachPlacementMapsToItsOwnOptionsSlot() {
        let marker = KitoAccessory.text("x")

        let leading = field().accessory(marker, placement: .leading).options
        XCTAssertNotNil(leading.leading)
        XCTAssertNil(leading.trailing); XCTAssertNil(leading.above); XCTAssertNil(leading.below); XCTAssertNil(leading.overlayCenter)

        let trailing = field().accessory(marker, placement: .trailing).options
        XCTAssertNotNil(trailing.trailing)
        XCTAssertNil(trailing.leading); XCTAssertNil(trailing.above); XCTAssertNil(trailing.below); XCTAssertNil(trailing.overlayCenter)

        let above = field().accessory(marker, placement: .above(alignment: .trailing)).options
        XCTAssertNotNil(above.above)
        XCTAssertEqual(above.aboveAlignment, .trailing)
        XCTAssertNil(above.leading); XCTAssertNil(above.trailing); XCTAssertNil(above.below); XCTAssertNil(above.overlayCenter)

        let below = field().accessory(marker, placement: .below(alignment: .center)).options
        XCTAssertNotNil(below.below)
        XCTAssertEqual(below.belowAlignment, .center)
        XCTAssertNil(below.leading); XCTAssertNil(below.trailing); XCTAssertNil(below.above); XCTAssertNil(below.overlayCenter)

        let center = field().accessory(marker, placement: .center).options
        XCTAssertNotNil(center.overlayCenter)
        XCTAssertNil(center.leading); XCTAssertNil(center.trailing); XCTAssertNil(center.above); XCTAssertNil(center.below)
    }

    func testAboveBelowDefaultToLeadingAlignment() {
        let options = field().options
        XCTAssertEqual(options.aboveAlignment, .leading)
        XCTAssertEqual(options.belowAlignment, .leading)
    }
}

final class KitoOptionalIndicatorTests: XCTestCase {
    func testNotOverriddenFollowsTheTheme() {
        XCTAssertEqual(kitoResolvedOptionalIndicator(override: nil, themeIndicator: "(optional)"), "(optional)")
        XCTAssertEqual(kitoResolvedOptionalIndicator(override: nil, themeIndicator: nil), nil)
    }

    func testExplicitOverrideWinsRegardlessOfTheTheme() {
        XCTAssertEqual(kitoResolvedOptionalIndicator(override: .some("(not required)"), themeIndicator: "(optional)"), "(not required)")
    }

    func testExplicitNilHidesItEvenWhenTheThemeShowsOne() {
        XCTAssertEqual(kitoResolvedOptionalIndicator(override: .some(nil), themeIndicator: "(optional)"), nil)
    }

    func testOptionalModifierStoresTheDoubleOptionalCorrectly() {
        let notCalled = KitoTextField(text: .constant("")).options
        XCTAssertEqual(notCalled.optionalText, nil)

        let defaultText = KitoTextField(text: .constant("")).optional().options
        XCTAssertEqual(defaultText.optionalText, .some("(optional)"))

        let customText = KitoTextField(text: .constant("")).optional("(not required)").options
        XCTAssertEqual(customText.optionalText, .some("(not required)"))

        let hidden = KitoTextField(text: .constant("")).optional(nil).options
        XCTAssertEqual(hidden.optionalText, .some(nil))
    }
}

final class KitoAccessibilityIdentifierOptionTests: XCTestCase {
    func testAccessibilityIdentifierIsStoredOnOptions() {
        let options = KitoTextField(text: .constant("")).accessibilityIdentifier("checkout.details.amount").options
        XCTAssertEqual(options.accessibilityIdentifier, "checkout.details.amount")
    }

    func testUnsetAccessibilityIdentifierStaysNil() {
        XCTAssertNil(KitoTextField(text: .constant("")).options.accessibilityIdentifier)
    }
}

final class KitoCurrencyFieldBridgeTests: XCTestCase {
    private func boundString(_ value: Double?) -> String {
        var text = ""
        let binding = KitoCurrencyField.bridge(Binding(get: { text }, set: { text = $0 }), formatter: KitoCurrencyField.bridgeFormatter())
        binding.wrappedValue = value
        return text
    }

    private func parsed(_ seed: String) -> Double? {
        var text = seed
        return KitoCurrencyField.bridge(Binding(get: { text }, set: { text = $0 }), formatter: KitoCurrencyField.bridgeFormatter()).wrappedValue
    }

    /// What the user sees is not what gets sent: the field displays "1,200.00", but the bound
    /// string — the value the app sends — is the plain "1200.00".
    func testTheBoundStringIsThePlainSendableForm() {
        XCTAssertEqual(boundString(1200), "1200.00")
        XCTAssertEqual(boundString(1250.5), "1250.50")
        XCTAssertEqual(boundString(1_234_567.89), "1234567.89")
        XCTAssertEqual(boundString(0.5), "0.50")
        XCTAssertEqual(boundString(nil), "")
    }

    func testTheBoundStringNeverContainsGrouping() {
        for amount in [1000.0, 20000, 1_250_000.75] {
            XCTAssertFalse(boundString(amount).contains(","), "\(boundString(amount)) must not carry display grouping")
        }
    }

    /// The bound string used to follow the device locale, so in de_DE it read "1.200" — which a
    /// backend parses as 1.2. It must be identical whatever the user's region.
    func testTheBoundStringIsLocaleIndependent() {
        let formatter = KitoCurrencyField.bridgeFormatter()
        XCTAssertEqual(formatter.locale.identifier, "en_US_POSIX")
        XCTAssertEqual(formatter.decimalSeparator, ".")
        XCTAssertFalse(formatter.usesGroupingSeparator)
    }

    /// Reads are lenient, so whatever the app seeds the field with still parses.
    func testSeedValuesParseInAnyReasonableForm() {
        XCTAssertEqual(parsed("1200.00"), 1200)
        XCTAssertEqual(parsed("1200"), 1200)
        XCTAssertEqual(parsed("1,200.00"), 1200, "an older grouped value must not be misread as 1.2")
        XCTAssertEqual(parsed("100000.00"), 100000)
        XCTAssertNil(parsed(""))
    }

    /// A `.currencySelector(...)` already names the currency, so the plain symbol has to be
    /// suppressible — otherwise the field shows it twice.
    func testCurrencyPositionIsReachableOnTheCurrencyField() {
        let field = KitoCurrencyField("Amount", text: .constant(""), currencyCode: "KES")
        XCTAssertEqual(field.base.currencyPosition, .prefix, "currency(_:) still defaults to a leading symbol")

        let suppressed = field.currencyPosition(.none)
        XCTAssertEqual(suppressed.base.currencyPosition, .none)
        XCTAssertEqual(field.currencyPosition(.suffix).base.currencyPosition, .suffix)
    }

    func testFractionDigitsAreReachableOnTheCurrencyField() {
        let whole = KitoCurrencyField("Amount", text: .constant(""), currencyCode: "KES").fractionDigits(0...0)
        XCTAssertEqual(whole.base.formatter.maximumFractionDigits, 0, "currency(_:) pins 2...2; the override has to win")
    }

    func testUnparsableStringYieldsNilRatherThanCrashing() {
        let formatter = KitoCurrencyField.bridgeFormatter()
        var text = "not a number"
        let binding = KitoCurrencyField.bridge(Binding(get: { text }, set: { text = $0 }), formatter: formatter)
        XCTAssertNil(binding.wrappedValue)
    }

    func testNilDoubleWritesBackAnEmptyString() {
        let formatter = KitoCurrencyField.bridgeFormatter()
        var text = "1,250.50"
        let binding = KitoCurrencyField.bridge(Binding(get: { text }, set: { text = $0 }), formatter: formatter)
        binding.wrappedValue = nil
        XCTAssertEqual(text, "")
    }
}

final class KitoCurrencyOptionTests: XCTestCase {
    func testResolvedSymbolPrefersTheExplicitSymbol() {
        let option = KitoCurrencyOption(code: "KES", symbol: "KSh")
        XCTAssertEqual(option.resolvedSymbol, "KSh")
    }

    func testResolvedSymbolFallsBackToTheCodeWhenNoLookupMatches() {
        let option = KitoCurrencyOption(code: "ZZZ")
        XCTAssertEqual(option.resolvedSymbol, "ZZZ")
    }
}

final class KitoPhoneCustomSelectorTests: XCTestCase {
    func testCustomSelectorReceivesTheCurrentCountryAndWritesBackTheChosenOne() {
        var receivedCountry: KitoCountry?
        var chosenCountry: KitoCountry?

        let field = KitoPhoneField(phoneNumber: .constant(nil))
            .countrySelector { current, choose in
                receivedCountry = current
                choose(KitoCountryDatabase.country(isoCode: "KE")!)
                return EmptyView()
            }

        guard case .custom(let builder) = field.phone.selectionMode else {
            XCTFail("countrySelector(_:) must set selectionMode to .custom")
            return
        }
        let us = KitoCountryDatabase.country(isoCode: "US")!
        _ = builder(us) { chosenCountry = $0 }

        XCTAssertEqual(receivedCountry?.isoCode, "US")
        XCTAssertEqual(chosenCountry?.isoCode, "KE")
    }

    func testCountrySelectionEqualityTreatsAnyTwoCustomCasesAsEqual() {
        let a = KitoCountrySelection.custom { _, _ in AnyView(EmptyView()) }
        let b = KitoCountrySelection.custom { _, _ in AnyView(EmptyView()) }
        XCTAssertEqual(a, b, "two .custom selectors with different closures must still compare equal — only the active mode matters to the existing == .locked checks in KitoPhoneField")
        XCTAssertNotEqual(a, .sheet)
        XCTAssertNotEqual(a, .locked)
    }

    func testPrefixPlacementDefaultsToLeading() {
        let field = KitoPhoneField(phoneNumber: .constant(nil))
        XCTAssertEqual(field.phone.prefixPlacement, .leading)
    }

    func testPrefixPlacementModifierUpdatesTheStoredConfiguration() {
        let field = KitoPhoneField(phoneNumber: .constant(nil)).prefixPlacement(.trailing)
        XCTAssertEqual(field.phone.prefixPlacement, .trailing)
    }
}

final class KitoCurrencySymbolTests: XCTestCase {
    /// The symbol is drawn as an accessory, so the formatted text must not repeat it — otherwise
    /// an unfocused field reads "$ $1,250.50".
    func testCurrencyFormatterOmitsTheSymbol() {
        let field = KitoNumberField("Amount", value: .constant(1250.5)).currency("USD")
        let text = field.formatter.string(from: 1250.5 as NSNumber) ?? ""
        XCTAssertFalse(text.contains("$"), "got \(text)")
        XCTAssertTrue(text.contains("1"), "the number itself must still be formatted: got \(text)")
        XCTAssertEqual(text.trimmingCharacters(in: .whitespaces), text, "no stray padding where the symbol used to be: got \(text)")
    }

    func testCurrencyFormatterKeepsTwoFractionDigits() {
        let field = KitoNumberField("Amount", value: .constant(1250.5)).currency("USD")
        XCTAssertTrue((field.formatter.string(from: 1250.5 as NSNumber) ?? "").hasSuffix("50"))
    }

    func testPlainNumberFieldIsUnaffected() {
        let field = KitoNumberField("Count", value: .constant(1250.5))
        XCTAssertEqual(field.formatter.numberStyle, .decimal)
    }
}
