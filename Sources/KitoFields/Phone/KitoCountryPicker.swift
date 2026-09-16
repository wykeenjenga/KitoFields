//
//  KitoCountryPicker.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// Searchable, localized list of regions. Presented by `KitoPhoneField`, or use it standalone.
public struct KitoCountryPicker: View {
    @Binding private var selection: KitoCountry
    private let countries: [KitoCountry]
    private let preferred: [KitoCountry]
    private let configuration: KitoCountryPickerConfiguration
    private let onSelect: ((KitoCountry) -> Void)?

    @State private var query = ""
    @Environment(\.dismiss) private var dismiss
    @Environment(\.kitoFieldTheme) private var theme

    public init(selection: Binding<KitoCountry>, countries: [KitoCountry] = KitoCountryDatabase.all, preferred: [KitoCountry] = [], configuration: KitoCountryPickerConfiguration = KitoCountryPickerConfiguration(), onSelect: ((KitoCountry) -> Void)? = nil) {
        _selection = selection
        self.countries = countries
        self.preferred = preferred
        self.configuration = configuration
        self.onSelect = onSelect
    }

    public var body: some View {
        NavigationView {
            list
                .navigationTitle(configuration.strings.title)
                .modifier(InlineTitle())
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(configuration.strings.cancel) { dismiss() }
                    }
                }
                .modifier(SearchModifier(query: $query, enabled: configuration.showsSearch, prompt: configuration.strings.searchPrompt))
        }
        .modifier(StackNavigationStyle())
    }

    @ViewBuilder private var list: some View {
        let results = filtered
        if results.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "magnifyingglass").font(.largeTitle).foregroundColor(.secondary)
                Text(configuration.strings.noResults).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                if query.isEmpty, !preferred.isEmpty {
                    Section(configuration.strings.preferredSection) {
                        ForEach(preferred) { row($0) }
                    }
                }
                Section(query.isEmpty && !preferred.isEmpty ? configuration.strings.allSection : "") {
                    ForEach(results) { row($0) }
                }
            }
            .modifier(ListStyleModifier())
        }
    }

    private func row(_ country: KitoCountry) -> some View {
        Button {
            selection = country
            onSelect?(country)
            dismiss()
        } label: {
            KitoCountryRow(country: country, isSelected: country == selection, configuration: configuration)
        }
        .buttonStyle(.plain)
    }

    private var filtered: [KitoCountry] {
        let locale = configuration.locale ?? .autoupdatingCurrent
        let sorted = configuration.sortsByLocalizedName
            ? countries.sorted { $0.localizedName(in: locale).localizedCaseInsensitiveCompare($1.localizedName(in: locale)) == .orderedAscending }
            : countries
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return sorted }
        let digits = q.asciiDigits
        return sorted.filter { country in
            country.localizedName(in: locale).localizedCaseInsensitiveContains(q)
                || country.englishName.localizedCaseInsensitiveContains(q)
                || country.isoCode.localizedCaseInsensitiveContains(q)
                || (!digits.isEmpty && country.dialCode.hasPrefix(digits))
        }
    }

    // MARK: Platform shims

    private struct InlineTitle: ViewModifier {
        func body(content: Content) -> some View {
            #if os(iOS) || os(watchOS) || os(visionOS)
            content.navigationBarTitleDisplayMode(.inline)
            #else
            content
            #endif
        }
    }

    private struct StackNavigationStyle: ViewModifier {
        func body(content: Content) -> some View {
            #if os(iOS)
            content.navigationViewStyle(.stack)
            #else
            content.frame(minWidth: 360, minHeight: 480)
            #endif
        }
    }

    private struct ListStyleModifier: ViewModifier {
        func body(content: Content) -> some View {
            #if os(iOS) || os(visionOS)
            content.listStyle(.insetGrouped)
            #elseif os(macOS)
            content.listStyle(.inset)
            #else
            content
            #endif
        }
    }

    private struct SearchModifier: ViewModifier {
        @Binding var query: String
        var enabled: Bool
        var prompt: String
        func body(content: Content) -> some View {
            if enabled {
                content.searchable(text: $query, placement: .automatic, prompt: Text(prompt))
            } else {
                content
            }
        }
    }
}

/// A single row: flag, localized name, dial code, checkmark when selected.
public struct KitoCountryRow: View {
    public var country: KitoCountry
    public var isSelected: Bool
    public var configuration: KitoCountryPickerConfiguration

    public init(country: KitoCountry, isSelected: Bool, configuration: KitoCountryPickerConfiguration = KitoCountryPickerConfiguration()) {
        self.country = country
        self.isSelected = isSelected
        self.configuration = configuration
    }

    public var body: some View {
        HStack(spacing: 12) {
            KitoFlag(country: country, style: configuration.flagStyle, size: 24)
            Text(country.localizedName(in: configuration.locale ?? .autoupdatingCurrent))
                .foregroundColor(.primary)
            Spacer()
            if configuration.showsDialCodes {
                Text(country.formattedDialCode)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.accentColor)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Text used by the picker. Override for localization.
public struct KitoCountryPickerStrings: Sendable {
    public var title = KitoLocalization.string("picker.title", "Select Country")
    public var searchPrompt = KitoLocalization.string("picker.searchPrompt", "Search by country or code")
    public var cancel = KitoLocalization.string("picker.cancel", "Cancel")
    public var noResults = KitoLocalization.string("picker.noResults", "No countries found")
    public var preferredSection = KitoLocalization.string("picker.preferred", "Suggested")
    public var allSection = KitoLocalization.string("picker.all", "All Countries")
    public init() {}
}

public struct KitoCountryPickerConfiguration: Sendable {
    public var showsSearch = true
    public var showsDialCodes = true
    public var flagStyle: KitoFlagStyle = .emoji
    public var sortsByLocalizedName = true
    /// Locale for country names; nil uses the device locale.
    public var locale: Locale? = nil
    public var strings = KitoCountryPickerStrings()
    public init() {}
}
