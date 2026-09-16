//
//  KitoCountryField.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// Settings for `KitoCountryField`.
public struct KitoCountryFieldConfiguration {
    public var showsFlag = true
    public var showsName = true
    public var showsDialCode = false
    public var showsCurrency = false
    public var showsChevron = true
    public var flagStyle: KitoFlagStyle = .emoji
    public var selectionMode: KitoCountrySelection = .sheet
    public var allowedCountries: Set<String>? = nil
    public var excludedCountries: Set<String> = []
    public var preferredCountries: [String] = []
    public var picker = KitoCountryPickerConfiguration()
    public var onChange: ((KitoCountry) -> Void)?

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
}

/// A form field that selects a country. Shows any combination of flag, name, dial code and
/// currency, opens the searchable picker on tap, and hands back the full `KitoCountry` (flag,
/// names, dial code, currency) through the binding or `onCountryChange`.
///
/// ```swift
/// KitoCountryField("Country", selection: $country)
///     .shows(flag: true, name: true, currency: true)
///     .flagStyle(.circle)
///     .required()
///     .onCountryChange { country in
///         print(country.flag, country.localizedName, country.formattedDialCode, country.currencyCode ?? "")
///     }
/// ```
public struct KitoCountryField: View, KitoFieldConfigurable {
    public var options = KitoFieldOptions()
    var config = KitoCountryFieldConfiguration()

    @Binding private var selection: KitoCountry?
    private let isoBinding: Binding<String>?

