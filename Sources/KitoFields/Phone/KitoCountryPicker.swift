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
    @State private var recentSearches: [String] = []
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
                .onAppear {
                    recents = KitoCountryRecents.load(key: configuration.recentsStorageKey, limit: configuration.recentsLimit)
                    recentSearches = KitoCountryRecents.loadSearches(key: configuration.recentsStorageKey, limit: configuration.recentSearchesLimit)
                }
                .onSubmit(of: .search) { KitoCountryRecents.recordSearch(query, key: configuration.recentsStorageKey, limit: configuration.recentSearchesLimit) }
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
                Text(configuration.strings.noResultsHint).font(theme.helperFont).foregroundColor(.secondary).multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                if query.isEmpty {
                    if configuration.showsRecentSearches, !recentSearches.isEmpty {
                        Section(configuration.strings.recentSearchesSection) {
                            chips(recentSearches.map { term in Chip(id: "q-\(term)", label: term, symbol: "clock.arrow.circlepath") { query = term } })
                        }
                    }
                    if configuration.showsRecents, !recents.isEmpty {
                        let visible = Array(recents.filter { countries.contains($0) }.prefix(configuration.recentsLimit))
                        Section(configuration.strings.recentSection) {
                            if configuration.suggestionStyle == .chips {
                                chips(visible.map { c in Chip(id: c.isoCode, label: c.localizedName(in: configuration.locale ?? .autoupdatingCurrent), flag: c) { select(c) } })
                            } else {
                                ForEach(visible) { row($0) }
                            }
                        }
                    }
                    if configuration.showsCurrentRegion, let current = currentRegion {
                        Section(configuration.strings.currentRegionSection) { row(current) }
                    }
                    if !preferred.isEmpty {
                        let visible = Array(preferred.prefix(configuration.suggestedLimit))
                        Section(configuration.strings.preferredSection) {
                            if configuration.suggestionStyle == .chips {
                                chips(visible.map { c in Chip(id: c.isoCode, label: c.localizedName(in: configuration.locale ?? .autoupdatingCurrent), flag: c) { select(c) } })
                            } else {
                                ForEach(visible) { row($0) }
                            }
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

    private struct Chip: Identifiable {
        let id: String
        let label: String
        var symbol: String? = nil
        var flag: KitoCountry? = nil
        let action: () -> Void
    }

    /// Horizontally scrolling capsule chips.
    private func chips(_ items: [Chip]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items) { chip in
                    Button(action: chip.action) {
                        HStack(spacing: 6) {
                            if let flag = chip.flag { KitoFlag(country: flag, style: configuration.flagStyle == .hidden ? .hidden : .emoji, size: 16) }
                            if let symbol = chip.symbol { Image(systemName: symbol).font(.caption) }
                            Text(chip.label).font(theme.labelFont).lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(theme.filledBackgroundColor))
                        .overlay(Capsule().stroke(theme.borderColor.opacity(0.6), lineWidth: 1))
                        .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .listRowBackground(Color.clear)
    }

    private func select(_ country: KitoCountry) {
        selection = country
        if configuration.showsRecents {
            KitoCountryRecents.record(country, key: configuration.recentsStorageKey, limit: configuration.recentsLimit)
        }
        if configuration.showsRecentSearches, !query.trimmingCharacters(in: .whitespaces).isEmpty {
            KitoCountryRecents.recordSearch(query, key: configuration.recentsStorageKey, limit: configuration.recentSearchesLimit)
        }
        onSelect?(country)
        dismiss()
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
            select(country)
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

/// A single row: flag, localized name, optional currency, dial code, checkmark when selected.
public struct KitoCountryRow: View {
    public var country: KitoCountry
    public var isSelected: Bool
    public var configuration: KitoCountryPickerConfiguration
    public var highlight: String = ""

    @Environment(\.kitoFieldTheme) private var theme

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
                        .font(theme.helperFont)
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
        UserDefaults.standard.removeObject(forKey: key + ".searches")
    }

    // MARK: Recent search terms

    public static func loadSearches(key: String = defaultKey, limit: Int = 4) -> [String] {
        Array((UserDefaults.standard.stringArray(forKey: key + ".searches") ?? []).prefix(limit))
    }

    public static func recordSearch(_ term: String, key: String = defaultKey, limit: Int = 4) {
        let trimmed = term.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var terms = UserDefaults.standard.stringArray(forKey: key + ".searches") ?? []
        terms.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        terms.insert(trimmed, at: 0)
        UserDefaults.standard.set(Array(terms.prefix(max(limit, 1))), forKey: key + ".searches")
    }
}

/// How the Recent and Suggested sections are drawn.
public enum KitoSuggestionStyle: Sendable {
    /// Horizontally scrolling capsule chips (default).
    case chips
    /// Ordinary list rows.
    case rows
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
    public var recentSearchesSection = KitoLocalization.string("picker.recentSearches", "Recent searches")
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
    public var recentsLimit = 4
    /// Chips or rows for the Recent and Suggested sections.
    public var suggestionStyle: KitoSuggestionStyle = .chips
    /// Maximum number of preferred countries shown in Suggested.
    public var suggestedLimit = 4
    /// "Recent searches" chips that refill the search box.
    public var showsRecentSearches = true
    public var recentSearchesLimit = 4
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
