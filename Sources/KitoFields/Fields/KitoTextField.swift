//
//  KitoTextField.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// Secure-entry behaviour used by `KitoPasswordField`.
struct KitoSecureEntryOptions {
    var revealable = true
    var showsStrengthMeter = false
    var strengthEvaluator = KitoPasswordStrengthEvaluator()
    var requirements: [KitoRule] = []
    var showsRequirementChecklist = false
    var revealedBinding: Binding<Bool>?
    var ui = KitoPasswordUIConfiguration()
}

/// The general-purpose text field. `KitoEmailField`, `KitoPasswordField` and friends are presets on top of it.
///
/// ```swift
/// KitoTextField("Username", text: $username, prompt: "e.g. wykee")
///     .leadingIcon("person")
///     .clearButton()
///     .required()
///     .validation(.minLength(3), .alphanumeric())
/// ```
public struct KitoTextField: View, KitoFieldConfigurable {
    @Binding private var text: String
    public var options = KitoFieldOptions()
    var secure: KitoSecureEntryOptions?

    @State private var isRevealed = false
    @State private var presentation = KitoValidationPresentation()
    @State private var lastReported: KitoValidationState?
    @FocusState private var focusedField: FocusField?
    @State private var nativeFocused = false

    @Environment(\.kitoFieldTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum FocusField: Hashable { case plain, secure }

    // MARK: Init

    public init(_ label: String? = nil, text: Binding<String>, prompt: String? = nil) {
        _text = text
        options.label = label
        options.placeholder = prompt
    }

    public init(text: Binding<String>) {
        _text = text
    }

    // MARK: Derived state

    private var isSecureEntry: Bool { secure != nil }
    private var revealed: Bool { secure?.revealedBinding?.wrappedValue ?? isRevealed }
    private var isFocused: Bool { focusedField != nil || nativeFocused }
    private var usesNativeMaskedInput: Bool {
        #if os(iOS)
        return options.mask != nil && !isSecureEntry
        #else
        return false
        #endif
    }

    private var validationState: KitoValidationState {
        if let external = options.externalError { return .invalid([external]) }
        var rules = options.effectiveRules
        if let secure { rules += secure.requirements.filter { req in !rules.contains { $0.id == req.id } } }
        if let limit = options.characterLimit, !options.characterLimitIsHard, !rules.contains(where: { $0.id == "inputkit.maxLength.\(limit)" }) {
            rules.append(.maxLength(limit))
        }
        return KitoValidator.validate(text, rules: rules)
    }

    private var displayedErrors: [String] {
        if let external = options.externalError { return [external] }
        guard presentation.shouldShowErrors(for: options.validationTrigger) else { return [] }
        var errors = validationState.errors
        // Requirements rendered as a checklist should not be duplicated as error lines.
        if let secure, secure.showsRequirementChecklist {
            let checklist = Set(secure.requirements.map(\.message))
            errors.removeAll { checklist.contains($0) }
        }
        return errors
    }

    private var showsSuccess: Bool {
        options.showsSuccessIndicator && !text.isEmpty && validationState == .valid
    }

    // MARK: Body

    public var body: some View {
        KitoFieldCore(
            options: options,
            isFocused: isFocused,
            isEmpty: text.isEmpty,
            errors: displayedErrors,
            isSuccess: showsSuccess,
            leadingOverride: nil,
            trailingExtras: trailingExtras,
            input: inputView,
            footer: footerView
        )
        .onChange(of: text) { handleTextChange($0) }
        .onChange(of: focusedField) { handleFocusChange($0 != nil) }
        .onChange(of: validationState) { report($0) }
        .onChange(of: options.focusBinding?.wrappedValue) { requested in
            guard let requested, requested != isFocused else { return }
            setFocus(requested)
        }
        .onAppear {
            report(validationState)
            if options.focusBinding?.wrappedValue == true { setFocus(true) }
        }
        .accessibilityLabel(options.accessibilityLabel ?? options.label ?? options.placeholder ?? "")
    }

    // MARK: Input control

    @ViewBuilder private var inputView: some View {
        if usesNativeMaskedInput {
            maskedInput
        } else if isSecureEntry {
            ZStack(alignment: .leading) {
                configuredTextField
                    .focused($focusedField, equals: .plain)
                    .opacity(revealed ? 1 : 0)
                    .allowsHitTesting(revealed)
                    .accessibilityHidden(!revealed)
                SecureField("", text: $text)
                    .modifier(CommonTextStyling(options: options, theme: theme, contentTypeOverride: nil))
                    .focused($focusedField, equals: .secure)
                    .onSubmit(handleSubmit)
                    .opacity(revealed ? 0 : 1)
                    .allowsHitTesting(!revealed)
                    .accessibilityHidden(revealed)
            }
        } else {
            configuredTextField.focused($focusedField, equals: .plain)
        }
    }

    @ViewBuilder private var configuredTextField: some View {
        Group {
            if let lines = options.multilineRange {
                if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *) {
                    TextField("", text: $text, axis: .vertical).lineLimit(lines)
                } else {
                    TextField("", text: $text)
                }
            } else {
                TextField("", text: $text)
            }
        }
        .modifier(CommonTextStyling(options: options, theme: theme, contentTypeOverride: nil))
        .onSubmit(handleSubmit)
    }

