//
//  KitoPresetFields.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

// MARK: - Name

/// Person-name preset: words capitalization, name autofill, letters/spaces/hyphens only.
public struct KitoNameField: View, KitoFieldConfigurable {
    private var base: KitoTextField
    public var options: KitoFieldOptions { get { base.options } set { base.options = newValue } }

    public init(_ label: String? = KitoLocalization.string("name.label", "Full name"), text: Binding<String>, prompt: String? = nil) {
        base = KitoTextField(label, text: text, prompt: prompt)
        base.options.contentType = .name
        base.options.autocapitalization = .words
        base.options.disablesAutocorrection = true
        base.options.rules = [.personName(), .minLength(2)]
        base.options.leading = .animatedSymbol("person", focused: "person.fill", motion: .bounce)
    }

    public var body: some View { base }

    /// Given or family name autofill instead of full name.
    public func part(_ part: KitoContentType) -> KitoNameField { var c = self; c.base.options.contentType = part; return c }
}

// MARK: - Username with availability check

/// Username preset with lowercase input, allowed-character validation and an optional async
/// availability check (debounced) that shows a spinner, then a tick or a "taken" error.
public struct KitoUsernameField: View, KitoFieldConfigurable {
    private var base: KitoTextField
    private var check: ((String) async -> Bool)?
    private var debounce: TimeInterval = 0.45
    @Binding private var text: String
    @State private var status: Status = .idle
    @State private var task: Task<Void, Never>?

    private enum Status: Equatable { case idle, checking, available, taken }

    public var options: KitoFieldOptions { get { base.options } set { base.options = newValue } }

    public init(_ label: String? = "Username", text: Binding<String>, prompt: String? = "yourname") {
        _text = text
        base = KitoTextField(label, text: text, prompt: prompt)
        base.options.contentType = .username
        base.options.autocapitalization = .never
        base.options.disablesAutocorrection = true
        base.options.rules = [.username()]
        base.options.transform = { $0.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" } }
        base.options.leading = .text("@")
        base.options.validationTrigger = .live
    }

    public var body: some View {
        var field = base
        switch status {
        case .checking:
            field.options.trailing = .custom { ProgressView().modifier(SmallControl()) }
        case .taken:
            field.options.externalError = KitoLocalization.string("username.taken", "That username is taken")
        case .available:
            field.options.helperText = field.options.helperText ?? KitoLocalization.string("username.available", "Username is available")
            field.options.showsSuccessIndicator = true
        case .idle:
            break
        }
        return field
            .onChange(of: text) { _ in schedule() }
    }

    private func schedule() {
        task?.cancel()
        guard let check, KitoRule.username().validate(text), !text.isEmpty else { status = .idle; return }
        status = .checking
        let candidate = text
        task = Task {
            try? await Task.sleep(nanoseconds: UInt64(debounce * 1_000_000_000))
            guard !Task.isCancelled else { return }
            let ok = await check(candidate)
            guard !Task.isCancelled, candidate == text else { return }
            status = ok ? .available : .taken
        }
    }

    /// Called after typing pauses; return true when the username is free.
    /// `debounce` is in seconds.
    public func availability(debounce: TimeInterval = 0.45, _ check: @escaping (String) async -> Bool) -> KitoUsernameField {
        var c = self; c.check = check; c.debounce = debounce; return c
    }
}

// MARK: - Search

/// Search preset: magnifier, clear button, no autocorrection, debounced `onSearch`.
public struct KitoSearchField: View, KitoFieldConfigurable {
    private var base: KitoTextField
    private var onSearch: ((String) -> Void)?
    private var debounce: TimeInterval = 0.3
    @Binding private var text: String
    @State private var task: Task<Void, Never>?

    public var options: KitoFieldOptions { get { base.options } set { base.options = newValue } }

    public init(text: Binding<String>, prompt: String? = KitoLocalization.string("search.placeholder", "Search")) {
        _text = text
        base = KitoTextField(nil, text: text, prompt: prompt)
        base.options.leading = .systemImage("magnifyingglass")
        base.options.showsClearButton = true
        base.options.disablesAutocorrection = true
        base.options.autocapitalization = .never
        base.options.keyboard = .webSearch
        base.options.validationTrigger = .never
    }

    public var body: some View {
        base.onChange(of: text) { value in
            task?.cancel()
            task = Task {
                try? await Task.sleep(nanoseconds: UInt64(debounce * 1_000_000_000))
                guard !Task.isCancelled else { return }
                onSearch?(value)
            }
        }
    }

    /// Fires after the user pauses typing.
    /// `debounce` is in seconds.
    public func onSearch(debounce: TimeInterval = 0.3, _ handler: @escaping (String) -> Void) -> KitoSearchField {
        var c = self; c.onSearch = handler; c.debounce = debounce; return c
    }
}

// MARK: - URL

public struct KitoURLField: View, KitoFieldConfigurable {
    private var base: KitoTextField
    public var options: KitoFieldOptions { get { base.options } set { base.options = newValue } }

    public init(_ label: String? = "Website", text: Binding<String>, prompt: String? = "https://example.com") {
        base = KitoTextField(label, text: text, prompt: prompt)
        base.options.keyboard = .url
        base.options.contentType = .url
        base.options.autocapitalization = .never
        base.options.disablesAutocorrection = true
        base.options.leading = .systemImage("link")
        base.options.rules = [.url()]
        base.options.transform = { $0.filter { !$0.isWhitespace } }
    }

    public var body: some View { base }
}

// MARK: - Text area

/// Multi-line text with a character counter.
public struct KitoTextArea: View, KitoFieldConfigurable {
    private var base: KitoTextField
    public var options: KitoFieldOptions { get { base.options } set { base.options = newValue } }

    public init(_ label: String? = nil, text: Binding<String>, prompt: String? = nil, lines: ClosedRange<Int> = 3...8, limit: Int? = 280) {
        base = KitoTextField(label, text: text, prompt: prompt)
        base.options.multilineRange = lines
        base.options.characterLimit = limit
        base.options.showsCharacterCounter = limit != nil
        base.options.counterStyle = .remaining
        base.options.characterLimitIsHard = false
    }

    public var body: some View { base }
}


/// `controlSize` is unavailable on tvOS and needs watchOS 9.
private struct SmallControl: ViewModifier {
    func body(content: Content) -> some View {
        #if os(tvOS) || os(watchOS)
        content.scaleEffect(0.8)
        #else
        content.controlSize(.small)
        #endif
    }
}