    @State private var showsPicker = false
    @State private var presentation = KitoValidationPresentation()
    @State private var lastReported: KitoValidationState?
    @Environment(\.kitoFieldTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    // MARK: Init

    public init(_ label: String? = nil, selection: Binding<KitoCountry?>) {
        _selection = selection
        isoBinding = nil
        options.label = label
    }

    /// Binds to an ISO 3166-1 alpha-2 code ("" when nothing is selected).
    public init(_ label: String? = nil, isoCode: Binding<String>) {
        _selection = Binding(
            get: { KitoCountryDatabase.country(isoCode: isoCode.wrappedValue) },
            set: { isoCode.wrappedValue = $0?.isoCode ?? "" }
        )
        isoBinding = isoCode
        options.label = label
    }

    // MARK: Derived

    private var validationState: KitoValidationState {
        if let external = options.externalError { return .invalid([external]) }
        if options.isRequired && selection == nil { return .invalid([options.requiredMessage]) }
        return options.rules.isEmpty ? (selection == nil ? .idle : .valid) : .valid
    }

    private var displayedErrors: [String] {
        if let external = options.externalError { return [external] }
        guard presentation.shouldShowErrors(for: options.validationTrigger) else { return [] }
        return validationState.errors
    }

    private var placeholder: String {
        options.placeholder ?? KitoLocalization.string("country.placeholder", "Select a country")
    }

    // MARK: Body

    public var body: some View {
        var resolved = options
        resolved.placeholder = placeholder
        return KitoFieldCore(
            options: resolved,
            isFocused: showsPicker,
            isEmpty: selection == nil,
            errors: displayedErrors,
            isSuccess: options.showsSuccessIndicator && selection != nil,
            leadingOverride: nil,
            trailingExtras: trailingExtras,
            input: input,
            footer: EmptyView?.none
        )
        .onChange(of: selection) { _ in
            presentation.didEdit()
            if let country = selection { config.onChange?(country) }
            report(validationState)
        }
        .onChange(of: showsPicker) { open in if !open { presentation.didBlur() } }
        .onAppear { report(validationState) }
        .sheet(isPresented: $showsPicker) {
            KitoCountryPicker(
                selection: Binding(get: { selection ?? KitoCountryDatabase.current }, set: { selection = $0 }),
                countries: config.availableCountries,
                preferred: config.preferred,
                configuration: pickerConfiguration
            )
            .kitoFieldTheme(theme)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(options.accessibilityLabel ?? options.label ?? KitoLocalization.string("country.accessibilityLabel", "Country"))
        .accessibilityValue(selection?.localizedName ?? "")
        .accessibilityAddTraits(.isButton)
    }

    private var pickerConfiguration: KitoCountryPickerConfiguration {
        var picker = config.picker
        picker.flagStyle = config.flagStyle
        if config.showsCurrency { picker.showsCurrency = true }
        return picker
    }

    @ViewBuilder private var input: some View {
        switch config.selectionMode {
        case .menu:
            Menu {
                ForEach(config.preferred + config.availableCountries.filter { !config.preferred.contains($0) }) { country in
                    Button { selection = country } label: { Text("\(country.flag) \(country.localizedName)  \(country.formattedDialCode)") }
                }
            } label: { valueLabel }
        case .sheet, .locked:
            Button { if config.selectionMode == .sheet { showsPicker = true } } label: { valueLabel }
                .buttonStyle(.plain)
                .disabled(!isEnabled)
        }
    }

    /// The selected country rendered inline; empty when nothing is selected so the placeholder shows.
    private var valueLabel: some View {
        HStack(spacing: 8) {
            if let country = selection {
                if config.showsFlag {
                    KitoFlag(country: country, style: config.flagStyle, size: theme.iconSize + 5)
                        .id(country.isoCode)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
                if config.showsName {
                    Text(country.localizedName(in: config.picker.locale ?? .autoupdatingCurrent))
                        .font(theme.font).foregroundColor(theme.textColor).lineLimit(1)
                }
                if config.showsDialCode {
                    Text(country.formattedDialCode)
                        .font(theme.font).foregroundColor(theme.helperColor).monospacedDigit()
                }
                if config.showsCurrency, let code = country.currencyCode {
                    Text([code, country.currencySymbol].compactMap { $0 }.joined(separator: " "))
                        .font(theme.helperFont).foregroundColor(theme.helperColor)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(theme.borderColor.opacity(0.35)))
                }
            } else {
                // Keep the row's height stable while empty.
                Text(" ").font(theme.font)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .animation(theme.motion.pop, value: selection)
    }

    private var trailingExtras: [AnyView] {
        var views: [AnyView] = []
        if options.showsClearButton, selection != nil, isEnabled {
            views.append(KitoFieldControls.clearButton(theme: theme) { selection = nil })
        }
        if !displayedErrors.isEmpty && options.showsErrorIndicator && options.externalError == nil {
            views.append(KitoFieldControls.validationIcon(isError: true, theme: theme))
        } else if options.showsSuccessIndicator && selection != nil {
            views.append(KitoFieldControls.validationIcon(isError: false, theme: theme))
        }
        if config.showsChevron && config.selectionMode != .locked {
            views.append(AnyView(
                Image(systemName: "chevron.down")
                    .font(.system(size: theme.iconSize * 0.6, weight: .semibold))
                    .foregroundColor(theme.iconColor)
            ))
        }
        return views
    }

    private func report(_ state: KitoValidationState) {
        guard state != lastReported else { return }
        lastReported = state
        options.isValidBinding?.wrappedValue = state.isValid && (!options.isRequired || selection != nil)
        options.onValidationChange?(state)
    }
}

// MARK: - Fluent configuration

public extension KitoCountryField {
    private func mutatingConfig(_ change: (inout KitoCountryFieldConfiguration) -> Void) -> KitoCountryField {
        var copy = self
        change(&copy.config)
        return copy
    }

    /// Which parts of the selected country appear in the field.
    func shows(flag: Bool = true, name: Bool = true, dialCode: Bool = false, currency: Bool = false) -> KitoCountryField {
        mutatingConfig { $0.showsFlag = flag; $0.showsName = name; $0.showsDialCode = dialCode; $0.showsCurrency = currency }
    }
    /// Emoji, circle, rounded, tile, ISO code badge or hidden.
    func flagStyle(_ style: KitoFlagStyle) -> KitoCountryField { mutatingConfig { $0.flagStyle = style } }
    func showsChevron(_ shows: Bool) -> KitoCountryField { mutatingConfig { $0.showsChevron = shows } }
    func selectionMode(_ mode: KitoCountrySelection) -> KitoCountryField { mutatingConfig { $0.selectionMode = mode } }
    func countries(allowed: [String]? = nil, excluded: [String] = [], preferred: [String] = []) -> KitoCountryField {
        mutatingConfig {
            if let allowed { $0.allowedCountries = Set(allowed.map { $0.uppercased() }) }
            $0.excludedCountries = Set(excluded.map { $0.uppercased() })
            $0.preferredCountries = preferred.map { $0.uppercased() }
        }
    }
    func countryPicker(_ transform: @escaping (inout KitoCountryPickerConfiguration) -> Void) -> KitoCountryField {
        mutatingConfig { transform(&$0.picker) }
    }
    /// Receives the full country (flag, names, dial code, currency) whenever the selection changes.
    func onCountryChange(_ handler: @escaping (KitoCountry) -> Void) -> KitoCountryField { mutatingConfig { $0.onChange = handler } }
}
