//
//  AboutScreen.swift
//  KitoFieldsExample
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

struct AboutScreen: View {
    @Environment(\.dismiss) private var dismiss
    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image("AppIconPreview")
                            .resizable()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("KitoFields").font(.title3.weight(.semibold))
                            Text("Sample app · \(version)").font(.footnote).foregroundStyle(.secondary)
                            Text("Text, email, password, phone, country and one-time-code fields").font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
                Section("Package") {
                    Link(destination: URL(string: "https://github.com/wykeenjenga/KitoFields")!) { Label("Source on GitHub", systemImage: "chevron.left.forwardslash.chevron.right") }
                    Link(destination: URL(string: "https://swiftpackageindex.com/wykeenjenga/KitoFields")!) { Label("Swift Package Index", systemImage: "shippingbox") }
                    Link(destination: URL(string: "https://cocoapods.org/pods/KitoFields")!) { Label("CocoaPods", systemImage: "cube") }
                    Link(destination: URL(string: "https://github.com/wykeenjenga/KitoButtons")!) { Label("KitoButtons · matching buttons", systemImage: "hand.tap") }
                }
                Section("Community") {
                    Link(destination: URL(string: "https://github.com/wykeenjenga/KitoFields/issues/new/choose")!) { Label("Report a bug or request a feature", systemImage: "exclamationmark.bubble") }
                    Link(destination: URL(string: "https://github.com/wykeenjenga/KitoFields/blob/main/CONTRIBUTING.md")!) { Label("Contributing guide", systemImage: "person.2") }
                    Link(destination: URL(string: "https://www.buymeacoffee.com/wycliffnjea")!) { Label("Buy me a coffee", systemImage: "cup.and.saucer") }
                }
                Section {
                    Text("Made by Wycliff Njenga in Nairobi. MIT licensed.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
