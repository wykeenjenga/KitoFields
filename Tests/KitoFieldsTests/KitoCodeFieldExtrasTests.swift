//
//  KitoCodeFieldExtrasTests.swift
//  KitoFieldsTests
//
//  Created by Wycliff Njenga on 22/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI
import XCTest
@testable import KitoFields

final class KitoCodeSanitizeTests: XCTestCase {
    func testDigitsDropEverythingElse() {
        XCTAssertEqual(KitoCodeField.sanitize("12a3!4", characterSet: .digits, uppercases: true, length: 6), "1234")
    }

    func testArabicIndicAndPersianDigitsBecomeASCII() {
        XCTAssertEqual(KitoCodeField.sanitize("١٢٣٤٥٦", characterSet: .digits, uppercases: true, length: 6), "123456")
        XCTAssertEqual(KitoCodeField.sanitize("۱۲۳-456", characterSet: .digits, uppercases: true, length: 6), "123456")
        XCTAssertEqual("½²٣".asciiDigits, "3")
    }

    func testPastedCodeStripsSpacesAndDashes() {
        XCTAssertEqual(KitoCodeField.sanitize("123 456", characterSet: .digits, uppercases: true, length: 6), "123456")
        XCTAssertEqual(KitoCodeField.sanitize("123-456", characterSet: .digits, uppercases: true, length: 6), "123456")
        XCTAssertEqual(KitoCodeField.sanitize(" 12 - 34 ", characterSet: .digits, uppercases: true, length: 4), "1234")
    }

    func testPastedCodeLongerThanTheFieldIsTruncated() {
        XCTAssertEqual(KitoCodeField.sanitize("123456789", characterSet: .digits, uppercases: true, length: 6), "456789")
    }

    /// Typing into an already-full field must replace the last character rather than dropping the
    /// new one: the hidden field appends, so keeping the *last* `length` characters is what makes
    /// the newest digit win.
    func testTypingIntoAFullFieldKeepsTheNewestCharacter() {
        XCTAssertEqual(KitoCodeField.sanitize("1234567", characterSet: .digits, uppercases: true, length: 6), "234567")
    }

    func testBackspaceJustShortensTheCode() {
        XCTAssertEqual(KitoCodeField.sanitize("12345", characterSet: .digits, uppercases: true, length: 6), "12345")
        XCTAssertEqual(KitoCodeField.sanitize("", characterSet: .digits, uppercases: true, length: 6), "")
    }

    func testAlphanumericKeepsLettersAndUppercasesThem() {
        XCTAssertEqual(KitoCodeField.sanitize("ab3-d", characterSet: .alphanumeric, uppercases: true, length: 6), "AB3D")
    }

    func testUppercasingCanBeTurnedOff() {
        XCTAssertEqual(KitoCodeField.sanitize("ab3d", characterSet: .alphanumeric, uppercases: false, length: 6), "ab3d")
    }

    func testCustomCharacterSet() {
        let hex = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
        XCTAssertEqual(KitoCodeField.sanitize("1f-9z-A", characterSet: .custom(hex), uppercases: true, length: 6), "1F9A")
    }

    func testCustomCharacterSetCanKeepLowercase() {
        let hex = CharacterSet(charactersIn: "0123456789abcdef")
        XCTAssertEqual(KitoCodeField.sanitize("1f9a", characterSet: .custom(hex), uppercases: false, length: 6), "1f9a")
    }
}

final class KitoCodeActiveBoxTests: XCTestCase {
    func testNothingIsActiveWhileUnfocused() {
        for index in 0..<6 {
            XCTAssertFalse(KitoCodeField.isActiveBox(index: index, characterCount: 3, length: 6, isFocused: false))
        }
    }

    func testTheNextEmptyBoxIsActive() {
        XCTAssertTrue(KitoCodeField.isActiveBox(index: 3, characterCount: 3, length: 6, isFocused: true))
        XCTAssertFalse(KitoCodeField.isActiveBox(index: 2, characterCount: 3, length: 6, isFocused: true))
        XCTAssertFalse(KitoCodeField.isActiveBox(index: 4, characterCount: 3, length: 6, isFocused: true))
    }

    /// Backspacing from 4 entered digits to 3 moves the active box back one, with no separate
    /// cursor state to keep in sync.
    func testBackspaceMovesTheActiveBoxToThePreviousOne() {
        XCTAssertTrue(KitoCodeField.isActiveBox(index: 4, characterCount: 4, length: 6, isFocused: true))
        XCTAssertTrue(KitoCodeField.isActiveBox(index: 3, characterCount: 3, length: 6, isFocused: true))
    }

