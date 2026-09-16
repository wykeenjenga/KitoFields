//
//  FieldSamplesScreen.swift
//  KitoFieldsExample
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

struct FieldSamplesScreen: View {
    @State private var query = ""
    @State private var showsAbout = false

    private var filtered: [FieldSample] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return FieldSampleCatalog.all }
        return FieldSampleCatalog.all.filter { $0.title.localizedCaseInsensitiveContains(q) || $0.subtitle.localizedCaseInsensitiveContains(q) || $0.category.rawValue.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(FieldCategory.allCases) { category in
                    let items = filtered.filter { $0.category == category }
                    if !items.isEmpty {
                        Section {
                            ForEach(items) { sample in
                                NavigationLink(value: sample.id) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(sample.title).font(.body.weight(.semibold))
                                        Text(sample.subtitle).font(.footnote).foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        } header: {
                            Label(category.rawValue, systemImage: category.symbol).font(.subheadline.weight(.semibold)).foregroundStyle(.primary).textCase(nil)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $query, prompt: "Search \(FieldSampleCatalog.all.count) samples")
            .navigationTitle("Samples")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showsAbout = true } label: { Image(systemName: "info.circle") }.accessibilityLabel("About")
                }
            }
            .sheet(isPresented: $showsAbout) { AboutScreen() }
            .navigationDestination(for: UUID.self) { id in
                if let sample = FieldSampleCatalog.all.first(where: { $0.id == id }) { FieldSampleDetail(sample: sample) }
            }
        }
    }
}

struct FieldSampleDetail: View {
    let sample: FieldSample
    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(sample.subtitle).font(.subheadline).foregroundStyle(.secondary)
                Themed { sample.view().frame(maxWidth: .infinity) }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                HStack {
                    Text("Code").font(.headline)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = sample.code
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { copied = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { withAnimation { copied = false } }
                    } label: {
                        Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(Capsule().fill(copied ? Color.primary : Color.primary.opacity(0.08)))
                            .foregroundStyle(copied ? Color(.systemBackground) : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(sample.code).font(.system(.footnote, design: .monospaced)).textSelection(.enabled).padding(16)
                }
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.05)))
                Text("Requires `import KitoFields`. Style, shape, motion and language follow the Appearance tab.").font(.caption).foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle(sample.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
