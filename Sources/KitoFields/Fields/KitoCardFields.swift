//
//  KitoCardFields.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// Payment card brands detected from the number prefix.
public enum KitoCardBrand: String, CaseIterable, Sendable {
    case visa, mastercard, amex, discover, dinersClub, jcb, unionPay, unknown

    public var displayName: String {
        switch self {
        case .visa: return "Visa"
        case .mastercard: return "Mastercard"
        case .amex: return "American Express"
        case .discover: return "Discover"
        case .dinersClub: return "Diners Club"
        case .jcb: return "JCB"
        case .unionPay: return "UnionPay"
        case .unknown: return "Card"
        }
    }

    /// Short label used in the field badge.
    public var badge: String {
        switch self {
        case .visa: return "VISA"
        case .mastercard: return "MC"
        case .amex: return "AMEX"
        case .discover: return "DISC"
        case .dinersClub: return "DC"
        case .jcb: return "JCB"
        case .unionPay: return "UP"
        case .unknown: return ""
        }
    }

    /// Digit grouping for display.
    public var mask: String {
        switch self {
        case .amex: return "#### ###### #####"
        case .dinersClub: return "#### ###### ####"
        default: return "#### #### #### ####"
        }
    }

    public var numberLength: ClosedRange<Int> {
        switch self {
        case .amex: return 15...15
        case .dinersClub: return 14...16
        default: return 16...16
        }
    }

    public var cvvLength: Int { self == .amex ? 4 : 3 }

    /// Detects the brand from the digits typed so far.
    public static func detect(_ number: String) -> KitoCardBrand {
        let d = number.asciiDigits
        guard !d.isEmpty else { return .unknown }
        if d.hasPrefix("4") { return .visa }
        if d.hasPrefix("34") || d.hasPrefix("37") { return .amex }
        if let two = Int(d.prefix(2)), (51...55).contains(two) { return .mastercard }
        if let four = Int(d.prefix(4)), (2221...2720).contains(four) { return .mastercard }
        if d.hasPrefix("6011") || d.hasPrefix("65") || (Int(d.prefix(3)).map { (644...649).contains($0) } ?? false) { return .discover }
        if d.hasPrefix("36") || d.hasPrefix("38") || d.hasPrefix("39") || d.hasPrefix("300") || d.hasPrefix("305") { return .dinersClub }
        if let four = Int(d.prefix(4)), (3528...3589).contains(four) { return .jcb }
        if d.hasPrefix("62") { return .unionPay }
        return .unknown
    }

    /// Luhn checksum.
    public static func passesLuhn(_ number: String) -> Bool {
        let digits = number.asciiDigits.compactMap { Int(String($0)) }
        guard digits.count >= 12 else { return false }
        var sum = 0
        for (i, d) in digits.reversed().enumerated() {
            if i % 2 == 1 { let dd = d * 2; sum += dd > 9 ? dd - 9 : dd } else { sum += d }
        }
        return sum % 10 == 0
    }
}

/// Card number with live brand detection, brand-specific grouping and Luhn validation.
///
/// ```swift
/// KitoCardNumberField(number: $number)
///     .onBrandChange { brand in cvvLength = brand.cvvLength }
/// ```
public struct KitoCardNumberField: View, KitoFieldConfigurable {
    private var base: KitoTextField
    private var onBrandChange: ((KitoCardBrand) -> Void)?
    @Binding private var number: String

    public var options: KitoFieldOptions { get { base.options } set { base.options = newValue } }

    public init(_ label: String? = "Card number", number: Binding<String>, prompt: String? = "1234 5678 9012 3456") {
        _number = number
        base = KitoTextField(label, text: number, prompt: prompt)
        base.options.keyboard = .numberPad
        base.options.contentType = .creditCardNumber
        base.options.disablesAutocorrection = true
        base.options.rules = [.luhn()]
        base.options.validationTrigger = .onBlur
    }

    public var brand: KitoCardBrand { KitoCardBrand.detect(number) }

    public var body: some View {
        var field = base
        let brand = self.brand
        field.options.mask = brand.mask
        field.options.characterLimit = brand.mask.count
        field.options.leading = .reactive { ctx in
            HStack(spacing: 6) {
                Image(systemName: "creditcard")
                    .font(.system(size: ctx.theme.iconSize))
                    .foregroundColor(ctx.iconColor)
                if brand != .unknown {
                    Text(brand.badge)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(ctx.theme.borderColor.opacity(0.45)))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(ctx.theme.motion.pop, value: brand)
        }
        // The mask handles formatting on iOS; on other platforms format via transform.
        #if !os(iOS)
        field.options.transform = { KitoPhoneFormatter().apply(mask: brand.mask, to: String($0.asciiDigits.prefix(brand.numberLength.upperBound))) }
        #endif
        var rules = base.options.rules
        rules.append(KitoRule(id: "inputkit.card.length", message: KitoLocalization.string("card.invalid", "Enter a valid card number")) { brand.numberLength.contains($0.asciiDigits.count) })
        field.options.rules = rules
        return field.onChange(of: brand) { onBrandChange?($0) }
    }

    public func onBrandChange(_ handler: @escaping (KitoCardBrand) -> Void) -> KitoCardNumberField { var c = self; c.onBrandChange = handler; return c }
}

/// MM/YY expiry with real-month and not-expired validation.
public struct KitoCardExpiryField: View, KitoFieldConfigurable {
    private var base: KitoTextField
    public var options: KitoFieldOptions { get { base.options } set { base.options = newValue } }

    public init(_ label: String? = "Expiry", text: Binding<String>, prompt: String? = "MM/YY") {
        base = KitoTextField(label, text: text, prompt: prompt)
        base.options.keyboard = .numberPad
        base.options.disablesAutocorrection = true
        base.options.mask = "##/##"
        base.options.characterLimit = 5
        base.options.rules = KitoRule.cardExpiry()
        base.options.leading = .systemImage("calendar")
        #if !os(iOS)
        base.options.transform = { KitoPhoneFormatter().apply(mask: "##/##", to: String($0.asciiDigits.prefix(4))) }
        #endif
    }

    public var body: some View { base }

    /// "MM/YY" → (month, fourDigitYear) when well-formed.
    public static func components(_ text: String) -> (month: Int, year: Int)? {
        let d = text.asciiDigits
        guard d.count == 4, let m = Int(d.prefix(2)), let y = Int(d.suffix(2)), (1...12).contains(m) else { return nil }
        return (m, 2000 + y)
    }

    public static func isExpired(month: Int, year: Int, now: Date = Date()) -> Bool {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year, .month], from: now)
        guard let y = comps.year, let m = comps.month else { return false }
        return year < y || (year == y && month < m)
    }
}

/// 3- or 4-digit security code, hidden by default.
public struct KitoCVVField: View, KitoFieldConfigurable {
    private var base: KitoTextField
    public var options: KitoFieldOptions { get { base.options } set { base.options = newValue } }

    public init(_ label: String? = "CVV", text: Binding<String>, length: Int = 3, prompt: String? = "•••") {
        base = KitoTextField(label, text: text, prompt: prompt)
        base.secure = KitoSecureEntryOptions(revealable: true)
        base.options.keyboard = .numberPad
        base.options.disablesAutocorrection = true
        base.options.characterLimit = length
        base.options.transform = { $0.asciiDigits }
        base.options.rules = [.exactLength(length, message: KitoLocalization.string("card.cvv.invalid", "Enter a valid security code"))]
        base.options.leading = .systemImage("lock.shield")
    }

    public var body: some View { base }
}
