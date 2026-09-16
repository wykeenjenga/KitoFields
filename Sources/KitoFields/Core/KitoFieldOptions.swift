//
//  KitoFieldOptions.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// Platform-neutral keyboard choice (maps to `UIKeyboardType` on iOS, ignored on macOS).
public enum KitoKeyboard: Sendable {
    case `default`, asciiCapable, numbersAndPunctuation, url, numberPad, phonePad, namePhonePad, emailAddress, decimalPad, webSearch
}

/// Platform-neutral content type hint for autofill.
public enum KitoContentType: Sendable {
    case none, name, givenName, familyName, username, emailAddress, password, newPassword, oneTimeCode, telephoneNumber, url, streetAddress, postalCode, creditCardNumber
}

public enum KitoAutocapitalization: Sendable {
    case never, words, sentences, characters
}

/// Options common to every KitoFields field. Configure through the fluent modifiers in
/// `KitoFieldConfigurable` rather than touching this directly.
public struct KitoFieldOptions {
    public var label: String?
    public var placeholder: String?
    public var helperText: String?
    /// Error supplied by you (e.g. from a server). Always shown when non-nil.
    public var externalError: String?
    public var leading: KitoAccessory?
    public var trailing: KitoAccessory?
    public var showsClearButton = false
    public var characterLimit: Int?
    public var showsCharacterCounter = false
    public var rules: [KitoRule] = []
    public var validationTrigger: KitoValidationTrigger = .onBlur
    public var showsSuccessIndicator = false
    public var showsErrorIndicator = true
    public var keyboard: KitoKeyboard = .default
    public var contentType: KitoContentType = .none
    public var autocapitalization: KitoAutocapitalization = .sentences
    public var disablesAutocorrection = false
    public var multilineRange: ClosedRange<Int>?
    public var transform: ((String) -> String)?
    public var focusBinding: Binding<Bool>?
    public var isValidBinding: Binding<Bool>?
    public var onValidationChange: ((KitoValidationState) -> Void)?
    public var onSubmit: (() -> Void)?
    public var onFocusChange: ((Bool) -> Void)?
    public var accessibilityLabel: String?
    /// Marks the field as required: adds a required-indicator to the label and a `.required` rule.
    public var isRequired = false
    public var requiredMessage = "This field is required"

    public init() {}

    /// Rules actually evaluated: the configured rules plus an implicit `.required` rule when
    /// `isRequired` is set and no explicit required rule exists.
    var effectiveRules: [KitoRule] {
        guard isRequired, !rules.contains(where: { $0.id == KitoRule.requiredID }) else { return rules }
        return [.required(message: requiredMessage)] + rules
    }
}

/// Fluent configuration shared by all fields. Every method returns a modified copy.
public protocol KitoFieldConfigurable: View {
    var options: KitoFieldOptions { get set }
}

public extension KitoFieldConfigurable {
    private func mutating(_ change: (inout KitoFieldOptions) -> Void) -> Self {
        var copy = self
        change(&copy.options)
        return copy
    }

    /// Title shown above the field (or floating inside it with the floating-label style).
    func label(_ text: String?) -> Self { mutating { $0.label = text } }
    /// Placeholder shown while empty.
    func placeholder(_ text: String?) -> Self { mutating { $0.placeholder = text } }
    /// Neutral hint shown under the field while there are no errors.
    func helperText(_ text: String?) -> Self { mutating { $0.helperText = text } }
    /// Externally supplied error (server-side validation). Shown regardless of trigger.
    func errorMessage(_ text: String?) -> Self { mutating { $0.externalError = text } }

    /// Marks the field required. Shows the theme's required indicator next to the label and
    /// fails validation while empty.
    func required(_ isRequired: Bool = true, message: String = "This field is required") -> Self {
        mutating { $0.isRequired = isRequired; $0.requiredMessage = message }
    }

    func leadingAccessory(_ accessory: KitoAccessory?) -> Self { mutating { $0.leading = accessory } }
    func trailingAccessory(_ accessory: KitoAccessory?) -> Self { mutating { $0.trailing = accessory } }
    /// Shortcut for a leading SF Symbol.
    func leadingIcon(_ systemName: String) -> Self { leadingAccessory(.systemImage(systemName)) }
    /// Shortcut for a trailing SF Symbol.
    func trailingIcon(_ systemName: String) -> Self { trailingAccessory(.systemImage(systemName)) }

    /// Shows an "x" button that empties the field.
    func clearButton(_ enabled: Bool = true) -> Self { mutating { $0.showsClearButton = enabled } }

    /// Hard limit on length, optionally with a "12 / 50" counter under the field.
    func characterLimit(_ limit: Int?, showsCounter: Bool = false) -> Self {
        mutating { $0.characterLimit = limit; $0.showsCharacterCounter = showsCounter }
    }

