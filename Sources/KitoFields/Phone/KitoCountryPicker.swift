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
    @State private var recents: [KitoCountry] = []
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
                .onAppear { recents = KitoCountryRecents.load(key: configuration.recentsStorageKey, limit: configuration.recentsLimit) }
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
                Text(configuration.strings.noResultsHint).font(.footnote).foregroundColor(.secondary).multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                if query.isEmpty {
                    if configuration.showsRecents, !recents.isEmpty {
                        Section(configuration.strings.recentSection) {
                            ForEach(recents.filter { countries.contains($0) }) { row($0) }
                        }
                    }
                    if configuration.showsCurrentRegion, let current = currentRegion {
                        Section(configuration.strings.currentRegionSection) { row(current) }
                    }
                    if !preferred.isEmpty {
                        Section(configuration.strings.preferredSection) {
                            ForEach(preferred) { row($0) }
                        }
                    }
                    if configuration.groupsAlphabetically {
                        ForEach(alphabeticalSections(results), id: \.letter) { section in
                            Section(section.letter) { ForEach(section.countries) { row($0) } }
                        }
                    } else {
                        Section(configuration.strings.allSection) { ForEach(results) { row($0) } }
                    }
                } else {
                    Section { ForEach(results) { row($0) } }
                }
            }
            .modifier(ListStyleModifier())
        }
    }

    private var currentRegion: KitoCountry? {
        let current = KitoCountryDatabase.current
        return countries.contains(current) ? current : nil
    }

    private struct LetterSection { let letter: String; let countries: [KitoCountry] }

    private func alphabeticalSections(_ countries: [KitoCountry]) -> [LetterSection] {
        let locale = configuration.locale ?? .autoupdatingCurrent
        var buckets: [String: [KitoCountry]] = [:]
        for country in countries {
            let name = country.localizedName(in: locale)
            let letter = name.first.map { String($0).folding(options: [.diacriticInsensitive, .caseInsensitive], locale: locale).uppercased() } ?? "#"
            buckets[letter, default: []].append(country)
        }
        return buckets.keys.sorted().map { LetterSection(letter: $0, countries: buckets[$0]!) }
    }

    private func row(_ country: KitoCountry) -> some View {
        Button {
            selection = country
            if configuration.showsRecents {
                KitoCountryRecents.record(country, key: configuration.recentsStorageKey, limit: configuration.recentsLimit)
            }
            onSelect?(country)
            dismiss()
        } label: {
            KitoCountryRow(country: country, isSelected: country == selection, configuration: configuration, highlight: query)
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
        let needle = Self.fold(q)
        let digits = q.asciiDigits
        let scored: [(KitoCountry, Int)] = sorted.compactMap { country in
            let name = Self.fold(country.localizedName(in: locale))
            let english = Self.fold(country.englishName)
            if name.hasPrefix(needle) || english.hasPrefix(needle) { return (country, 0) }
            if country.isoCode.lowercased() == needle { return (country, 1) }
            if !digits.isEmpty && country.dialCode.hasPrefix(digits) { return (country, 2) }
            if name.contains(needle) || english.contains(needle) { return (country, 3) }
            if let code = country.currencyCode, code.lowercased().hasPrefix(needle) { return (country, 4) }
            return nil
        }
        return scored.sorted { $0.1 < $1.1 }.map(\.0)
    }

    /// Lowercase, diacritic-insensitive ("Côte" matches "cote").
    static func fold(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive], locale: nil).lowercased()
    }

    // MARK: Platform shims

    private struct InlineTitle: ViewModifier {
        func body(content: Content) -> some View {
            #if os(iOS)
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
            #if os(iOS)
            content.listStyle(.insetGrouped)
            #else
            content.listStyle(.inset)
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

/// A single row: flag, localized name, optional currency, dial code, checkmark when selected.
public struct KitoCountryRow: View {
    public var country: KitoCountry
    public var isSelected: Bool
    public var configuration: KitoCountryPickerConfiguration
    public var highlight: String = ""

    public init(country: KitoCountry, isSelected: Bool, configuration: KitoCountryPickerConfiguration = KitoCountryPickerConfiguration(), highlight: String = "") {
        self.country = country
        self.isSelected = isSelected
        self.configuration = configuration
        self.highlight = highlight
    }

    public var body: some View {
        HStack(spacing: 12) {
            KitoFlag(country: country, style: configuration.flagStyle, size: 24)
            VStack(alignment: .leading, spacing: 2) {
                highlighted(country.localizedName(in: configuration.locale ?? .autoupdatingCurrent))
                    .foregroundColor(.primary)
                if configuration.showsCurrency, let code = country.currencyCode {
                    Text([code, country.currencySymbol].compactMap { $0 }.joined(separator: " · "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
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

    /// Bolds the part of the name that matches the search query.
    private func highlighted(_ name: String) -> Text {
        let needle = KitoCountryPicker.fold(highlight.trimmingCharacters(in: .whitespaces))
        guard !needle.isEmpty, let range = KitoCountryPicker.fold(name).range(of: needle),
              KitoCountryPicker.fold(name).count == name.count else { return Text(name) }
        let start = name.distance(from: KitoCountryPicker.fold(name).startIndex, to: range.lowerBound)
        let length = KitoCountryPicker.fold(name).distance(from: range.lowerBound, to: range.upperBound)
        let a = name.prefix(start)
        let b = name.dropFirst(start).prefix(length)
        let c = name.dropFirst(start + length)
        return Text(String(a)) + Text(String(b)).bold() + Text(String(c))
    }
}

/// Recently selected countries, persisted in UserDefaults.
public enum KitoCountryRecents {
    public static let defaultKey = "kitofields.recentCountries"

    public static func load(key: String = defaultKey, limit: Int = 5) -> [KitoCountry] {
        let codes = UserDefaults.standard.stringArray(forKey: key) ?? []
        return codes.prefix(limit).compactMap(KitoCountryDatabase.country(isoCode:))
    }

    public static func record(_ country: KitoCountry, key: String = defaultKey, limit: Int = 5) {
        var codes = UserDefaults.standard.stringArray(forKey: key) ?? []
        codes.removeAll { $0 == country.isoCode }
        codes.insert(country.isoCode, at: 0)
        UserDefaults.standard.set(Array(codes.prefix(max(limit, 1))), forKey: key)
    }

    public static func clear(key: String = defaultKey) {
        UserDefaults.standard.removeObject(forKey: key)
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
    public var recentSection = KitoLocalization.string("picker.recent", "Recent")
    public var currentRegionSection = KitoLocalization.string("picker.currentRegion", "Your region")
    public var noResultsHint = KitoLocalization.string("picker.noResultsHint", "Try the country name, ISO code, dial code or currency.")
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
    /// "Recent" section with the last selections, persisted across launches.
    public var showsRecents = true
    public var recentsLimit = 5
    /// UserDefaults key for recents; give each picker its own key to keep histories separate.
    public var recentsStorageKey = KitoCountryRecents.defaultKey
    /// "Your region" section with the device's current region.
    public var showsCurrentRegion = true
    /// Group the full list under A–Z headers instead of one long section.
    public var groupsAlphabetically = true
    /// Show the currency code and symbol under each country name.
    public var showsCurrency = false
    public init() {}
}