    @ViewBuilder private var maskedInput: some View {
        #if os(iOS)
        KitoNativeTextField(
            text: $text,
            isFocused: $nativeFocused,
            keyboard: options.keyboard.uiKeyboardType,
            contentType: options.contentType.uiTextContentType,
            font: theme.uiFont,
            textColor: theme.textColor,
            tint: theme.tintColor ?? theme.focusedBorderColor,
            accessibilityLabel: options.accessibilityLabel ?? options.label ?? options.placeholder ?? "",
            onEdit: { proposed in
                var digits = proposed.asciiDigits
                if let mask = options.mask {
                    let capacity = mask.digitCount
                    if options.characterLimitIsHard || options.characterLimit == nil { digits = String(digits.prefix(capacity)) }
                    return KitoPhoneFormatter().apply(mask: mask, to: digits)
                }
                return proposed
            },
            onSubmit: handleSubmit
        )
        .frame(minHeight: 22)
        .onChange(of: nativeFocused) { handleFocusChange($0) }
        #else
        configuredTextField.focused($focusedField, equals: .plain)
        #endif
    }

    private struct CommonTextStyling: ViewModifier {
        let options: KitoFieldOptions
        let theme: KitoFieldTheme
        let contentTypeOverride: KitoContentType?

        func body(content: Content) -> some View {
            content
                .textFieldStyle(.plain)
                .font(theme.font)
                .foregroundColor(theme.textColor)
                .accentColor(theme.tintColor ?? theme.focusedBorderColor)
                .kitoKeyboard(options.keyboard)
                .kitoContentType(contentTypeOverride ?? options.contentType)
                .kitoAutocapitalization(options.autocapitalization)
                .disableAutocorrection(options.disablesAutocorrection)
        }
    }

    // MARK: Trailing controls

    private var trailingExtras: [AnyView] {
        var views: [AnyView] = []
        if options.showsClearButton && !text.isEmpty && isEnabled {
            views.append(KitoFieldControls.clearButton(theme: theme) { clear() })
        }
        if let secure, secure.revealable {
            views.append(revealButton)
        }
        if !displayedErrors.isEmpty && options.showsErrorIndicator && options.externalError == nil {
            views.append(KitoFieldControls.validationIcon(isError: true, theme: theme))
        } else if showsSuccess {
            views.append(KitoFieldControls.validationIcon(isError: false, theme: theme))
        }
        return views
    }

