//
//  FieldSample.swift
//  KitoFieldsExample
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI
import KitoFields

enum FieldCategory: String, CaseIterable, Identifiable {
    case text = "Text"
    case identity = "Name, email & username"
    case password = "Password & security"
    case phone = "Phone & country"
    case numbers = "Numbers & money"
    case dates = "Dates & cards"
    case choice = "Select, search & code"
    case errors = "Error presentation"
    case validation = "Validation & limits"
    case icons = "Icons & accessories"
    case styles = "Styles & shapes"
    case forms = "Complete forms"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .text: return "character.cursor.ibeam"
        case .identity: return "person.text.rectangle"
        case .password: return "lock"
        case .phone: return "phone"
        case .numbers: return "number"
        case .dates: return "creditcard"
        case .choice: return "list.bullet"
        case .errors: return "exclamationmark.bubble"
        case .validation: return "checkmark.shield"
        case .icons: return "sparkles"
        case .styles: return "paintbrush"
        case .forms: return "doc.text"
        }
    }
}

struct FieldSample: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let category: FieldCategory
    let code: String
    let view: () -> AnyView

    init<V: View>(_ title: String, _ subtitle: String, category: FieldCategory, code: String, @ViewBuilder view: @escaping () -> V) {
        self.title = title; self.subtitle = subtitle; self.category = category; self.code = code
        self.view = { AnyView(view()) }
    }
}

/// Holds a text binding for stateless sample definitions.
struct Stateful<Content: View>: View {
    @State private var text: String
    let content: (Binding<String>) -> Content
    init(_ initial: String = "", @ViewBuilder content: @escaping (Binding<String>) -> Content) {
        _text = State(initialValue: initial); self.content = content
    }
    var body: some View { content($text) }
}
