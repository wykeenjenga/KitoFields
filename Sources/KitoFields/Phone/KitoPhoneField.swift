//
//  KitoPhoneField.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// How the user changes the selected region.
public enum KitoCountrySelection: Sendable {
    /// Full-screen/sheet picker with search. Default.
    case sheet
    /// A compact `Menu` (best with a short allowed-country list, or on macOS).
    case menu
    /// The region is fixed; the selector is display-only.
    case locked
}

/// Phone-specific settings, configured through `KitoPhoneField`'s fluent modifiers.
public struct KitoPhoneFieldConfiguration {
    public var showsFlag = true
    public var showsDialCode = true
    public var showsChevron = true
    public var showsDivider = true
    public var flagStyle: KitoFlagStyle = .emoji
    public var selectionMode: KitoCountrySelection = .sheet
    public var formatsAsYouType = true
    public var limitsToMaxLength = true
    public var detectsCountryFromInternationalInput = true
    public var usesExampleNumberAsPlaceholder = true
    public var allowedCountries: Set<String>? = nil
    public var excludedCountries: Set<String> = []
    public var preferredCountries: [String] = []
    public var defaultCountry: String? = nil
    public var picker = KitoCountryPickerConfiguration()
    public var validator = KitoPhoneValidator()
    public var errorMessages: (KitoPhoneError) -> String = { $0.message }
    public var hapticsEnabled = true
    public var onCountryChange: ((KitoCountry) -> Void)?
    public var onPhoneNumberChange: ((KitoPhoneNumber?) -> Void)?
    public var onValidationChange: ((KitoPhoneState) -> Void)?

    public init() {}

    var availableCountries: [KitoCountry] {
        KitoCountryDatabase.all.filter { country in
            if let allowed = allowedCountries, !allowed.contains(country.isoCode) { return false }
            return !excludedCountries.contains(country.isoCode)
        }
    }

    var preferred: [KitoCountry] {
        let available = Set(availableCountries.map(\.isoCode))
        return preferredCountries.compactMap(KitoCountryDatabase.country(isoCode:)).filter { available.contains($0.isoCode) }
    }

    func resolvedDefaultCountry() -> KitoCountry {
        let available = availableCountries
        if let iso = defaultCountry, let c = KitoCountryDatabase.country(isoCode: iso), available.contains(c) { return c }
        let current = KitoCountryDatabase.current
        if available.contains(current) { return current }
        return preferred.first ?? available.first ?? current
    }
}

/// Phone number entry with a country selector, as-you-type formatting, international paste
/// detection and metadata-based validation. Shares styles and theme with every other field.
///
/// ```swift
/// KitoPhoneField(phoneNumber: $phone)
///     .label("Mobile number")
///     .required()
///     .countries(preferred: ["KE", "UG", "TZ"])
/// ```
public struct KitoPhoneField: View, KitoFieldConfigurable {
    public var options = KitoFieldOptions()
    var phone = KitoPhoneFieldConfiguration()

    private let phoneBinding: Binding<KitoPhoneNumber?>?
    private let e164Binding: Binding<String>?
    private let countryBinding: Binding<KitoCountry>?
    private let nationalBinding: Binding<String>?

    @State private var country: KitoCountry
    @State private var digits = ""
    @State private var displayText = ""
    @State private var pendingInternational: String? = nil
    @State private var presentation = KitoValidationPresentation()
    @State private var showsPicker = false
    @State private var lastReportedState: KitoPhoneState?
    @State private var hasAppeared = false
    @State private var isFocused = false
    @FocusState private var swiftUIFocus: Bool