    /// Validation rules and when their failures become visible.
    func validation(_ rules: [KitoRule], trigger: KitoValidationTrigger = .onBlur) -> Self {
        mutating { $0.rules = rules; $0.validationTrigger = trigger }
    }
    func validation(_ rules: KitoRule..., trigger: KitoValidationTrigger = .onBlur) -> Self {
        validation(rules, trigger: trigger)
    }
    func validationTrigger(_ trigger: KitoValidationTrigger) -> Self { mutating { $0.validationTrigger = trigger } }

    /// Green check when the value passes every rule; red exclamation on error.
    func validationIndicators(success: Bool = true, error: Bool = true) -> Self {
        mutating { $0.showsSuccessIndicator = success; $0.showsErrorIndicator = error }
    }

    func keyboard(_ keyboard: KitoKeyboard) -> Self { mutating { $0.keyboard = keyboard } }
    func contentType(_ type: KitoContentType) -> Self { mutating { $0.contentType = type } }
    func autocapitalization(_ mode: KitoAutocapitalization) -> Self { mutating { $0.autocapitalization = mode } }
    func autocorrectionDisabled(_ disabled: Bool = true) -> Self { mutating { $0.disablesAutocorrection = disabled } }

    /// Grows vertically between the given line counts (iOS 16 / macOS 13+; single line earlier).
    func multiline(_ lines: ClosedRange<Int> = 1...5) -> Self { mutating { $0.multilineRange = lines } }

    /// Applied to every edit before the value is stored (e.g. `{ $0.lowercased() }`).
    func transform(_ transform: ((String) -> String)?) -> Self { mutating { $0.transform = transform } }

    /// Two-way focus control from outside the field.
    func focused(_ binding: Binding<Bool>) -> Self { mutating { $0.focusBinding = binding } }
    /// Continuously written with the field's validity (handy for enabling a submit button).
    func isValid(_ binding: Binding<Bool>) -> Self { mutating { $0.isValidBinding = binding } }

    func onValidationChange(_ handler: ((KitoValidationState) -> Void)?) -> Self { mutating { $0.onValidationChange = handler } }
    func onSubmit(_ handler: (() -> Void)?) -> Self { mutating { $0.onSubmit = handler } }
    func onFocusChange(_ handler: ((Bool) -> Void)?) -> Self { mutating { $0.onFocusChange = handler } }
    func accessibilityLabel(_ label: String?) -> Self { mutating { $0.accessibilityLabel = label } }
}

// MARK: - Platform mapping

extension View {
    @ViewBuilder
    func kitoKeyboard(_ keyboard: KitoKeyboard) -> some View {
        #if os(iOS)
        self.keyboardType(keyboard.uiKeyboardType)
        #else
        self
        #endif
    }

    @ViewBuilder
    func kitoContentType(_ type: KitoContentType) -> some View {
        #if os(iOS)
        self.textContentType(type.uiTextContentType)
        #else
        self
        #endif
    }

    @ViewBuilder
    func kitoAutocapitalization(_ mode: KitoAutocapitalization) -> some View {
        #if os(iOS)
        self.textInputAutocapitalization(mode.textInputAutocapitalization)
        #else
        self
        #endif
    }
}

#if os(iOS)
extension KitoKeyboard {
    var uiKeyboardType: UIKeyboardType {
        switch self {
        case .default: return .default
        case .asciiCapable: return .asciiCapable
        case .numbersAndPunctuation: return .numbersAndPunctuation
        case .url: return .URL
        case .numberPad: return .numberPad
        case .phonePad: return .phonePad
        case .namePhonePad: return .namePhonePad
        case .emailAddress: return .emailAddress
        case .decimalPad: return .decimalPad
        case .webSearch: return .webSearch
        }
    }
}

extension KitoContentType {
    var uiTextContentType: UITextContentType? {
        switch self {
        case .none: return nil
        case .name: return .name
        case .givenName: return .givenName
        case .familyName: return .familyName
        case .username: return .username
        case .emailAddress: return .emailAddress
        case .password: return .password
        case .newPassword: return .newPassword
        case .oneTimeCode: return .oneTimeCode
        case .telephoneNumber: return .telephoneNumber
        case .url: return .URL
        case .streetAddress: return .fullStreetAddress
        case .postalCode: return .postalCode
        case .creditCardNumber: return .creditCardNumber
        }
    }
}

extension KitoAutocapitalization {
    var textInputAutocapitalization: TextInputAutocapitalization {
        switch self {
        case .never: return .never
        case .words: return .words
        case .sentences: return .sentences
        case .characters: return .characters
        }
    }
}
#endif
