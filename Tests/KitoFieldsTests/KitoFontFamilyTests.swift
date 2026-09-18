//
//  KitoFontFamilyTests.swift
//  KitoFieldsTests
//
//  Created by Wycliff Njenga on 18/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import XCTest
import SwiftUI
@testable import KitoFields

final class KitoFontFamilyTests: XCTestCase {
    private let brand = KitoFontFamily(regular: "Inter-Regular", medium: "Inter-Medium", semibold: "Inter-SemiBold", bold: "Inter-Bold")

    func testEachWeightResolvesItsOwnName() {
        XCTAssertEqual(brand.name(for: .regular), "Inter-Regular")
        XCTAssertEqual(brand.name(for: .medium), "Inter-Medium")
        XCTAssertEqual(brand.name(for: .semibold), "Inter-SemiBold")
        XCTAssertEqual(brand.name(for: .bold), "Inter-Bold")
    }

    func testMissingWeightsFallBackProgressivelyTowardRegular() {
        let sparse = KitoFontFamily(regular: "Brand-Regular")
        XCTAssertEqual(sparse.name(for: .medium), "Brand-Regular")
        XCTAssertEqual(sparse.name(for: .semibold), "Brand-Regular")
        XCTAssertEqual(sparse.name(for: .bold), "Brand-Regular")

        let mediumOnly = KitoFontFamily(regular: "Brand-Regular", medium: "Brand-Medium")
        XCTAssertEqual(mediumOnly.name(for: .semibold), "Brand-Medium", "semibold should prefer medium over regular when semibold/bold are missing")
        XCTAssertEqual(mediumOnly.name(for: .bold), "Brand-Medium")
    }

    func testHeavyAndBlackWeightsMapToBold() {
        XCTAssertEqual(brand.name(for: .heavy), "Inter-Bold")
        XCTAssertEqual(brand.name(for: .black), "Inter-Bold")
    }

    /// Regression: `KitoFieldTheme.default` must be a mutable, re-read-every-time fallback (not a
    /// `static let` snapshot) so setting it once at launch — before any field's environment is
    /// first read — reaches every field that doesn't have an explicit `.kitoFieldTheme(...)`.
    @MainActor
    func testSettingTheGlobalDefaultChangesWhatNewFieldsFallBackTo() {
        let original = KitoFieldTheme.default
        defer { KitoFieldTheme.default = original }

        KitoFieldTheme.default = .custom(brand)
        XCTAssertEqual(KitoFieldTheme.default.font, brand.font(size: 17, relativeTo: .body))
    }

    func testCustomBuilderSetsEveryTextRole() {
        let theme = KitoFieldTheme.custom(brand)
        XCTAssertEqual(theme.font, brand.font(size: 17, relativeTo: .body))
        XCTAssertEqual(theme.labelFont, brand.font(size: 15, weight: .medium, relativeTo: .subheadline))
        XCTAssertEqual(theme.helperFont, brand.font(size: 12, relativeTo: .caption))
        XCTAssertEqual(theme.errorFont, brand.font(size: 13, relativeTo: .footnote))
    }

    func testCustomBuilderPreservesABaseThemesNonFontTokens() {
        let theme = KitoFieldTheme.custom(brand, base: .capsule)
        XCTAssertEqual(theme.shape, KitoFieldShape.capsule)
        XCTAssertEqual(theme.font, brand.font(size: 17, relativeTo: .body))
    }
}
