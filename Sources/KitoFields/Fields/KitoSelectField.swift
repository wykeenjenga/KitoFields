//
//  KitoSelectField.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// One choice in a `KitoSelectField`.
public struct KitoSelectOption: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let systemImage: String?

    public init(id: String? = nil, _ title: String, subtitle: String? = nil, systemImage: String? = nil) {
        self.id = id ?? title
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }
}

/// Dropdown-style field. Opens a searchable sheet (or a menu) and shows the chosen option inline.
///
/// ```swift
/// KitoSelectField("Delivery speed", selection: $speed, options: [
///     KitoSelectOption("Standard", subtitle: "3–5 days", systemImage: "tortoise"),
///     KitoSelectOption("Express", subtitle: "Tomorrow", systemImage: "hare"),
/// ])
/// .required()
/// ```
public struct KitoSelectField: View, KitoFieldConfigurable {
    public var options = KitoFieldOptions()
    @Binding private var selection: KitoSelectOption?
    private let choices: [KitoSelectOption]
    private var usesMenu = false
    private var searchable = true
    private var onChange: ((KitoSelectOption) -> Void)?

    @State private var showsSheet = false
    @State private var presentation = KitoValidationPresentation()
    @State private var lastReported: KitoValidationState?
    @Environment(\.kitoFieldTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public init(_ label: String? = nil, selection: Binding<KitoSelectOption?>, options choices: [KitoSelectOption]) {
        _selection = selection
        self.choices = choices
        options.label = label
    }

    /// String-based convenience: options are plain titles.
    public init(_ label: String? = nil, selection: Binding<String?>, options titles: [String]) {
        _selection = Binding(
            get: { selection.wrappedValue.map { KitoSelectOption($0) } },
            set: { selection.wrappedValue = $0?.title }
        )
        self.choices = titles.map { KitoSelectOption($0) }
        options.label = label
    }

    private var validationState: KitoValidationState {
        if let external = options.externalError { return .invalid([external]) }
        if options.isRequired && selection == nil { return .invalid([options.requiredMessage]) }
        return selection == nil ? .idle : .valid
    }

    private var displayedErrors: [String] {
        if let external = options.externalError { return [external] }
        guard presentation.shouldShowErrors(for: options.validationTrigger) else { return [] }
        return validationState.errors
    }

    public var body: some View {
        var resolved = options
        resolved.placeholder = options.placeholder ?? KitoLocalization.string("select.placeholder", "Select an option")
        return KitoFieldCore(
            options: resolved,
            isFocused: showsSheet,
            isEmpty: selection == nil,
            errors: displayedErrors,
            isSuccess: options.showsSuccessIndicator && selection != nil,
            leadingOverride: nil,
            trailingExtras: trailing,
            input: input,
            footer: EmptyView?.none
        )
        .onChange(of: selection) { _ in
            presentation.didEdit()
            if let selection { onChange?(selection) }
            report()
        }
        .onChange(of: showsSheet) { open in if !open { presentation.didBlur() } }
        .onChange(of: options.revealTrigger?.wrappedValue) { _ in presentation.didSubmit() }
        .onAppear(perform: report)
        .sheet(isPresented: $showsSheet) { OptionsSheet(selection: $selection, choices: choices, searchable: searchable, title: options.label ?? "").kitoFieldTheme(theme) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(options.accessibilityLabel ?? options.label ?? "")
        .accessibilityValue(selection?.title ?? "")
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder private var input: some View {
        #if os(watchOS) || os(tvOS)
        Button { showsSheet = true } label: { valueLabel }.buttonStyle(.plain)
            .kitoAccessibilityIdentifier(options.accessibilityIdentifier)
        #else
        if usesMenu {
            Menu {
                ForEach(choices) { option in
                    Button { selection = option } label: {
                        if let symbol = option.systemImage { Label(option.title, systemImage: symbol) } else { Text(option.title) }
                    }
                }
            } label: { valueLabel }
            .kitoAccessibilityIdentifier(options.accessibilityIdentifier)
        } else {
            Button { showsSheet = true } label: { valueLabel }.buttonStyle(.plain).disabled(!isEnabled)
                .kitoAccessibilityIdentifier(options.accessibilityIdentifier)
        }
        #endif
    }

    private var valueLabel: some View {
        HStack(spacing: 8) {
            if let selection {
                if let symbol = selection.systemImage {
                    Image(systemName: symbol).font(.system(size: theme.iconSize)).foregroundColor(theme.iconColor)
                }
                Text(selection.title).font(theme.font).foregroundColor(theme.textColor).lineLimit(1)
                    .id(selection.id).transition(.opacity.combined(with: .move(edge: .bottom)))
                if let subtitle = selection.subtitle {
                    Text(subtitle).font(theme.helperFont).foregroundColor(theme.helperColor).lineLimit(1)
                }
            } else {
                Text(" ").font(theme.font)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .animation(theme.motion.pop, value: selection)
    }

    private var trailing: [AnyView] {
        var views: [AnyView] = []
        if options.showsClearButton, selection != nil, isEnabled {
            views.append(KitoFieldControls.clearButton(theme: theme) { selection = nil })
        }
        if !displayedErrors.isEmpty && options.showsErrorIndicator && options.externalError == nil {
            views.append(KitoFieldControls.validationIcon(isError: true, theme: theme))
        } else if options.showsSuccessIndicator && selection != nil {
            views.append(KitoFieldControls.validationIcon(isError: false, theme: theme))
        }
        views.append(AnyView(
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: theme.iconSize * 0.7, weight: .semibold))
                .foregroundColor(theme.iconColor)
        ))
        return views
    }

    private func report() {
        let state = validationState
        guard state != lastReported else { return }
        lastReported = state
        options.isValidBinding?.wrappedValue = state.isValid && (!options.isRequired || selection != nil)
        options.onValidationChange?(state)
    }

    private struct OptionsSheet: View {
        @Binding var selection: KitoSelectOption?
        let choices: [KitoSelectOption]
        let searchable: Bool
        let title: String
        @State private var query = ""
        @Environment(\.dismiss) private var dismiss
        @Environment(\.kitoFieldTheme) private var theme

        private var filtered: [KitoSelectOption] {
            let q = KitoCountryPicker.fold(query.trimmingCharacters(in: .whitespaces))
            guard !q.isEmpty else { return choices }
            return choices.filter { KitoCountryPicker.fold($0.title).contains(q) || KitoCountryPicker.fold($0.subtitle ?? "").contains(q) }
        }

        var body: some View {
            NavigationView {
                Group {
                    if filtered.isEmpty {
                        Text(KitoLocalization.string("select.noResults", "No matches")).foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(filtered) { option in
                            Button { selection = option; dismiss() } label: {
                                HStack(spacing: 12) {
                                    if let symbol = option.systemImage { Image(systemName: symbol).frame(width: 24) }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(option.title).foregroundColor(.primary)
                                        if let subtitle = option.subtitle { Text(subtitle).font(theme.helperFont).foregroundColor(.secondary) }
                                    }
                                    Spacer()
                                    if option == selection { Image(systemName: "checkmark").font(.body.weight(.semibold)).foregroundColor(.accentColor) }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .navigationTitle(title)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button(KitoLocalization.string("picker.cancel", "Cancel")) { dismiss() } } }
                .modifier(SearchIf(enabled: searchable && choices.count > 6, query: $query))
            }
            .modifier(SelectSheetDetents())
        }

        private struct SearchIf: ViewModifier {
            let enabled: Bool
            @Binding var query: String
            func body(content: Content) -> some View {
                if enabled { content.searchable(text: $query, prompt: Text(KitoLocalization.string("select.search", "Search options"))) } else { content }
            }
        }

        private struct SelectSheetDetents: ViewModifier {
            func body(content: Content) -> some View {
                #if os(tvOS)
                content
                #else
                if #available(iOS 16.0, macOS 13.0, watchOS 9.0, visionOS 1.0, *) { content.presentationDetents([.medium, .large]) } else { content }
                #endif
            }
        }
    }

    private func mutating(_ change: (inout KitoSelectField) -> Void) -> KitoSelectField { var c = self; change(&c); return c }
    /// Use a compact menu instead of the searchable sheet.
    public func menu(_ enabled: Bool = true) -> KitoSelectField { mutating { $0.usesMenu = enabled } }
    public func searchable(_ enabled: Bool) -> KitoSelectField { mutating { $0.searchable = enabled } }
    public func onSelectionChange(_ handler: @escaping (KitoSelectOption) -> Void) -> KitoSelectField { mutating { $0.onChange = handler } }
}
