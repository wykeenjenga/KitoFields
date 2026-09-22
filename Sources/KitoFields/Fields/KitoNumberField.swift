//
//  KitoNumberField.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// Where the currency symbol sits relative to the formatted value.
public enum KitoCurrencyPosition: Sendable { case prefix, suffix, none }

/// One currency a `currencySelector(_:selected:)` menu offers.
public struct KitoCurrencyOption: Identifiable, Equatable, Sendable {
    public let code: String
    public let symbol: String?

    public init(code: String, symbol: String? = nil) {
        self.code = code
        self.symbol = symbol
    }

    public var id: String { code }

    /// This option's currency symbol, falling back to a lookup by ISO code, then the code itself.
    public var resolvedSymbol: String {
        symbol ?? KitoCountryDatabase.all.first { $0.currencyCode == code }?.currencySymbol ?? code
    }
}

/// Default label for a `currencySelector(_:selected:)` menu: the ISO code with a chevron.
private struct KitoDefaultCurrencyLabel: View {
    let option: KitoCurrencyOption
    @Environment(\.kitoFieldTheme) private var theme
    var body: some View {
        HStack(spacing: 4) {
            Text(option.code).font(theme.font).foregroundColor(theme.textColor)
            Image(systemName: "chevron.down").font(.system(size: theme.iconSize * 0.6, weight: .semibold)).foregroundColor(theme.iconColor)
        }
    }
}

/// Numeric input bound to a `Double?`. Accepts the locale's decimal separator, formats with
/// grouping on blur, and validates an optional range.
///
/// ```swift
/// KitoNumberField("Quantity", value: $quantity)
///     .integer()
///     .range(1...99)
///     .stepper()
/// ```
public struct KitoNumberField: View, KitoFieldConfigurable {
    public var options = KitoFieldOptions()
    @Binding private var value: Double?
    @State private var text = ""
    @State private var focused = false
    private var fractionDigits: ClosedRange<Int> = 0...2
    private var groups = true
    private var range: ClosedRange<Double>?
    private var step: Double?
    private var locale: Locale = .autoupdatingCurrent
    private var currencyCode: String?
    private var currencyPosition: KitoCurrencyPosition = .prefix
    private var unitSuffix: String?

    public init(_ label: String? = nil, value: Binding<Double?>, prompt: String? = "0") {
        _value = value
        options.label = label
        options.placeholder = prompt
        options.keyboard = .decimalPad
    }

    private var formatter: NumberFormatter {
        let f = NumberFormatter()
        f.locale = locale
        if let currencyCode {
            f.numberStyle = .currency
            f.currencyCode = currencyCode
        } else {
            f.numberStyle = .decimal
        }
        f.usesGroupingSeparator = groups
        f.minimumFractionDigits = fractionDigits.lowerBound
        f.maximumFractionDigits = fractionDigits.upperBound
        return f
    }