    func testAFullFieldKeepsTheLastBoxActive() {
        XCTAssertTrue(KitoCodeField.isActiveBox(index: 5, characterCount: 6, length: 6, isFocused: true))
        XCTAssertFalse(KitoCodeField.isActiveBox(index: 4, characterCount: 6, length: 6, isFocused: true))
    }
}

final class KitoCodeDistributionTests: XCTestCase {
    /// Six 58pt boxes don't fit an iPhone SE's width at full size; `.fill` shrinks them instead of
    /// running off the screen.
    func testSixWideBoxesShrinkToFitASmallPhone() {
        let width = KitoCodeField.resolvedBoxWidth(availableWidth: 343, boxCount: 6, separatorCount: 0, spacing: 10, nominalBoxWidth: 58, minimumBoxWidth: 32)
        XCTAssertLessThan(width, 58)
        XCTAssertGreaterThanOrEqual(width, 32)
        XCTAssertLessThanOrEqual(width * 6 + 10 * 5, 343.5, "the whole row must fit the available width")
    }

    func testBoxesNeverGrowPastTheirNominalWidth() {
        let width = KitoCodeField.resolvedBoxWidth(availableWidth: 1000, boxCount: 6, separatorCount: 0, spacing: 10, nominalBoxWidth: 46, minimumBoxWidth: 32)
        XCTAssertEqual(width, 46)
    }

    func testShrinkingStopsAtTheMinimum() {
        let width = KitoCodeField.resolvedBoxWidth(availableWidth: 120, boxCount: 6, separatorCount: 0, spacing: 10, nominalBoxWidth: 58, minimumBoxWidth: 32)
        XCTAssertEqual(width, 32)
    }

    func testSeparatorsTakeTheirShareOfTheWidth() {
        let without = KitoCodeField.resolvedBoxWidth(availableWidth: 300, boxCount: 6, separatorCount: 0, spacing: 10, nominalBoxWidth: 58, minimumBoxWidth: 20)
        let with = KitoCodeField.resolvedBoxWidth(availableWidth: 300, boxCount: 6, separatorCount: 1, spacing: 10, nominalBoxWidth: 58, minimumBoxWidth: 20)
        XCTAssertLessThan(with, without)
    }

    func testDegenerateWidthsFallBackSafely() {
        XCTAssertEqual(KitoCodeField.resolvedBoxWidth(availableWidth: 0, boxCount: 6, separatorCount: 0, spacing: 10, nominalBoxWidth: 46, minimumBoxWidth: 32), 46)
        XCTAssertEqual(KitoCodeField.resolvedBoxWidth(availableWidth: 20, boxCount: 6, separatorCount: 0, spacing: 10, nominalBoxWidth: 46, minimumBoxWidth: 32), 32)
    }

    func testDistributionAndAlignmentDefaults() {
        let field = KitoCodeField(code: .constant(""), length: 6)
        XCTAssertEqual(field.distributionValue, .fixedSpacing)
        XCTAssertEqual(field.alignmentValue, .center)
        XCTAssertEqual(field.minimumBoxWidthValue, 32)
    }

    func testDistributionAndAlignmentAreStored() {
        let field = KitoCodeField(code: .constant(""), length: 6)
            .distribution(.fill)
            .alignment(.leading)
            .minimumBoxWidth(40)
        XCTAssertEqual(field.distributionValue, .fill)
        XCTAssertEqual(field.alignmentValue, .leading)
        XCTAssertEqual(field.minimumBoxWidthValue, 40)
    }
}

final class KitoCodeDynamicTypeTests: XCTestCase {
    func testStandardAndSmallerSizesDoNotGrowTheBoxes() {
        XCTAssertEqual(KitoCodeField.dynamicTypeScaleFactor(for: .large), 1)
        XCTAssertEqual(KitoCodeField.dynamicTypeScaleFactor(for: .medium), 1)
        XCTAssertEqual(KitoCodeField.dynamicTypeScaleFactor(for: .xSmall), 1)
    }

    func testLargerSizesGrowTheBoxes() {
        XCTAssertGreaterThan(KitoCodeField.dynamicTypeScaleFactor(for: .xLarge), 1)
        XCTAssertGreaterThan(KitoCodeField.dynamicTypeScaleFactor(for: .accessibility1), KitoCodeField.dynamicTypeScaleFactor(for: .xLarge))
    }

