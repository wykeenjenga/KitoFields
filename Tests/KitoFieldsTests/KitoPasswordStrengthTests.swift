//
//  KitoPasswordStrengthTests.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import XCTest
@testable import KitoFields

final class PasswordStrengthTests: XCTestCase {
    let evaluator = KitoPasswordStrengthEvaluator()

    func testBuckets() {
        XCTAssertEqual(evaluator.evaluate(""), .veryWeak)
        XCTAssertEqual(evaluator.evaluate("password"), .veryWeak)
        XCTAssertEqual(evaluator.evaluate("123456"), .veryWeak)
        XCTAssertEqual(evaluator.evaluate("abcdefgh"), .veryWeak)      // sequential
        XCTAssertEqual(evaluator.evaluate("aaaaaaaa"), .veryWeak)      // repetition
        XCTAssertLessThanOrEqual(evaluator.evaluate("kitten12"), .fair)
        XCTAssertGreaterThanOrEqual(evaluator.evaluate("Kitten!2024"), .strong)
        XCTAssertEqual(evaluator.evaluate("Tr0ub4dor&3xtraLong!"), .veryStrong)
    }

    func testMonotonicWithComplexity() {
        let weak = evaluator.evaluate("hello")
        let better = evaluator.evaluate("Hello123")
        let best = evaluator.evaluate("Hello123!@#xyz")
        XCTAssertLessThan(weak, better)
        XCTAssertLessThanOrEqual(better, best)
    }

    func testSegmentsAndLabels() {
        XCTAssertEqual(KitoPasswordStrength.veryWeak.segments, 0)
        XCTAssertEqual(KitoPasswordStrength.veryStrong.segments, 4)
        XCTAssertEqual(KitoPasswordStrength.allCases.count, 5)
    }
}
