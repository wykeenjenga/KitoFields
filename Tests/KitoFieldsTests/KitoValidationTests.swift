//
//  KitoValidationTests.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import XCTest
import SwiftUI
@testable import KitoFields

final class ValidationTests: XCTestCase {
    func testRequired() {
        XCTAssertFalse(KitoRule.required.validate(""))
        XCTAssertFalse(KitoRule.required.validate("   "))
        XCTAssertTrue(KitoRule.required.validate("a"))
    }

    func testOptionalRulesSkipEmpty() {
        XCTAssertTrue(KitoRule.email.validate(""))
        XCTAssertTrue(KitoRule.minLength(5).validate(""))
        XCTAssertFalse(KitoRule.minLength(5).validate("abc"))
    }

    func testEmail() {
        let valid = ["a@b.co", "first.last+tag@sub.example.org", "o'neil@example.com", "USER@EXAMPLE.IO", " padded@example.com "]
        let invalid = ["", "plain", "@example.com", "user@", "user@localhost", "user@@example.com", "user@exa mple.com", "user..dot@example.com", "user@-bad.com", "user@example.c"]
        for v in valid { XCTAssertTrue(KitoEmailValidator.isValid(v), v) }
        for v in invalid { XCTAssertFalse(KitoEmailValidator.isValid(v), v) }
    }

    func testCharacterClassRules() {
        XCTAssertTrue(KitoRule.containsUppercase().validate("aB"))
        XCTAssertFalse(KitoRule.containsUppercase().validate("ab"))
        XCTAssertTrue(KitoRule.containsDigit().validate("a1"))
        XCTAssertTrue(KitoRule.containsSymbol().validate("a!"))
        XCTAssertFalse(KitoRule.containsSymbol().validate("a1 "))
        XCTAssertTrue(KitoRule.numeric().validate("0123"))
        XCTAssertFalse(KitoRule.numeric().validate("12a"))
        XCTAssertTrue(KitoRule.decimal().validate("12,5"))
        XCTAssertTrue(KitoRule.url().validate("https://example.com/path"))
        XCTAssertFalse(KitoRule.url().validate("example"))
        XCTAssertFalse(KitoRule.noWhitespace().validate("a b"))
        XCTAssertTrue(KitoRule.regex("^[A-Z]{3}$", message: "x").validate("ABC"))
    }

    func testMatches() {
        var other = "secret"
        let rule = KitoRule.matches({ other })
        XCTAssertTrue(rule.validate("secret"))
        other = "changed"
        XCTAssertFalse(rule.validate("secret"))
    }

    func testValidatorCollectsMessagesInOrder() {
        let rules: [KitoRule] = [.required, .minLength(8), .containsDigit()]
        XCTAssertEqual(KitoValidator.validate("", rules: []), .idle)
        XCTAssertEqual(KitoValidator.validate("abc", rules: rules), .invalid(["Must be at least 8 characters", "At least one number"]))
        XCTAssertEqual(KitoValidator.validate("abcdefg1", rules: rules), .valid)
        XCTAssertEqual(KitoValidator.validate("", rules: rules), .invalid(["This field is required"]))
    }

    func testRequiredOptionInjectsRule() {
        var options = KitoFieldOptions()
        options.rules = [.minLength(3)]
        XCTAssertEqual(options.effectiveRules.count, 1)
        options.isRequired = true
        XCTAssertEqual(options.effectiveRules.count, 2)
        XCTAssertEqual(options.effectiveRules.first?.id, KitoRule.requiredID)
        options.rules = [.required(message: "Custom"), .minLength(3)]
        XCTAssertEqual(options.effectiveRules.count, 2)
        XCTAssertEqual(options.effectiveRules.first?.message, "Custom")
    }

