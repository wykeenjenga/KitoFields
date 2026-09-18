//
//  KitoResendCodeButtonTests.swift
//  KitoFieldsTests
//
//  Created by Wycliff Njenga on 18/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import XCTest
import SwiftUI
@testable import KitoFields

final class KitoResendCodeButtonTests: XCTestCase {
    func testStartsEnabledByDefault() {
        XCTAssertEqual(KitoResendCodeButton.seedRemaining(cooldown: 30, startsDisabled: false), 0)
    }

    func testStartsDisabledSeedsWholeSecondsFromCooldown() {
        XCTAssertEqual(KitoResendCodeButton.seedRemaining(cooldown: 30, startsDisabled: true), 30)
    }

    func testFractionalCooldownRoundsUp() {
        // 12.4s should still read as a full 13s remaining, never a moment short of the promise.
        XCTAssertEqual(KitoResendCodeButton.seedRemaining(cooldown: 12.4, startsDisabled: true), 13)
    }

    @MainActor
    func testFluentModifiersReturnAConfiguredCopy() {
        var calls = 0
        let styled = KitoResendCodeButton(cooldown: 30) { calls += 1 }
            .font(.footnote)
            .tint(.blue)
            .disabledTint(.gray)
        _ = styled
        XCTAssertEqual(calls, 0, "constructing and styling the view must not itself invoke the action")
    }
}
