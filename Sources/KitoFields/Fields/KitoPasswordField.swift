//
//  KitoPasswordField.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// Secure entry with a reveal toggle, optional strength meter and requirement checklist.
///
/// ```swift
/// KitoPasswordField(text: $password)
///     .newPassword()
///     .strengthMeter()
///     .requirements(.strongPassword())
/// ```
public struct KitoPasswordField: View, KitoFieldConfigurable {
    private var base: KitoTextField
    private var animatesLock = false
    @State private var revealedState = false

    public var options: KitoFieldOptions {
        get { base.options }
        set { base.options = newValue }
    }

    public init(_ label: String? = "Password", text: Binding<String>, prompt: String? = "Enter your password") {
        base = KitoTextField(label, text: text, prompt: prompt)
        base.secure = KitoSecureEntryOptions()
        base.options.contentType = .password
        base.options.autocapitalization = .never
        base.options.disablesAutocorrection = true
        base.options.validationTrigger = .onBlur
    }

    public var body: some View {
        if animatesLock {
            var field = base
            if field.secure?.revealedBinding == nil { field.secure?.revealedBinding = $revealedState }
            let open = field.secure?.revealedBinding?.wrappedValue ?? revealedState
            field.options.leading = .animatedSymbol(open ? "lock.open" : "lock", focused: open ? "lock.open.fill" : "lock.fill", error: "lock.trianglebadge.exclamationmark", motion: .wiggle)
            return AnyView(field)
        }
        return AnyView(base)
    }

    /// Leading lock icon that fills on focus, opens when the password is revealed and wiggles on error.
    public func animatedLockIcon(_ enabled: Bool = true) -> KitoPasswordField { var c = self; c.animatesLock = enabled; return c }

    private func mutatingSecure(_ change: (inout KitoSecureEntryOptions) -> Void) -> KitoPasswordField {
        var copy = self
        var secure = copy.base.secure ?? KitoSecureEntryOptions()
        change(&secure)
        copy.base.secure = secure
        return copy
    }

    /// Shows/hides the eye button.
    public func revealable(_ enabled: Bool = true) -> KitoPasswordField { mutatingSecure { $0.revealable = enabled } }

    /// Drives the revealed state from outside (e.g. one toggle for two fields).
    public func revealed(_ binding: Binding<Bool>) -> KitoPasswordField { mutatingSecure { $0.revealedBinding = binding } }

    /// Four-segment strength bar under the field.
    public func strengthMeter(_ enabled: Bool = true, evaluator: KitoPasswordStrengthEvaluator = KitoPasswordStrengthEvaluator()) -> KitoPasswordField {
        mutatingSecure { $0.showsStrengthMeter = enabled; $0.strengthEvaluator = evaluator }
    }

    /// Rules that must pass, rendered as a live checklist (and enforced as validation).
    public func requirements(_ rules: [KitoRule], showsChecklist: Bool = true) -> KitoPasswordField {
        mutatingSecure { $0.requirements = rules; $0.showsRequirementChecklist = showsChecklist }
    }

    /// Full control of the strength meter and requirement checklist: styles, icons, colours,
    /// labels, order, hide-when-met, custom scoring. See `KitoPasswordUIConfiguration`.
    public func passwordUI(_ configure: @escaping (inout KitoPasswordUIConfiguration) -> Void) -> KitoPasswordField {
        mutatingSecure { configure(&$0.ui) }
    }

    /// Shortcut for `passwordUI { $0.checklistStyle = style }`.
    public func checklistStyle(_ style: KitoChecklistStyle) -> KitoPasswordField { mutatingSecure { $0.ui.checklistStyle = style } }
    /// Shortcut for `passwordUI { $0.meterStyle = style }`.
    public func meterStyle(_ style: KitoStrengthMeterStyle) -> KitoPasswordField { mutatingSecure { $0.ui.meterStyle = style } }

    /// Hints autofill to generate/save a new password (sign-up flows).
    public func newPassword() -> KitoPasswordField {
        var copy = self
        copy.base.options.contentType = .newPassword
        return copy
    }

    /// Confirm-password helper: fails while the value differs from the other field's binding.
    ///
    /// ```swift
    /// KitoPasswordField("Confirm password", text: $confirm).mustMatch($password)
    /// ```
    public func mustMatch(_ other: Binding<String>, message: String = KitoLocalization.string("password.mismatch", "Passwords do not match")) -> KitoPasswordField {
        mustMatch({ other.wrappedValue }, message: message)
    }

    /// Confirm-password helper with a custom source of truth, evaluated at validation time.
    public func mustMatch(_ other: @escaping () -> String, message: String = KitoLocalization.string("password.mismatch", "Passwords do not match")) -> KitoPasswordField {
        var copy = self
        copy.base.options.rules.append(.matches(other, message: message))
        return copy
    }
}