    func testValidationPresentation() {
        var p = KitoValidationPresentation()
        XCTAssertFalse(p.shouldShowErrors(for: .live))
        p.didBlur()   // blur before any edit should not count
        XCTAssertFalse(p.shouldShowErrors(for: .onBlur))
        p.didEdit()
        XCTAssertTrue(p.shouldShowErrors(for: .live))
        XCTAssertFalse(p.shouldShowErrors(for: .onBlur))
        p.didBlur()
        XCTAssertTrue(p.shouldShowErrors(for: .onBlur))
        XCTAssertFalse(p.shouldShowErrors(for: .onSubmit))
        p.didSubmit()
        XCTAssertTrue(p.shouldShowErrors(for: .onSubmit))
        XCTAssertFalse(p.shouldShowErrors(for: .never))
        p.reset()
        XCTAssertFalse(p.shouldShowErrors(for: .live))
    }
}

final class KitoFieldMotionTests: XCTestCase {
    func testShakeEffectRestsAtWholeShakes() {
        XCTAssertEqual(KitoFieldShakeEffect(shakes: 0).effectValue(size: .zero).m31, 0, accuracy: 0.0001)
        XCTAssertEqual(KitoFieldShakeEffect(shakes: 1).effectValue(size: .zero).m31, 0, accuracy: 0.0001)
        XCTAssertEqual(abs(KitoFieldShakeEffect(shakes: 0.125, amplitude: 8).effectValue(size: .zero).m31), 8, accuracy: 0.0001)
    }

    func testMotionPresets() {
        XCTAssertEqual(KitoFieldMotion.default.focusScale, 1)
        XCTAssertGreaterThan(KitoFieldMotion.lively.focusScale, 1)
        XCTAssertNotNil(KitoFieldMotion.lively.focusedShadow)
        XCTAssertFalse(KitoFieldMotion.subtle.shakesOnError)
        XCTAssertTrue(KitoFieldTheme.default.motion.shakesOnError)
    }
}

final class KitoReducedMotionTests: XCTestCase {
    func testConfigurationUsesSubtleMotionWhenReduced() {
        var theme = KitoFieldTheme()
        theme.motion = .lively
        let make = { (reduced: Bool) in
            KitoFieldStyleConfiguration(label: nil, placeholder: nil, input: KitoFieldSlot(EmptyView()), leading: nil, trailing: nil, footer: nil, helperText: nil, errorMessages: [], isFocused: false, isEnabled: true, isEmpty: true, isSuccess: false, theme: theme, reducesMotion: reduced)
        }
        XCTAssertTrue(make(false).motion.shakesOnError)
        XCTAssertGreaterThan(make(false).motion.focusScale, 1)
        XCTAssertFalse(make(true).motion.shakesOnError)
        XCTAssertEqual(make(true).motion.focusScale, 1)
    }
}

final class KitoNewFieldTests: XCTestCase {
    func testCardBrandDetection() {
        XCTAssertEqual(KitoCardBrand.detect("4111 1111 1111 1111"), .visa)
        XCTAssertEqual(KitoCardBrand.detect("5555555555554444"), .mastercard)
        XCTAssertEqual(KitoCardBrand.detect("2223003122003222"), .mastercard)
        XCTAssertEqual(KitoCardBrand.detect("378282246310005"), .amex)
        XCTAssertEqual(KitoCardBrand.detect("6011111111111117"), .discover)
        XCTAssertEqual(KitoCardBrand.detect("3530111333300000"), .jcb)
        XCTAssertEqual(KitoCardBrand.detect("6200000000000005"), .unionPay)
        XCTAssertEqual(KitoCardBrand.detect(""), .unknown)
        XCTAssertEqual(KitoCardBrand.amex.mask, "#### ###### #####")
        XCTAssertEqual(KitoCardBrand.amex.cvvLength, 4)
    }

    func testLuhn() {
        XCTAssertTrue(KitoCardBrand.passesLuhn("4111 1111 1111 1111"))
        XCTAssertTrue(KitoCardBrand.passesLuhn("378282246310005"))
        XCTAssertFalse(KitoCardBrand.passesLuhn("4111 1111 1111 1112"))
        XCTAssertFalse(KitoCardBrand.passesLuhn("1234"))
        XCTAssertTrue(KitoRule.luhn().validate("5555555555554444"))
    }

