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

    @Published var style: Style = .outlined
    @Published var shape: Shape = .rounded
    @Published var motion: Motion = .default
    @Published var tint: Color = .indigo
    @Published var showsBorder = true
    @Published var showsShadow = false

    var fieldTheme: KitoFieldTheme {
        var theme = KitoFieldTheme()
        theme.shape = shape.fieldShape
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
            InputsScreen().tabItem { Label("Fields", systemImage: "character.cursor.ibeam") }
            AppearanceScreen().tabItem { Label("Appearance", systemImage: "paintpalette") }
        }
        .environmentObject(appearance)
        .tint(appearance.tint)
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