    private var editingFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.locale = locale
        f.numberStyle = .decimal
        f.usesGroupingSeparator = false
        f.maximumFractionDigits = fractionDigits.upperBound
        return f
    }

    public var body: some View {
        var field = KitoTextField(options.label, text: $text, prompt: options.placeholder)
        field.options = options
        field.options.keyboard = fractionDigits.upperBound == 0 ? .numberPad : .decimalPad
        field.options.transform = { [editingFormatter] raw in
            let separator = editingFormatter.decimalSeparator ?? "."
            var cleaned = raw.replacingOccurrences(of: ".", with: separator).replacingOccurrences(of: ",", with: separator)
            cleaned = cleaned.filter { $0.isNumber || String($0) == separator || $0 == "-" }
            // one separator, one leading minus
            var seen = false
            cleaned = String(cleaned.enumerated().filter { i, ch in
                if String(ch) == separator { if seen || fractionDigits.upperBound == 0 { return false }; seen = true }
                if ch == "-" && i != 0 { return false }
                return true
            }.map(\.element))
            if let idx = cleaned.firstIndex(of: Character(separator)) {
                let frac = cleaned[cleaned.index(after: idx)...]
                if frac.count > fractionDigits.upperBound { cleaned = String(cleaned.prefix(cleaned.distance(from: cleaned.startIndex, to: idx) + 1 + fractionDigits.upperBound)) }
            }
            return cleaned
        }
        var rules = options.rules
        if let range { rules += KitoRule.range(range, locale: locale) }
        rules.append(KitoRule(id: "inputkit.number", message: KitoLocalization.string("number.invalid", "Enter a valid number")) { [editingFormatter] in editingFormatter.number(from: $0) != nil })
        field.options.rules = rules
        if let currencyCode {
            let symbol = KitoCountryDatabase.all.first { $0.currencyCode == currencyCode }?.currencySymbol ?? currencyCode
            switch currencyPosition {
            case .prefix: if options.leading == nil { field.options.leading = .text(symbol) }
            case .suffix: if options.trailing == nil { field.options.trailing = .text(symbol) }
            case .none: break
            }
        }
        if let unitSuffix, options.trailing == nil { field.options.trailing = .text(unitSuffix) }
        if let step, options.trailing == nil, unitSuffix == nil {
            field.options.trailing = .custom { stepper(step) }
        }
        return field
            .onFocusChange { isFocused in
                focused = isFocused
                if !isFocused { reformat() }
                options.onFocusChange?(isFocused)
            }
            .onChange(of: text) { newText in
                let parsed = editingFormatter.number(from: newText)?.doubleValue
                if parsed != value { value = parsed }
            }
            .onChange(of: value) { newValue in
                let parsed = editingFormatter.number(from: text)?.doubleValue
                if newValue != parsed { text = newValue.map { editingFormatter.string(from: $0 as NSNumber) ?? "" } ?? "" }
            }
            .onAppear { if let value { text = focused ? (editingFormatter.string(from: value as NSNumber) ?? "") : (formatter.string(from: value as NSNumber) ?? "") } }
    }

    private func reformat() {
        guard let value else { return }
        text = formatter.string(from: value as NSNumber) ?? text
        // Editing again: strip grouping/currency so the raw number is editable.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {}
    }

    private func stepper(_ step: Double) -> some View {
        HStack(spacing: 2) {
            Button { adjust(-step) } label: { Image(systemName: "minus").frame(width: 28, height: 28) }
            Button { adjust(step) } label: { Image(systemName: "plus").frame(width: 28, height: 28) }
        }
        .buttonStyle(.plain)
        .font(.body.weight(.semibold))
    }

    private func adjust(_ delta: Double) {
        var next = (value ?? 0) + delta
        if let range { next = min(max(next, range.lowerBound), range.upperBound) }
        value = next
        text = editingFormatter.string(from: next as NSNumber) ?? ""
    }

    // MARK: Fluent

    private func mutating(_ change: (inout KitoNumberField) -> Void) -> KitoNumberField { var c = self; change(&c); return c }
    /// Whole numbers only (number pad keyboard).
    public func integer() -> KitoNumberField { mutating { $0.fractionDigits = 0...0 } }
    public func fractionDigits(_ digits: ClosedRange<Int>) -> KitoNumberField { mutating { $0.fractionDigits = digits } }
    public func groupsThousands(_ enabled: Bool) -> KitoNumberField { mutating { $0.groups = enabled } }
    public func range(_ range: ClosedRange<Double>) -> KitoNumberField { mutating { $0.range = range } }
    /// Plus/minus buttons in the trailing slot.
    public func stepper(_ step: Double = 1) -> KitoNumberField { mutating { $0.step = step } }
    public func locale(_ locale: Locale) -> KitoNumberField { mutating { $0.locale = locale } }
    /// Formats as currency when not editing and shows the symbol as the leading accessory.
    public func currency(_ code: String) -> KitoNumberField { mutating { $0.currencyCode = code; $0.fractionDigits = 2...2 } }
    public func currency(of country: KitoCountry) -> KitoNumberField { currency(country.currencyCode ?? "USD") }
    /// Where the currency symbol sits; `.prefix` (the default) matches `currency(_:)`'s own accessory.
    public func currencyPosition(_ position: KitoCurrencyPosition) -> KitoNumberField { mutating { $0.currencyPosition = position } }
    /// Unit shown after the value, e.g. "kg".
    public func unit(_ suffix: String) -> KitoNumberField { mutating { $0.unitSuffix = suffix } }
}

