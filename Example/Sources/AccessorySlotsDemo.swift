//
//  AccessorySlotsDemo.swift
//  KitoFieldsExample
//
//  Created by Wycliff Njenga on 22/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI
import KitoFields

/// Reproduces a checkout screen's phone, amount and description fields using only accessory
/// slots, interactive accessories and accessibility identifiers — the three designs
/// `feat/accessory-slots-and-identifiers` was built to cover.
struct AccessorySlotsDemo: View {
    private let currencies = [
        KitoCurrencyOption(code: "USD", symbol: "$"),
        KitoCurrencyOption(code: "KES", symbol: "KSh"),
        KitoCurrencyOption(code: "EUR", symbol: "€"),
    ]

    @State private var phone: KitoPhoneNumber?
    @State private var amountText = ""
    @State private var currencyTrailing = "USD"
    @State private var amountLeadingText = ""
    @State private var currencyLeading = "KES"
    @State private var notes = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Phone number — flag, dial code and chevron in the leading slot, a divider, then the input.")
                    .font(.footnote).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                KitoPhoneField("Phone number", phoneNumber: $phone)
                    .required()
                    .accessibilityIdentifier("checkout.details.phone")

                Text("Amount — currency menu in the trailing slot (default placement).")
                    .font(.footnote).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                KitoCurrencyField("Amount", text: $amountText, currencyCode: currencyTrailing)
                    .currencyPosition(.none)
                    .currencySelector(currencies, selected: $currencyTrailing)
                    .accessibilityIdentifier("checkout.details.amount")
                Text("Sends: \(amountText.isEmpty ? "—" : amountText)")
                    .font(.caption.monospaced()).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Amount — the same currency menu, moved to the leading slot instead.")
                    .font(.footnote).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                KitoCurrencyField("Amount", text: $amountLeadingText, currencyCode: currencyLeading)
                    .currencySelector(currencies, selected: $currencyLeading, placement: .leading)

                Text("Description — optional, multi-line, \"(optional)\" styled like the label but grey.")
                    .font(.footnote).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                KitoTextField("Description", text: $notes, prompt: "e.g. Deposit for Diani beach package")
                    .optional()
                    .multiline(1...3)
                    .accessibilityIdentifier("checkout.details.notes")
            }
            .padding()
        }
        .navigationTitle("Accessory slots")
        .navigationBarTitleDisplayMode(.inline)
    }
}