    func testGrowthIsCappedAtThirtyPercent() {
        XCTAssertEqual(KitoCodeField.dynamicTypeScaleFactor(for: .accessibility5), 1.3)
        XCTAssertLessThanOrEqual(KitoCodeField.dynamicTypeScaleFactor(for: .accessibility3), 1.3)
    }
}

final class KitoCodeBoxStateStylingTests: XCTestCase {
    func testErrorBoxOverridesTheThemeErrorChrome() {
        let theme = KitoFieldTheme()
        let appearance = KitoCodeField.boxAppearance(
            hasError: true, hasValue: true, isActive: true, baseFill: .white,
            filledFill: nil, filledBorderColor: nil, filledBorderWidth: nil, filledShadow: nil,
            theme: theme,
            errorFill: .pink, errorBorderColor: .purple, errorBorderWidth: 4
        )
        XCTAssertEqual(appearance.fill, .pink)
        XCTAssertEqual(appearance.borderColor, .purple)
        XCTAssertEqual(appearance.borderWidth, 4)
    }

    func testActiveBoxBeatsFilledWhenBothAreSet() {
        let theme = KitoFieldTheme()
        let appearance = KitoCodeField.boxAppearance(
            hasError: false, hasValue: true, isActive: true, baseFill: .white,
            filledFill: .green, filledBorderColor: .green, filledBorderWidth: 3, filledShadow: nil,
            theme: theme,
            activeFill: .yellow, activeBorderColor: .orange, activeBorderWidth: 5
        )
        XCTAssertEqual(appearance.fill, .yellow)
        XCTAssertEqual(appearance.borderColor, .orange)
        XCTAssertEqual(appearance.borderWidth, 5)
    }

    func testActiveBoxDoesNotAffectInactiveBoxes() {
        let theme = KitoFieldTheme()
        let appearance = KitoCodeField.boxAppearance(
            hasError: false, hasValue: true, isActive: false, baseFill: .white,
            filledFill: .green, filledBorderColor: nil, filledBorderWidth: nil, filledShadow: nil,
            theme: theme,
            activeFill: .yellow, activeBorderColor: .orange
        )
        XCTAssertEqual(appearance.fill, .green, "an inactive filled box keeps the filled override")
        XCTAssertEqual(appearance.borderColor, theme.borderColor)
    }

    func testSuccessRecoloursTheBorderAndBeatsActive() {
        let theme = KitoFieldTheme()
        let appearance = KitoCodeField.boxAppearance(
            hasError: false, hasValue: true, isActive: true, baseFill: .white,
            filledFill: nil, filledBorderColor: nil, filledBorderWidth: nil, filledShadow: nil,
            theme: theme,
            isSuccess: true
        )
        XCTAssertEqual(appearance.borderColor, theme.successColor)
    }

    func testSuccessUsesTheThemeSuccessBorderColorWhenSet() {
        var theme = KitoFieldTheme()
        theme.successBorderColor = .mint
        let appearance = KitoCodeField.boxAppearance(
            hasError: false, hasValue: false, isActive: false, baseFill: .white,
            filledFill: nil, filledBorderColor: nil, filledBorderWidth: nil, filledShadow: nil,
            theme: theme,
            isSuccess: true, successBorderColor: theme.successBorderColor
        )
        XCTAssertEqual(appearance.borderColor, .mint)
    }

    func testErrorStillBeatsSuccess() {
        let theme = KitoFieldTheme()
        let appearance = KitoCodeField.boxAppearance(
            hasError: true, hasValue: true, isActive: false, baseFill: .white,
            filledFill: nil, filledBorderColor: nil, filledBorderWidth: nil, filledShadow: nil,
            theme: theme,
            isSuccess: true
        )
        XCTAssertEqual(appearance.borderColor, theme.errorColor)
    }

    func testFilledPresetDropsTheIdleBorder() {
        let theme = KitoFieldTheme()
        let idle = KitoCodeField.boxAppearance(
            hasError: false, hasValue: false, isActive: false, baseFill: .white,
            filledFill: nil, filledBorderColor: nil, filledBorderWidth: nil, filledShadow: nil,
            theme: theme,
            presetBorderWidth: 0
        )
        XCTAssertEqual(idle.borderWidth, 0)

        let active = KitoCodeField.boxAppearance(
            hasError: false, hasValue: false, isActive: true, baseFill: .white,
            filledFill: nil, filledBorderColor: nil, filledBorderWidth: nil, filledShadow: nil,
            theme: theme,
            presetBorderWidth: 0
        )
        XCTAssertEqual(active.borderWidth, theme.focusedBorderWidth, "a focused box still shows its border under the filled preset")
    }
}

