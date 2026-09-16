//
//  KitoLocalization.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import Foundation

/// Localization entry point. Every user-facing string in KitoFields goes through here.
///
/// Built-in languages: English, Swahili (`sw`) and French (`fr`). To add or override strings from
/// your app, set `provider`; return nil to fall back to the bundled translation.
///
/// ```swift
/// KitoLocalization.provider = { key, fallback in
///     NSLocalizedString("kito.\(key)", value: fallback, comment: "")
/// }
/// ```
public enum KitoLocalization {
    /// Optional hook consulted before the bundled `Localizable.strings`.
    public static var provider: ((_ key: String, _ fallback: String) -> String?)?

    /// The bundle holding KitoFields' resources (SwiftPM `Bundle.module` or the CocoaPods resource bundle).
    public static var bundle: Bundle {
        #if SWIFT_PACKAGE
        return .module
        #else
        let host = Bundle(for: BundleToken.self)
        if let url = host.url(forResource: "KitoFields", withExtension: "bundle"), let bundle = Bundle(url: url) {
            return bundle
        }
        return host
        #endif
    }

    /// Localized string for `key`, falling back to `fallback` (the English copy) when missing.
    public static func string(_ key: String, _ fallback: String) -> String {
        if let custom = provider?(key, fallback) { return custom }
        return bundle.localizedString(forKey: key, value: fallback, table: nil)
    }

    /// Localized, formatted string.
    public static func format(_ key: String, _ fallback: String, _ arguments: CVarArg...) -> String {
        String(format: string(key, fallback), locale: .current, arguments: arguments)
    }

    /// All keys defined in the given language, useful for parity tests and custom providers.
    public static func keys(forLanguage code: String) -> Set<String> {
        guard let path = bundle.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: code),
              let dictionary = NSDictionary(contentsOfFile: path) as? [String: String] else { return [] }
        return Set(dictionary.keys)
    }
}

private final class BundleToken {}