/// Currency preset of `KitoNumberField`: two decimals, symbol prefix, grouping.
public struct KitoCurrencyField: View, KitoFieldConfigurable {
    private var base: KitoNumberField
    public var options: KitoFieldOptions { get { base.options } set { base.options = newValue } }

    public init(_ label: String? = "Amount", value: Binding<Double?>, currencyCode: String = "USD", prompt: String? = "0.00") {
        base = KitoNumberField(label, value: value, prompt: prompt).currency(currencyCode)
    }

    public init(_ label: String? = "Amount", value: Binding<Double?>, country: KitoCountry, prompt: String? = "0.00") {
        self.init(label, value: value, currencyCode: country.currencyCode ?? "USD", prompt: prompt)
    }

    /// Keeps the raw amount as a formatted string in your own binding (e.g. a view model that
    /// stores amounts as text rather than `Double`) instead of a `Double?`. Round-trips through
    /// the same locale-aware formatter the field itself displays with.
    public init(_ label: String? = "Amount", text: Binding<String>, currencyCode: String = "USD", prompt: String? = "0.00") {
        let formatter = Self.bridgeFormatter()
        base = KitoNumberField(label, value: Self.bridge(text, formatter: formatter), prompt: prompt).currency(currencyCode)
    }

    static func bridgeFormatter() -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = .autoupdatingCurrent
        f.usesGroupingSeparator = true
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }

    /// Bridges a `Binding<String>` to the `Binding<Double?>` `KitoNumberField` itself needs,
    /// parsing/formatting with `formatter` on every read/write. Extracted so the round-trip
    /// (string → double → string) is unit-testable without hosting a view.
    static func bridge(_ text: Binding<String>, formatter: NumberFormatter) -> Binding<Double?> {
        Binding<Double?>(
            get: { formatter.number(from: text.wrappedValue)?.doubleValue },
            set: { text.wrappedValue = $0.map { formatter.string(from: $0 as NSNumber) ?? "" } ?? "" }
        )
    }

    public var body: some View { base }

    public func range(_ range: ClosedRange<Double>) -> KitoCurrencyField { var c = self; c.base = c.base.range(range); return c }

    /// A currency-picker menu in any slot (trailing by default) — a flag + code + chevron, or
    /// your own label per option.
    ///
    /// ```swift
    /// KitoCurrencyField(text: $amount, currencyCode: currency)
    ///     .currencySelector(options, selected: $currency) { option in
    ///         MyCurrencyFlagLabel(option: option)
    ///     }
    /// ```
    public func currencySelector<Label: View>(_ options: [KitoCurrencyOption], selected: Binding<String>, placement: KitoAccessoryPlacement = .trailing, @ViewBuilder label: @escaping (KitoCurrencyOption) -> Label) -> KitoCurrencyField {
        var c = self
        c.base = c.base.accessory(Self.currencyMenu(options, selected: selected, label: label), placement: placement)
        return c
    }

    /// `currencySelector(_:selected:placement:label:)` with a built-in "code, chevron" label.
    public func currencySelector(_ options: [KitoCurrencyOption], selected: Binding<String>, placement: KitoAccessoryPlacement = .trailing) -> KitoCurrencyField {
        currencySelector(options, selected: selected, placement: placement) { option in KitoDefaultCurrencyLabel(option: option) }
    }

    private static func currencyMenu<Label: View>(_ options: [KitoCurrencyOption], selected: Binding<String>, @ViewBuilder label: @escaping (KitoCurrencyOption) -> Label) -> KitoAccessory {
        .menu(
            label: {
                if let current = options.first(where: { $0.code == selected.wrappedValue }) {
                    label(current)
                } else {
                    Text(selected.wrappedValue)
                }
            },
            content: {
                ForEach(options) { option in
                    Button { selected.wrappedValue = option.code } label: {
                        Text("\(option.resolvedSymbol) \(option.code)")
                    }
                }
            }
        )
    }
}
