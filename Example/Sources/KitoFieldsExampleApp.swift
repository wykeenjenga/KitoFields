//
//  KitoFieldsExampleApp.swift
//  KitoFieldsExample
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI
import KitoFields

@main
struct KitoFieldsExampleApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

/// Live-adjustable appearance shared by every screen.
final class AppearanceModel: ObservableObject {
    enum Style: String, CaseIterable, Identifiable {
        case outlined, filled, underlined, floatingLabel, plain
        var id: String { rawValue }
        var title: String {
            switch self {
            case .outlined: return "Outlined"
            case .filled: return "Filled"
            case .underlined: return "Underlined"
            case .floatingLabel: return "Floating"
            case .plain: return "Plain"
            }
        }
    }
    enum Shape: String, CaseIterable, Identifiable {
        case rounded, capsule, rectangle, underline
        var id: String { rawValue }
        var fieldShape: KitoFieldShape {
            switch self {
            case .rounded: return .rounded
            case .capsule: return .capsule
            case .rectangle: return .rectangle
            case .underline: return .underline
            }
        }
    }
    enum Motion: String, CaseIterable, Identifiable {
        case `default`, lively, subtle
        var id: String { rawValue }
        var preset: KitoFieldMotion {
            switch self {
            case .default: return .default
            case .lively: return .lively
            case .subtle: return .subtle
            }
        }
    }

    enum Language: String, CaseIterable, Identifiable {
        case system, en, sw, fr
        var id: String { rawValue }
        var title: String {
            switch self {
            case .system: return "System"
            case .en: return "English"
            case .sw: return "Kiswahili"
            case .fr: return "Français"
            }
        }
        var code: String? { self == .system ? nil : rawValue }
    }

    /// Switches every KitoFields string at runtime through `KitoLocalization.provider`, and the
    /// country names through the picker locale. Real apps normally rely on the device language;
    /// this shows how an in-app language setting can drive the package.
    @Published var language: Language = .system {
        didSet { applyLanguage() }
    }

    private var strings: [String: String] = [:]

    private func applyLanguage() {
        guard let code = language.code,
              let path = KitoLocalization.bundle.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: code),
              let table = NSDictionary(contentsOfFile: path) as? [String: String] else {
            strings = [:]
            KitoLocalization.provider = nil
            return
        }
        strings = table
        KitoLocalization.provider = { [table] key, _ in table[key] }
    }

    var locale: Locale { language.code.map(Locale.init(identifier:)) ?? .autoupdatingCurrent }

    @Published var style: Style = .outlined
    @Published var shape: Shape = .capsule
    @Published var motion: Motion = .default
    @Published var tint: Color = .black
    @Published var showsBorder = true
    @Published var showsShadow = false
    @Published var emojiFlags = false

    var fieldTheme: KitoFieldTheme {
        var theme = KitoFieldTheme()
        theme.shape = shape.fieldShape
        theme.flagStyle = emojiFlags ? .emoji : nil
        theme.showsBorder = showsBorder
        theme.focusedBorderColor = tint
        theme.shadow = showsShadow ? KitoShadow() : nil
        theme.motion = motion.preset
        if motion == .lively { theme.motion.focusedShadow = KitoShadow(color: tint.opacity(0.25), radius: 12, y: 4) }
        if shape == .capsule { theme.contentPadding = EdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 18) }
        return theme
    }
}

struct ContentView: View {
    @StateObject private var appearance = AppearanceModel()

    var body: some View {
        TabView {
            FieldSamplesScreen().tabItem { Label("Samples", systemImage: "square.grid.2x2") }
            InputsScreen().tabItem { Label("Demos", systemImage: "character.cursor.ibeam") }
            AppearanceScreen().tabItem { Label("Appearance", systemImage: "paintpalette") }
        }
        .environmentObject(appearance)
        .tint(appearance.tint)
        .environment(\.locale, appearance.locale)
        .id(appearance.language)   // re-render every string when the language changes
    }
}

/// Applies the chosen style and theme to any content.
struct Themed<Content: View>: View {
    @EnvironmentObject private var appearance: AppearanceModel
    @ViewBuilder var content: () -> Content

    var body: some View {
        styled.kitoFieldTheme(appearance.fieldTheme)
    }

    @ViewBuilder private var styled: some View {
        switch appearance.style {
        case .outlined: content().kitoFieldStyle(.outlined)
        case .filled: content().kitoFieldStyle(.filled)
        case .underlined: content().kitoFieldStyle(.underlined)
        case .floatingLabel: content().kitoFieldStyle(.floatingLabel)
        case .plain: content().kitoFieldStyle(.plain)
        }
    }
}

struct AppearanceScreen: View {
    @EnvironmentObject private var appearance: AppearanceModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Language") {
                    Picker("Language", selection: $appearance.language) {
                        ForEach(AppearanceModel.Language.allCases) { Text($0.title).tag($0) }
                    }.pickerStyle(.segmented)
                    Text("Validation messages, picker titles, strength labels and accessibility text switch instantly. Field labels typed in this demo stay in English.")
                        .font(.footnote).foregroundColor(.secondary)
                }
                Section("Field style") {
                    Picker("Style", selection: $appearance.style) {
                        ForEach(AppearanceModel.Style.allCases) { Text($0.title).tag($0) }
                    }.pickerStyle(.segmented)
                }
                Section("Shape") {
                    Picker("Shape", selection: $appearance.shape) {
                        ForEach(AppearanceModel.Shape.allCases) { Text($0.rawValue.capitalized).tag($0) }
                    }.pickerStyle(.segmented)
                    Toggle("Show border", isOn: $appearance.showsBorder)
                    Toggle("Emoji flags", isOn: $appearance.emojiFlags)
                    Toggle("Drop shadow", isOn: $appearance.showsShadow)
                }
                Section("Motion preset") {
                    Picker("Motion", selection: $appearance.motion) {
                        ForEach(AppearanceModel.Motion.allCases) { Text($0.rawValue.capitalized).tag($0) }
                    }.pickerStyle(.segmented)
                }
                Section("Tint") {
                    ColorPicker("Accent color", selection: $appearance.tint, supportsOpacity: false)
                }
                Section("Preview") {
                    Themed {
                        KitoTextField("Full name", text: .constant("Wycliff Njenga"), prompt: "Your name")
                            .leadingIcon("person")
                            .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Appearance")
        }
    }
}
