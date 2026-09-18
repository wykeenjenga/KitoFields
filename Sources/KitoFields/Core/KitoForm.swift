//
//  KitoForm.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 18/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// Coordinates a group of KitoFields so a submit button can validate every field at once and
/// jump focus to the first one that fails, instead of the app tracking each field's validity by hand.
///
/// ```swift
/// @StateObject private var form = KitoFormController()
/// @FocusState private var focus: Field?
///
/// KitoEmailField(text: $email)
///     .required()
///     .kitoFormField("email", form: form, focus: $focus, equals: .email)
///
/// KitoPasswordField(text: $password)
///     .required()
///     .kitoFormField("password", form: form, focus: $focus, equals: .password)
///
/// KitoButton("Continue") {
///     guard form.validate() else { return }
///     submit()
/// }
/// ```
///
/// Fields register themselves the first time their `.kitoFormField(...)` modifier is evaluated, in
/// the order they appear on screen, and report their own validity continuously (the same value
/// `.isValid(_:)` would report). `validate()` never re-runs your validation rules itself; it only
/// asks each already-registered field to reveal what it already knows.
@MainActor
public final class KitoFormController: ObservableObject {
    private var order: [AnyHashable] = []
    private var validity: [AnyHashable: Bool] = [:]
    private var focusActions: [AnyHashable: () -> Void] = [:]

    /// Bumped on every `validate()` call; fields observe this to reveal their errors on demand.
    @Published private var revealTick = 0

    public init() {}

    /// Whether every registered field currently reports itself valid. Updates live as the user
    /// types; does not reveal any field's errors or move focus.
    public var isValid: Bool {
        order.allSatisfy { validity[$0] != false }
    }

    /// Reveals every registered field's errors and, if any are invalid, moves focus to the first
    /// one (in the order fields appeared on screen). Returns whether the form was already valid.
    @discardableResult
    public func validate() -> Bool {
        revealTick += 1
        guard let firstInvalid = order.first(where: { validity[$0] == false }) else { return true }
        focusActions[firstInvalid]?()
        return false
    }

    /// Clears every field's recorded validity back to "not yet known to be invalid" (a fresh form).
    /// Does not touch the fields' own text/selection — clear those bindings yourself.
    public func reset() {
        validity = validity.mapValues { _ in true }
    }

    /// Used by `.kitoFormField(...)`; registers `id` the first time it's seen and returns the
    /// bindings that modifier wires into the field's options.
    func bindings<ID: Hashable>(for id: ID, focus: @escaping () -> Void) -> (isValid: Binding<Bool>, revealTrigger: Binding<Int>) {
        let anyID = AnyHashable(id)
        if !order.contains(anyID) { order.append(anyID) }
        if validity[anyID] == nil { validity[anyID] = true }
        focusActions[anyID] = focus

        let isValid = Binding<Bool>(
            get: { [weak self] in self?.validity[anyID] ?? true },
            set: { [weak self] in self?.validity[anyID] = $0 }
        )
        let reveal = Binding<Int>(get: { [weak self] in self?.revealTick ?? 0 }, set: { _ in })
        return (isValid, reveal)
    }
}