final class KitoCodeFieldConfigurationTests: XCTestCase {
    func testDefaults() {
        let field = KitoCodeField(code: .constant(""), length: 6)
        XCTAssertEqual(field.boxStylePreset, .outlined)
        XCTAssertNil(field.boxShapeOverride)
        XCTAssertNil(field.digitColorFilled)
        XCTAssertNil(field.digitColorActive)
        XCTAssertEqual(field.characterSetValue, .digits)
        XCTAssertTrue(field.uppercasesValue)
        XCTAssertFalse(field.selectAllOnFocusValue)
        XCTAssertNil(field.revealLastEnteredDuration)
        XCTAssertEqual(field.maskCharacterValue, "●")
        XCTAssertEqual(field.successAnimationValue, .none)
        XCTAssertNil(field.customStyle)
        XCTAssertFalse(field.hapticsOnDigit)
        XCTAssertFalse(field.hapticsOnComplete)
        XCTAssertFalse(field.hapticsOnError)
        XCTAssertNil(field.activeFill)
        XCTAssertNil(field.errorFill)
    }

    func testStateStylingIsStored() {
        let field = KitoCodeField(code: .constant(""), length: 6)
            .activeBox(fill: .yellow, borderColor: .orange, borderWidth: 3, shadow: KitoShadow())
            .errorBox(fill: .pink, borderColor: .purple)
        XCTAssertEqual(field.activeFill, .yellow)
        XCTAssertEqual(field.activeBorderColor, .orange)
        XCTAssertEqual(field.activeBorderWidth, 3)
        XCTAssertNotNil(field.activeShadow)
        XCTAssertEqual(field.errorFill, .pink)
        XCTAssertEqual(field.errorBorderColor, .purple)
        XCTAssertNil(field.errorBorderWidth)
    }

    func testBoxStyleAndShapeAreStored() {
        let underline = KitoCodeField(code: .constant(""), length: 6).boxStyle(.underline)
        XCTAssertEqual(underline.boxStylePreset, .underline)

        let shaped = KitoCodeField(code: .constant(""), length: 6).boxShape(.capsule)
        XCTAssertEqual(shaped.boxShapeOverride, .capsule)
    }

    func testDigitColorsAreStored() {
        let field = KitoCodeField(code: .constant(""), length: 6).digitColor(filled: .blue, active: .red)
        XCTAssertEqual(field.digitColorFilled, .blue)
        XCTAssertEqual(field.digitColorActive, .red)
    }

    func testCharacterSetAndUppercasing() {
        let hex = CharacterSet(charactersIn: "0123456789ABCDEF")
        let field = KitoCodeField(code: .constant(""), length: 6)
            .characterSet(.custom(hex))
            .uppercases(false)
        XCTAssertEqual(field.characterSetValue, .custom(hex))
        XCTAssertFalse(field.uppercasesValue)
    }

    /// `.alphanumeric()` predates `.characterSet(_:)` and must keep behaving the same.
    func testAlphanumericShorthandStillMapsOntoTheCharacterSet() {
        XCTAssertEqual(KitoCodeField(code: .constant(""), length: 6).alphanumeric().characterSetValue, .alphanumeric)
        XCTAssertEqual(KitoCodeField(code: .constant(""), length: 6).alphanumeric(false).characterSetValue, .digits)
    }

    func testSecureEntryOptionsAreStored() {
        let field = KitoCodeField(code: .constant(""), length: 6)
            .secure()
            .revealLastEntered(for: 0.8)
            .maskCharacter("•")
        XCTAssertEqual(field.revealLastEnteredDuration, 0.8)
        XCTAssertEqual(field.maskCharacterValue, "•")
    }

    func testSelectAllOnFocusIsStored() {
        XCTAssertTrue(KitoCodeField(code: .constant(""), length: 6).selectAllOnFocus().selectAllOnFocusValue)
    }

    func testSuccessAndHapticsAreStored() {
        let field = KitoCodeField(code: .constant(""), length: 6)
            .successAnimation(.tick)
            .haptics(onDigit: true, onComplete: true, onError: true)
        XCTAssertEqual(field.successAnimationValue, .tick)
        XCTAssertTrue(field.hapticsOnDigit)
        XCTAssertTrue(field.hapticsOnComplete)
        XCTAssertTrue(field.hapticsOnError)
    }

    func testCustomStyleIsStored() {
        let field = KitoCodeField(code: .constant(""), length: 6).style(KitoCodePillBoxStyle())
        XCTAssertNotNil(field.customStyle)
    }
}