    @Environment(\.kitoFieldTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let formatter = KitoPhoneFormatter()

    // MARK: Init

    /// Binds to a `KitoPhoneNumber?`; nil while empty.
    public init(_ label: String? = nil, phoneNumber: Binding<KitoPhoneNumber?>) {
        phoneBinding = phoneNumber; e164Binding = nil; countryBinding = nil; nationalBinding = nil
        options.label = label
        _country = State(initialValue: phoneNumber.wrappedValue?.country ?? KitoCountryDatabase.current)
    }

    /// Binds to an E.164 string ("+254712123456", or "" while empty). Handy for APIs.
    public init(_ label: String? = nil, e164: Binding<String>) {
        phoneBinding = nil; e164Binding = e164; countryBinding = nil; nationalBinding = nil
        options.label = label
        _country = State(initialValue: KitoPhoneNumber(e164: e164.wrappedValue)?.country ?? KitoCountryDatabase.current)
    }

    /// Binds region and national digits separately.
    public init(_ label: String? = nil, country: Binding<KitoCountry>, nationalNumber: Binding<String>) {
        phoneBinding = nil; e164Binding = nil; countryBinding = country; nationalBinding = nationalNumber
        options.label = label
        _country = State(initialValue: country.wrappedValue)
    }

    // MARK: Derived

    private var phoneNumber: KitoPhoneNumber? {
        digits.isEmpty ? nil : KitoPhoneNumber(country: country, nationalNumber: digits)
    }

    private var validationState: KitoPhoneState {
        phone.validator.validate(nationalNumber: digits, country: country)
    }

    private var displayedErrors: [String] {
        if let external = options.externalError { return [external] }
        guard presentation.shouldShowErrors(for: options.validationTrigger) else { return [] }
        switch validationState {
        case .invalid(let error):
            return [phone.errorMessages(error)]
        case .incomplete:
            return presentation.hasBlurred || presentation.hasSubmitted ? [phone.errorMessages(.tooShort)] : []
        case .empty:
            return options.isRequired && (presentation.hasBlurred || presentation.hasSubmitted) ? [options.requiredMessage] : []
        case .valid:
            return []
        }
    }

    private var placeholder: String? {
        if let explicit = options.placeholder { return explicit }
        return phone.usesExampleNumberAsPlaceholder ? country.formattedExampleNumber : nil
    }

    // MARK: Body

    public var body: some View {
        var resolvedOptions = options
        resolvedOptions.placeholder = placeholder
        return KitoFieldCore(
            options: resolvedOptions,
            isFocused: isFocused,
            isEmpty: displayText.isEmpty,
            errors: displayedErrors,
            isSuccess: options.showsSuccessIndicator && validationState == .valid,
            leadingOverride: AnyView(countrySelector),
            trailingExtras: trailingExtras,
            input: textField,
            footer: EmptyView?.none
        )
        .onChange(of: country) { handleCountryChange($0) }
        .onChange(of: isFocused) { handleFocusChange($0) }
        .onChange(of: validationState) { report($0) }
        .onChange(of: phoneBinding?.wrappedValue) { syncFromPhoneBinding($0) }
        .onChange(of: e164Binding?.wrappedValue) { syncFromE164($0) }
        .onChange(of: nationalBinding?.wrappedValue) { syncFromNational($0) }
        .onChange(of: countryBinding?.wrappedValue) { if let c = $0, c != country { country = c } }
        .onChange(of: options.focusBinding?.wrappedValue) { if let f = $0, f != isFocused { isFocused = f } }
        .onAppear(perform: initialSync)
        .sheet(isPresented: $showsPicker) { picker }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder private var textField: some View {
        #if os(iOS)
        KitoNativeTextField(
            text: $displayText,
            isFocused: $isFocused,
            keyboard: (options.keyboard == .default ? KitoKeyboard.phonePad : options.keyboard).uiKeyboardType,
            contentType: .telephoneNumber,
            font: theme.uiFont,
            textColor: theme.textColor,
            tint: theme.tintColor ?? theme.focusedBorderColor,
            accessibilityLabel: options.accessibilityLabel ?? options.label ?? KitoLocalization.string("phone.accessibilityLabel", "Phone number"),
            onEdit: { proposed in process(proposed) },
            onSubmit: { presentation.didSubmit(); options.onSubmit?() }
        )
        .frame(minHeight: 22)
        #else
        TextField("", text: $displayText)
            .textFieldStyle(.plain)
            .focused($swiftUIFocus)
            .font(theme.font)
            .foregroundColor(theme.textColor)
            .accentColor(theme.tintColor ?? theme.focusedBorderColor)
            .disableAutocorrection(true)
            .onSubmit { presentation.didSubmit(); options.onSubmit?() }
            .onChange(of: displayText) { newValue in
                let formatted = process(newValue)
                if formatted != newValue { rewrite(newValue, to: formatted) }
            }
            .onChange(of: swiftUIFocus) { if isFocused != $0 { isFocused = $0 } }
            .onChange(of: isFocused) { if swiftUIFocus != $0 { swiftUIFocus = $0 } }
            .accessibilityLabel(options.accessibilityLabel ?? options.label ?? KitoLocalization.string("phone.accessibilityLabel", "Phone number"))
        #endif
    }

    private var trailingExtras: [AnyView] {
        var views: [AnyView] = []
        if options.showsClearButton && !displayText.isEmpty && isEnabled {
            views.append(KitoFieldControls.clearButton(theme: theme) { displayText = "" })
        }
        if !displayedErrors.isEmpty && options.showsErrorIndicator && options.externalError == nil {
            views.append(KitoFieldControls.validationIcon(isError: true, theme: theme))
        } else if options.showsSuccessIndicator && validationState == .valid {
            views.append(KitoFieldControls.validationIcon(isError: false, theme: theme))
        }
        return views
    }

    // MARK: KitoCountry selector

    @ViewBuilder private var countrySelector: some View {
        HStack(spacing: theme.accessorySpacing) {
            switch phone.selectionMode {
            case .sheet:
                Button { showsPicker = true } label: { selectorLabel }
                    .buttonStyle(.plain)
            case .menu:
                #if os(watchOS)
                Button { showsPicker = true } label: { selectorLabel }
                    .buttonStyle(.plain)
                #else
                Menu {
                    ForEach(phone.preferred + phone.availableCountries.filter { !phone.preferred.contains($0) }) { c in
                        Button {
                            country = c
                        } label: {
                            Text("\(c.flag) \(c.localizedName(in: phone.picker.locale ?? .autoupdatingCurrent))  \(c.formattedDialCode)")
                        }
                    }
                } label: { selectorLabel }
                .fixedSize()
                #endif
            case .locked:
                selectorLabel
            }
            if phone.showsDivider {
                Rectangle()
                    .fill(theme.borderColor)
                    .frame(width: 1, height: theme.iconSize + 6)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(KitoLocalization.format("phone.countryAccessibility", "Country: %@, %@", country.localizedName, country.formattedDialCode))
        .accessibilityAddTraits(phone.selectionMode == .locked ? [] : .isButton)
    }

    private var selectorLabel: some View {
        HStack(spacing: 6) {
            if phone.showsFlag {
                KitoFlag(country: country, style: phone.flagStyle, size: theme.iconSize + 5)
                    .id(country.isoCode)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
            }
            if phone.showsDialCode {
                Text(country.formattedDialCode)
                    .font(theme.font)
                    .foregroundColor(theme.textColor)
                    .monospacedDigit()
                    .id(country.dialCode)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if phone.showsChevron && phone.selectionMode != .locked {
                Image(systemName: "chevron.down")
                    .font(.system(size: theme.iconSize * 0.6, weight: .semibold))
                    .foregroundColor(theme.iconColor)
            }
        }
        .contentShape(Rectangle())
        .animation((reduceMotion ? KitoFieldMotion.subtle : theme.motion).pop, value: country)
    }

    private var picker: some View {
        KitoCountryPicker(
            selection: $country,
            countries: phone.availableCountries,
            preferred: phone.preferred,
            configuration: phone.picker
        )
        .kitoFieldTheme(theme)
        .modifier(SheetDetents())
    }

    private struct SheetDetents: ViewModifier {
        func body(content: Content) -> some View {
            #if os(tvOS)
            content
            #else
            if #available(iOS 16.0, macOS 13.0, watchOS 9.0, visionOS 1.0, *) {
                content.presentationDetents([.medium, .large])
            } else {
                content
            }
            #endif
        }
    }

    // MARK: Behaviour

    private func initialSync() {
        guard !hasAppeared else { return }
        hasAppeared = true
        if country != phone.resolvedDefaultCountry(), phoneBinding?.wrappedValue == nil,
           (e164Binding?.wrappedValue ?? "").isEmpty, (nationalBinding?.wrappedValue ?? "").isEmpty, countryBinding == nil {
            country = phone.resolvedDefaultCountry()
        }
        if let phone = phoneBinding?.wrappedValue { load(phone) }
        else if let e164 = e164Binding?.wrappedValue, let parsed = KitoPhoneNumber(e164: e164) { load(parsed) }
        else if let national = nationalBinding?.wrappedValue, !national.isEmpty { digits = formatter.stripTrunkPrefix(national.asciiDigits, country: country); displayText = format(digits) }
        if options.focusBinding?.wrappedValue == true { isFocused = true }
        report(validationState)
    }

    private func load(_ number: KitoPhoneNumber) {
        if number.country != country { country = number.country }
        digits = number.nationalNumber
        displayText = format(digits)
    }

    private func format(_ digits: String) -> String {
        phone.formatsAsYouType ? formatter.formatNational(digits, country: country) : digits
    }

    /// Applies an edit: detects international input, strips trunk prefixes, clamps to the region's
    /// maximum length, commits to the bindings and returns the text that should be displayed.
    @discardableResult
    private func process(_ newValue: String) -> String {
        // International entry: "+" or "00" prefix resolves the region as soon as it is unambiguous.
        if phone.detectsCountryFromInternationalInput,
           let international = KitoPhoneParser().internationalDigits(from: newValue) {
            if let (matched, national) = KitoCountryDatabase.match(internationalDigits: international),
               phone.availableCountries.contains(matched) {
                pendingInternational = nil
                if matched != country { country = matched }
                digits = clamp(formatter.stripTrunkPrefix(national, country: matched), for: matched)
                presentation.didEdit()
                commit()
                return formatter.formatNational(digits, country: matched)
            }
            // Not resolvable yet ("+2"): keep what the user typed.
            pendingInternational = newValue
            if !digits.isEmpty { digits = ""; commit() }
            presentation.didEdit()
            return newValue
        }
        pendingInternational = nil

        var raw = newValue.asciiDigits
        if let trunk = country.trunkPrefix, raw == trunk {
            // Just the trunk digit so far ("0"): keep it visible until more digits arrive.
            if digits != "" { digits = ""; commit() }
            presentation.didEdit()
            return newValue
        }
        raw = formatter.stripTrunkPrefix(raw, country: country)
        raw = clamp(raw, for: country)

        let formatted = format(raw)
        let changed = raw != digits
        digits = raw
        if changed || newValue.isEmpty {
            if raw.isEmpty && !isFocused { presentation.reset() } else { presentation.didEdit() }
            commit()
        }
        return formatted
    }

    /// Replaces the field text with its formatted form, but only if no newer keystroke has landed
    /// in the meantime. Writing synchronously can swallow characters typed faster than SwiftUI
    /// round-trips the binding (hardware keyboards, fast typists, automated input).
    private func rewrite(_ observed: String, to formatted: String) {
        DispatchQueue.main.async {
            guard displayText == observed else { return }
            displayText = formatted
        }
    }

    private func clamp(_ digits: String, for country: KitoCountry) -> String {
        guard phone.limitsToMaxLength else { return digits }
        return String(digits.prefix(country.maxNationalNumberLength))
    }

    private func handleCountryChange(_ newCountry: KitoCountry) {
        digits = clamp(digits, for: newCountry)
        if pendingInternational == nil { displayText = format(digits) }
        if let binding = countryBinding, binding.wrappedValue != newCountry { binding.wrappedValue = newCountry }
        phone.onCountryChange?(newCountry)
        haptic()
        commit()
    }

    private func handleFocusChange(_ focused: Bool) {
        if !focused {
            presentation.didBlur()
            if pendingInternational != nil, digits.isEmpty { displayText = ""; pendingInternational = nil }
        }
        if let binding = options.focusBinding, binding.wrappedValue != focused { binding.wrappedValue = focused }
        options.onFocusChange?(focused)
    }

    private func commit() {
        let number = phoneNumber
        if let phoneBinding, phoneBinding.wrappedValue != number { phoneBinding.wrappedValue = number }
        if let e164Binding {
            let value = number?.e164 ?? ""
            if e164Binding.wrappedValue != value { e164Binding.wrappedValue = value }
        }
        if let nationalBinding, nationalBinding.wrappedValue != digits { nationalBinding.wrappedValue = digits }
        phone.onPhoneNumberChange?(number)
    }

    private func report(_ state: KitoPhoneState) {
        guard state != lastReportedState else { return }
        lastReportedState = state
        options.isValidBinding?.wrappedValue = state == .valid || (state == .empty && !options.isRequired)
        phone.onValidationChange?(state)
        options.onValidationChange?(bridged(state))
    }

    private func bridged(_ state: KitoPhoneState) -> KitoValidationState {
        switch state {
        case .valid: return .valid
        case .empty: return options.isRequired ? .invalid([options.requiredMessage]) : .idle
        case .incomplete: return .invalid([phone.errorMessages(.tooShort)])
        case .invalid(let e): return .invalid([phone.errorMessages(e)])
        }
    }

    private func syncFromPhoneBinding(_ value: KitoPhoneNumber?) {
        guard hasAppeared, value != phoneNumber else { return }
        if let value { load(value) } else { digits = ""; displayText = "" }
    }

    private func syncFromE164(_ value: String?) {
        guard hasAppeared, let value, value != (phoneNumber?.e164 ?? "") else { return }
        if let parsed = KitoPhoneNumber(e164: value) { load(parsed) } else if value.isEmpty { digits = ""; displayText = "" }
    }

    private func syncFromNational(_ value: String?) {
        guard hasAppeared, let value, value != digits else { return }
        digits = clamp(formatter.stripTrunkPrefix(value.asciiDigits, country: country), for: country)
        displayText = format(digits)
    }

    private func haptic() {
        #if os(iOS)
        guard phone.hapticsEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }
}

// MARK: - Phone-specific fluent configuration

public extension KitoPhoneField {
    private func mutatingPhone(_ change: (inout KitoPhoneFieldConfiguration) -> Void) -> KitoPhoneField {
        var copy = self
        change(&copy.phone)
        return copy
    }

    /// Restrict, exclude, or pin regions (ISO 3166-1 alpha-2 codes).
    func countries(allowed: [String]? = nil, excluded: [String] = [], preferred: [String] = []) -> KitoPhoneField {
        mutatingPhone {
            if let allowed { $0.allowedCountries = Set(allowed.map { $0.uppercased() }) }
            $0.excludedCountries = Set(excluded.map { $0.uppercased() })
            $0.preferredCountries = preferred.map { $0.uppercased() }
        }
    }
    /// Region selected when the bound value is empty. Defaults to the device region.
    func defaultCountry(_ isoCode: String) -> KitoPhoneField { mutatingPhone { $0.defaultCountry = isoCode.uppercased() } }
    func countrySelection(_ mode: KitoCountrySelection) -> KitoPhoneField { mutatingPhone { $0.selectionMode = mode } }
    func showsFlag(_ shows: Bool) -> KitoPhoneField { mutatingPhone { $0.showsFlag = shows } }
    func showsDialCode(_ shows: Bool) -> KitoPhoneField { mutatingPhone { $0.showsDialCode = shows } }
    func showsChevron(_ shows: Bool) -> KitoPhoneField { mutatingPhone { $0.showsChevron = shows } }
    func showsDivider(_ shows: Bool) -> KitoPhoneField { mutatingPhone { $0.showsDivider = shows } }
    func flagStyle(_ style: KitoFlagStyle) -> KitoPhoneField { mutatingPhone { $0.flagStyle = style; $0.picker.flagStyle = style } }
    func formatsAsYouType(_ enabled: Bool) -> KitoPhoneField { mutatingPhone { $0.formatsAsYouType = enabled } }
    func limitsToMaxLength(_ enabled: Bool) -> KitoPhoneField { mutatingPhone { $0.limitsToMaxLength = enabled } }
    func detectsInternationalInput(_ enabled: Bool) -> KitoPhoneField { mutatingPhone { $0.detectsCountryFromInternationalInput = enabled } }
    /// Use the region's example number ("(201) 555-0123") as placeholder when no explicit placeholder is set.
    func examplePlaceholder(_ enabled: Bool) -> KitoPhoneField { mutatingPhone { $0.usesExampleNumberAsPlaceholder = enabled } }
    func countryPicker(_ configuration: KitoCountryPickerConfiguration) -> KitoPhoneField { mutatingPhone { $0.picker = configuration } }
    func countryPicker(_ transform: @escaping (inout KitoCountryPickerConfiguration) -> Void) -> KitoPhoneField { mutatingPhone { transform(&$0.picker) } }
    func phoneValidator(_ validator: KitoPhoneValidator) -> KitoPhoneField { mutatingPhone { $0.validator = validator } }
    /// Localize/override validation messages.
    func phoneErrorMessages(_ messages: @escaping (KitoPhoneError) -> String) -> KitoPhoneField { mutatingPhone { $0.errorMessages = messages } }
    func haptics(_ enabled: Bool) -> KitoPhoneField { mutatingPhone { $0.hapticsEnabled = enabled } }
    func onCountryChange(_ handler: @escaping (KitoCountry) -> Void) -> KitoPhoneField { mutatingPhone { $0.onCountryChange = handler } }
    func onPhoneNumberChange(_ handler: @escaping (KitoPhoneNumber?) -> Void) -> KitoPhoneField { mutatingPhone { $0.onPhoneNumberChange = handler } }
    func onPhoneValidationChange(_ handler: @escaping (KitoPhoneState) -> Void) -> KitoPhoneField { mutatingPhone { $0.onValidationChange = handler } }
}