    private var revealButton: AnyView {
        AnyView(
            Button(action: toggleReveal) {
                Image(systemName: revealed ? "eye.slash" : "eye")
                    .font(.system(size: theme.iconSize))
                    .foregroundColor(theme.iconColor)
                    .frame(width: theme.iconSize + 8, height: theme.iconSize + 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(revealed ? KitoLocalization.string("password.hide", "Hide password") : KitoLocalization.string("password.show", "Show password"))
        )
    }

    // MARK: Footer

    @ViewBuilder private var footerView: some View {
        let hasCounter = options.showsCharacterCounter && options.characterLimit != nil
        let hasStrength = secure?.showsStrengthMeter == true
        let hasChecklist = secure?.showsRequirementChecklist == true && !(secure?.requirements.isEmpty ?? true)
        if hasCounter || hasStrength || hasChecklist {
            VStack(alignment: .leading, spacing: secure?.ui.spacing ?? 6) {
                if let secure {
                    let strength = secure.ui.scorer?(text) ?? secure.strengthEvaluator.evaluate(text)
                    let meterVisible = hasStrength && !(secure.ui.hidesMeterWhenEmpty && text.isEmpty)
                    if secure.ui.order == .meterThenChecklist {
                        if meterVisible { KitoStrengthMeterView(strength: strength, ui: secure.ui) }
                        if hasChecklist { KitoRequirementChecklistView(rules: secure.requirements, value: text, ui: secure.ui) }
                    } else {
                        if hasChecklist { KitoRequirementChecklistView(rules: secure.requirements, value: text, ui: secure.ui) }
                        if meterVisible { KitoStrengthMeterView(strength: strength, ui: secure.ui) }
                    }
                }
                if hasCounter, let limit = options.characterLimit {
                    HStack {
                        Spacer()
                        Text(options.counterStyle == .count
                             ? "\(text.count) / \(limit)"
                             : KitoLocalization.format("counter.remaining", "%d left", max(limit - text.count, 0)))
                            .font(theme.helperFont)
                            .foregroundColor(text.count > limit ? theme.errorColor : (text.count == limit ? theme.helperColor.opacity(0.9) : theme.helperColor))
                            .monospacedDigit()
                            .scaleEffect(text.count >= limit ? 1.15 : 1, anchor: .trailing)
                            .animation((reduceMotion ? KitoFieldMotion.subtle : theme.motion).pop, value: text.count >= limit)
                    }
                }
            }
        }
    }

    // MARK: Behaviour

    private func handleTextChange(_ newValue: String) {
        var value = newValue
        if let transform = options.transform { value = transform(value) }
        if let limit = options.characterLimit, options.characterLimitIsHard, options.mask == nil, value.count > limit { value = String(value.prefix(limit)) }
        if value != newValue {
            // Defer the rewrite so a keystroke that arrives before this one is applied is not lost.
            DispatchQueue.main.async {
                guard text == newValue else { return }
                text = value
            }
            return
        }
        if value.isEmpty && !isFocused {
            // Programmatic reset from the parent: start the interaction lifecycle over.
            presentation.reset()
        } else {
            presentation.didEdit()
        }
    }

    private func handleFocusChange(_ focused: Bool) {
        if !focused { presentation.didBlur() }
        if let binding = options.focusBinding, binding.wrappedValue != focused {
            binding.wrappedValue = focused
        }
        options.onFocusChange?(focused)
    }

    private func handleSubmit() {
        presentation.didSubmit()
        options.onSubmit?()
    }

    private func report(_ state: KitoValidationState) {
        guard state != lastReported else { return }
        lastReported = state
        options.isValidBinding?.wrappedValue = state.isValid && (!options.isRequired || !text.isEmpty)
        options.onValidationChange?(state)
    }

    private func clear() {
        text = ""
        presentation.didEdit()
    }

    private func toggleReveal() {
        let wasFocused = isFocused
        if let binding = secure?.revealedBinding {
            binding.wrappedValue.toggle()
        } else {
            isRevealed.toggle()
        }
        if wasFocused {
            let target: FocusField = revealed ? .plain : .secure
            DispatchQueue.main.async { focusedField = target }
        }
    }

    private func setFocus(_ focused: Bool) {
        if usesNativeMaskedInput { nativeFocused = focused; return }
        if focused {
            focusedField = isSecureEntry ? (revealed ? .plain : .secure) : .plain
        } else {
            focusedField = nil
        }
    }
}
