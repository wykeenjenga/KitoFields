//
//  KitoCodeFieldTests.swift
//  KitoFieldsTests
//
//  Created by Wycliff Njenga on 22/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import XCTest
import SwiftUI
@testable import KitoFields

final class KitoCodeFieldTests: XCTestCase {
    func testFilledBoxStoresEachValueAndLeavesUnsetOnesNil() {
        let full = KitoCodeField(code: .constant(""), length: 4)
            .filledBox(fill: .white, borderColor: .blue, borderWidth: 2, shadow: KitoShadow())
        XCTAssertEqual(full.filledFill, .white)
        XCTAssertEqual(full.filledBorderColor, .blue)
        XCTAssertEqual(full.filledBorderWidth, 2)
        XCTAssertNotNil(full.filledShadow)

        let partial = KitoCodeField(code: .constant(""), length: 4).filledBox(fill: .white)
        XCTAssertEqual(partial.filledFill, .white)
        XCTAssertNil(partial.filledBorderColor)
        XCTAssertNil(partial.filledBorderWidth)
        XCTAssertNil(partial.filledShadow)

        let none = KitoCodeField(code: .constant(""), length: 4)
        XCTAssertNil(none.filledFill)
        XCTAssertNil(none.filledBorderColor)
        XCTAssertNil(none.filledBorderWidth)
        XCTAssertNil(none.filledShadow)
    }

    func testErrorBeatsFilledAndActive() {
        let theme = KitoFieldTheme()
        let appearance = KitoCodeField.boxAppearance(
            hasError: true, hasValue: true, isActive: true,
            baseFill: .white,
            filledFill: .green, filledBorderColor: .green, filledBorderWidth: 3, filledShadow: KitoShadow(),
            theme: theme
        )
        XCTAssertEqual(appearance.borderColor, theme.errorColor)
        XCTAssertEqual(appearance.borderWidth, theme.focusedBorderWidth)
        XCTAssertEqual(appearance.fill, .white, "error must not apply the filled fill override")
        XCTAssertEqual(appearance.shadow, theme.shadow)
    }

    func testFilledBeatsActiveWhenOverridesAreSet() {
        let theme = KitoFieldTheme()
        let filledActive = KitoCodeField.boxAppearance(
            hasError: false, hasValue: true, isActive: true,
            baseFill: .white,
            filledFill: .green, filledBorderColor: .green, filledBorderWidth: 3, filledShadow: nil,
            theme: theme
        )
        XCTAssertEqual(filledActive.fill, .green)
        XCTAssertEqual(filledActive.borderColor, .green, "an explicit filled override must win over the active/focus border")
        XCTAssertEqual(filledActive.borderWidth, 3)
    }

    func testActiveBeatsIdleWhenNoFilledOverrideIsSet() {
        let theme = KitoFieldTheme()
        let active = KitoCodeField.boxAppearance(
            hasError: false, hasValue: false, isActive: true,
            baseFill: .white,
            filledFill: nil, filledBorderColor: nil, filledBorderWidth: nil, filledShadow: nil,
            theme: theme
        )
        XCTAssertEqual(active.borderColor, theme.focusedBorderColor)
        XCTAssertEqual(active.borderWidth, theme.focusedBorderWidth)
    }

    func testIdleWhenNothingElseApplies() {
        let theme = KitoFieldTheme()
        let idle = KitoCodeField.boxAppearance(
            hasError: false, hasValue: false, isActive: false,
            baseFill: .white,
            filledFill: nil, filledBorderColor: nil, filledBorderWidth: nil, filledShadow: nil,
            theme: theme
        )
        XCTAssertEqual(idle.borderColor, theme.borderColor)
        XCTAssertEqual(idle.borderWidth, theme.borderWidth)
        XCTAssertEqual(idle.fill, .white)
    }

    /// A filled box with no `filledBox(...)` override at all must resolve exactly as it did
    /// before this feature existed — active beats idle, same as the pre-existing formula.
    func testFilledWithNoOverrideRendersIdenticallyToPreExistingBehavior() {
        let theme = KitoFieldTheme()
        let filledNoOverrideActive = KitoCodeField.boxAppearance(
            hasError: false, hasValue: true, isActive: true,
            baseFill: .white,
            filledFill: nil, filledBorderColor: nil, filledBorderWidth: nil, filledShadow: nil,
            theme: theme
        )
        XCTAssertEqual(filledNoOverrideActive.borderColor, theme.focusedBorderColor)
        XCTAssertEqual(filledNoOverrideActive.borderWidth, theme.focusedBorderWidth)

        let filledNoOverrideIdle = KitoCodeField.boxAppearance(
            hasError: false, hasValue: true, isActive: false,
            baseFill: .white,
            filledFill: nil, filledBorderColor: nil, filledBorderWidth: nil, filledShadow: nil,
            theme: theme
        )
        XCTAssertEqual(filledNoOverrideIdle.borderColor, theme.borderColor)
        XCTAssertEqual(filledNoOverrideIdle.borderWidth, theme.borderWidth)
    }
}
