//
//  KitoFormControllerTests.swift
//  KitoFieldsTests
//
//  Created by Wycliff Njenga on 18/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import XCTest
import SwiftUI
@testable import KitoFields

final class KitoFormControllerTests: XCTestCase {
    @MainActor
    func testValidateFocusesFirstInvalidInRegistrationOrder() {
        let form = KitoFormController()
        var focusedA = false
        var focusedB = false
        let a = form.bindings(for: "a", focus: { focusedA = true })
        let b = form.bindings(for: "b", focus: { focusedB = true })

        a.isValid.wrappedValue = true
        b.isValid.wrappedValue = false

        XCTAssertFalse(form.isValid)
        XCTAssertFalse(form.validate())
        XCTAssertFalse(focusedA, "a is valid; it should not receive focus")
        XCTAssertTrue(focusedB, "b is the only invalid field; it should receive focus")
    }

    @MainActor
    func testFirstInvalidWinsEvenWhenLaterFieldsAlsoFail() {
        let form = KitoFormController()
        var focused: [String] = []
        let a = form.bindings(for: "a", focus: { focused.append("a") })
        let b = form.bindings(for: "b", focus: { focused.append("b") })

        a.isValid.wrappedValue = false
        b.isValid.wrappedValue = false

        XCTAssertFalse(form.validate())
        XCTAssertEqual(focused, ["a"], "only the first invalid field in registration order should be focused")
    }

    @MainActor
    func testValidateReturnsTrueWhenEveryFieldIsValid() {
        let form = KitoFormController()
        let a = form.bindings(for: "a", focus: {})
        let b = form.bindings(for: "b", focus: {})
        a.isValid.wrappedValue = true
        b.isValid.wrappedValue = true

        XCTAssertTrue(form.isValid)
        XCTAssertTrue(form.validate())
    }

    @MainActor
    func testRevealTriggerIncrementsSoFieldsCanRevealTheirErrors() {
        let form = KitoFormController()
        let a = form.bindings(for: "a", focus: {})
        let before = a.revealTrigger.wrappedValue
        form.validate()
        XCTAssertNotEqual(a.revealTrigger.wrappedValue, before)
    }

    @MainActor
    func testResetClearsRecordedInvalidity() {
        let form = KitoFormController()
        let a = form.bindings(for: "a", focus: {})
        a.isValid.wrappedValue = false
        XCTAssertFalse(form.isValid)
        form.reset()
        XCTAssertTrue(form.isValid)
    }

    @MainActor
    func testRegisteringTheSameIDTwiceDoesNotDuplicateOrder() {
        let form = KitoFormController()
        var focusCount = 0
        _ = form.bindings(for: "a", focus: { focusCount += 1 })
        let second = form.bindings(for: "a", focus: { focusCount += 1 })
        second.isValid.wrappedValue = false
        form.validate()
        XCTAssertEqual(focusCount, 1, "re-registering the same id should replace, not add, the focus action")
    }
}
