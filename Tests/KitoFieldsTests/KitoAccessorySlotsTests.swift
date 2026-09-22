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
    func testStringBindingRoundTripsThroughTheFormatter() {
        let formatter = KitoCurrencyField.bridgeFormatter()
        formatter.locale = Locale(identifier: "en_US")
        var text = "1,250.50"
        let binding = KitoCurrencyField.bridge(
            Binding(get: { text }, set: { text = $0 }),
            formatter: formatter
        )
        XCTAssertEqual(binding.wrappedValue, 1250.5)

        binding.wrappedValue = 42
        XCTAssertEqual(text, formatter.string(from: 42 as NSNumber))
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
