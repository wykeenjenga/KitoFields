//
//  KitoValidationTests.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import XCTest
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

final class KitoLocalizationTests: XCTestCase {
    func testAllLanguagesDefineTheSameKeys() {
        let en = KitoLocalization.keys(forLanguage: "en")
        XCTAssertGreaterThan(en.count, 30)
        for code in ["sw", "fr"] {
            let keys = KitoLocalization.keys(forLanguage: code)
            XCTAssertEqual(keys, en, "\(code) is missing \(en.subtracting(keys)) / has extra \(keys.subtracting(en))")
        }
    }

    func testEnglishFallbackAndProviderOverride() {
        XCTAssertEqual(KitoLocalization.string("rule.required", "fallback"), KitoLocalization.string("rule.required", "fallback"))
        XCTAssertEqual(KitoLocalization.string("does.not.exist", "Fallback copy"), "Fallback copy")
        KitoLocalization.provider = { key, _ in key == "rule.required" ? "Lazima" : nil }
        defer { KitoLocalization.provider = nil }
        XCTAssertEqual(KitoRule.required().message, "Lazima")
        XCTAssertEqual(KitoRule.email().message, KitoLocalization.string("rule.email", ""))
    }

    func testFormattedMessages() {
        XCTAssertTrue(KitoRule.minLength(8).message.contains("8"))
        XCTAssertTrue(KitoRule.exactLength(4).message.contains("4"))
    }
}