    func testExpiry() {
        XCTAssertEqual(KitoCardExpiryField.components("12/30")?.month, 12)
        XCTAssertEqual(KitoCardExpiryField.components("12/30")?.year, 2030)
        XCTAssertNil(KitoCardExpiryField.components("13/30"))
        XCTAssertNil(KitoCardExpiryField.components("1/30"))
        XCTAssertTrue(KitoCardExpiryField.isExpired(month: 1, year: 2020))
        XCTAssertFalse(KitoCardExpiryField.isExpired(month: 12, year: 2099))
        let rules = KitoRule.cardExpiry()
        XCTAssertEqual(KitoValidator.validate("12/99", rules: rules), .valid)
        XCTAssertFalse(KitoValidator.validate("01/20", rules: rules).isValid)
    }

    func testDateParsing() {
        XCTAssertNotNil(KitoDateField.parse("31/12/2026", format: "dd/MM/yyyy"))
        XCTAssertNil(KitoDateField.parse("31/02/2026", format: "dd/MM/yyyy"), "February 31st must be rejected")
        XCTAssertNil(KitoDateField.parse("3/1/2026", format: "dd/MM/yyyy"))
        XCTAssertNotNil(KitoDateField.parse("2026-02-28", format: "yyyy-MM-dd"))
        XCTAssertTrue(KitoRule.date(format: "MM/dd/yyyy").validate("02/28/2026"))
    }

    func testNumberRange() {
        let rules = KitoRule.range(1...99, locale: Locale(identifier: "en_US"))
        XCTAssertEqual(KitoValidator.validate("50", rules: rules), .valid)
        XCTAssertFalse(KitoValidator.validate("0", rules: rules).isValid)
        XCTAssertFalse(KitoValidator.validate("100", rules: rules).isValid)
        XCTAssertTrue(KitoRule.personName().validate("Wycliff Njenga-O'Brien"))
        XCTAssertFalse(KitoRule.personName().validate("W1"))
        XCTAssertTrue(KitoRule.username().validate("wykee_2"))
        XCTAssertFalse(KitoRule.username().validate("hi"))
    }

    func testEmailSuggestions() {
        XCTAssertEqual(KitoEmailField.suggestion(for: "wycliff@gmial.com"), "wycliff@gmail.com")
        XCTAssertEqual(KitoEmailField.suggestion(for: "w@hotmial.com"), "w@hotmail.com")
        XCTAssertNil(KitoEmailField.suggestion(for: "w@gmail.com"), "exact matches need no suggestion")
        XCTAssertNil(KitoEmailField.suggestion(for: "w@triply.co"), "unrelated domains are left alone")
        XCTAssertNil(KitoEmailField.suggestion(for: "no-at-sign"))
    }

    func testRecentSearches() {
        let key = "test.searches.\(UUID().uuidString)"
        defer { KitoCountryRecents.clear(key: key) }
        KitoCountryRecents.recordSearch("ken", key: key, limit: 2)
        KitoCountryRecents.recordSearch("Ken", key: key, limit: 2)
        KitoCountryRecents.recordSearch("+44", key: key, limit: 2)
        XCTAssertEqual(KitoCountryRecents.loadSearches(key: key, limit: 2), ["+44", "Ken"])
        KitoCountryRecents.recordSearch("   ", key: key)
        XCTAssertEqual(KitoCountryRecents.loadSearches(key: key, limit: 2).count, 2)
    }
}

final class KitoReviewTests: XCTestCase {
    func testErrorThemeDefaults() {
        let theme = KitoFieldTheme()
        XCTAssertEqual(theme.errorIcon, "exclamationmark.circle.fill")
        XCTAssertNil(theme.errorFont)
        XCTAssertNil(theme.errorIconFont)
    }

    func testFocusEqualsBridge() {
        enum Field: Hashable { case name, email }
        var current: Field? = nil
        let bridge = Binding<Bool>(
            get: { current == .email },
            set: { on in if on { current = .email } else if current == .email { current = nil } }
        )
        XCTAssertFalse(bridge.wrappedValue)
        bridge.wrappedValue = true
        XCTAssertEqual(current, .email)
        current = .name
        XCTAssertFalse(bridge.wrappedValue)
        bridge.wrappedValue = false
        XCTAssertEqual(current, .name, "resigning must not clear another field's focus")
    }
}
