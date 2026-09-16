//
//  KitoEmailField.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// Email preset: email keyboard and autofill, no autocapitalization or autocorrection,
/// whitespace stripped as you type, `.email` rule applied on blur.
///
/// ```swift
/// KitoEmailField(text: $email)
///     .required()
///     .leadingIcon("envelope")
/// ```
public struct KitoEmailField: View, KitoFieldConfigurable {
    private var base: KitoTextField

    public var options: KitoFieldOptions {
        get { base.options }
        set { base.options = newValue }
    }

    public init(_ label: String? = "Email", text: Binding<String>, prompt: String? = "name@example.com") {
        base = KitoTextField(label, text: text, prompt: prompt)
        base.options.keyboard = .emailAddress
        base.options.contentType = .emailAddress
        base.options.autocapitalization = .never
        base.options.disablesAutocorrection = true
        base.options.rules = [.email]
        base.options.validationTrigger = .onBlur
        base.options.transform = { $0.filter { !$0.isWhitespace } }
    }

    public var body: some View { base }

    /// Lowercases input as it is typed.
    public func lowercased(_ enabled: Bool = true) -> KitoEmailField {
        var copy = self
        copy.base.options.transform = enabled
            ? { $0.filter { !$0.isWhitespace }.lowercased() }
            : { $0.filter { !$0.isWhitespace } }
        return copy
    }
}
