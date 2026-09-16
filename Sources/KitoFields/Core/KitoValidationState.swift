//
//  KitoValidationState.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// Result of running validation rules against a field's value.
public enum KitoValidationState: Equatable, Sendable {
    /// No rules configured, or validation has not yet run.
    case idle
    case valid
    case invalid([String])

    public var isValid: Bool {
        switch self {
        case .valid, .idle: return true
        case .invalid: return false
        }
    }

    public var errors: [String] {
        if case .invalid(let errors) = self { return errors }
        return []
    }
}

/// When a field reveals validation results to the user.
public enum KitoValidationTrigger: Sendable, Equatable {
    /// Immediately as the user types (after the first edit).
    case live
    /// After the field loses focus for the first time (and thereafter live).
    case onBlur
    /// Only after the user submits (Return key) or you set an external error.
    case onSubmit
    /// Never show rule errors automatically; only externally supplied error text is shown.
    case never
}

/// Tracks the interaction milestones that gate when errors become visible.
struct KitoValidationPresentation: Equatable {
    var hasEdited = false
    var hasBlurred = false
    var hasSubmitted = false

    mutating func didEdit() { hasEdited = true }
    mutating func didBlur() { if hasEdited { hasBlurred = true } }
    mutating func didSubmit() { hasSubmitted = true }
    mutating func reset() { self = KitoValidationPresentation() }

    func shouldShowErrors(for trigger: KitoValidationTrigger) -> Bool {
        switch trigger {
        case .live: return hasEdited || hasSubmitted
        case .onBlur: return hasBlurred || hasSubmitted
        case .onSubmit: return hasSubmitted
        case .never: return false
        }
    }
}
