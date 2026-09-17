//
//  KitoPasswordUI.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 17/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// How the requirement checklist is drawn.
public enum KitoChecklistStyle: Sendable, Equatable {
    /// One requirement per line with an icon (default).
    case list
    /// Two columns.
    case grid
    /// Capsule chips that fill in as each rule passes.
    case chips
    /// A single line: "3 of 5 requirements met" plus a thin progress bar.
    case compact
    /// Nothing drawn (rules still validate).
    case hidden
}

/// How the strength meter is drawn.
public enum KitoStrengthMeterStyle: Sendable, Equatable {
    /// Discrete segments (default 4).
    case segments(Int)
    /// One continuous bar that fills and recolours.
    case bar
    /// A ring with the label inside.
    case ring
    /// Small dots.
    case dots(Int)
    /// Label only.
    case textOnly
    case hidden

    public static let segments = KitoStrengthMeterStyle.segments(4)
}

/// Where the meter and checklist go relative to each other.
public enum KitoPasswordFooterOrder: Sendable, Equatable {
    case meterThenChecklist
    case checklistThenMeter
}

/// Every knob for the password field's strength meter and requirement checklist.
///
/// ```swift
/// KitoPasswordField(text: $pw)
///     .strengthMeter()
///     .requirements(KitoRule.strongPassword())
///     .passwordUI { ui in
///         ui.checklistStyle = .chips
///         ui.meterStyle = .ring
///         ui.metSymbol = "checkmark.seal.fill"
///         ui.levelColors[.veryStrong] = .mint
///         ui.hidesChecklistWhenAllMet = true
///     }
/// ```
public struct KitoPasswordUIConfiguration {
    // Checklist
    public var checklistStyle: KitoChecklistStyle = .list
    public var metSymbol = "checkmark.circle.fill"
    public var unmetSymbol = "circle"
    public var metColor: Color? = nil            // nil = theme.successColor
    public var unmetColor: Color? = nil          // nil = theme.helperColor
    public var checklistFont: Font? = nil        // nil = theme.helperFont
    public var showsOnlyUnmet = false
    public var hidesChecklistWhenAllMet = false
    public var showsProgressHeader = false       // "3 of 5 requirements met" above the list
    public var strikesThroughMet = false

    // Meter
    public var meterStyle: KitoStrengthMeterStyle = .segments
    public var showsLabel = true
    public var meterHeight: CGFloat = 4
    public var levelColors: [KitoPasswordStrength: Color] = [:]   // overrides per level
    public var levelLabels: [KitoPasswordStrength: String] = [:]  // overrides per level
    public var showsScoreOutOf = false           // "3 / 4" next to the label
    public var hidesMeterWhenEmpty = true
    /// Custom scorer; nil uses `KitoPasswordStrengthEvaluator`.
    public var scorer: ((String) -> KitoPasswordStrength)? = nil

    // Layout
    public var order: KitoPasswordFooterOrder = .meterThenChecklist
    public var spacing: CGFloat = 8

    public init() {}

    func color(for level: KitoPasswordStrength) -> Color { levelColors[level] ?? level.color }
    func label(for level: KitoPasswordStrength) -> String { levelLabels[level] ?? level.label }
}

// MARK: - Meter

/// Strength meter honouring `KitoPasswordUIConfiguration`.
public struct KitoStrengthMeterView: View {
    public var strength: KitoPasswordStrength
    public var ui: KitoPasswordUIConfiguration
    @Environment(\.kitoFieldTheme) private var theme

    public init(strength: KitoPasswordStrength, ui: KitoPasswordUIConfiguration = KitoPasswordUIConfiguration()) {
        self.strength = strength
        self.ui = ui
    }

    private var fill: Color { ui.color(for: strength) }
    private var track: Color { theme.borderColor.opacity(0.6) }
    private var fraction: CGFloat { CGFloat(strength.rawValue) / CGFloat(KitoPasswordStrength.allCases.count - 1) }

    public var body: some View {
        Group {
            switch ui.meterStyle {
            case .segments(let count):
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        ForEach(0..<max(count, 1), id: \.self) { index in
                            Capsule().fill(Double(index) < fraction * Double(count) - 0.001 || (strength.rawValue > 0 && index < Int(round(fraction * Double(count)))) ? fill : track)
                                .frame(height: ui.meterHeight)
                        }
                    }
                    label
                }
            case .bar:
                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(track)
                            Capsule().fill(fill).frame(width: max(proxy.size.width * fraction, strength.rawValue == 0 ? 0 : ui.meterHeight))
                        }
                    }
                    .frame(height: ui.meterHeight)
                    label
                }
            case .ring:
                HStack(spacing: 10) {
                    ZStack {
                        Circle().stroke(track, lineWidth: 4)
                        Circle().trim(from: 0, to: fraction).stroke(fill, style: StrokeStyle(lineWidth: 4, lineCap: .round)).rotationEffect(.degrees(-90))
                        if ui.showsScoreOutOf {
                            Text("\(strength.rawValue)").font(.caption2.weight(.bold)).foregroundColor(fill)
                        }
                    }
                    .frame(width: 28, height: 28)
                    label
                }
            case .dots(let count):
                HStack(spacing: 8) {
                    HStack(spacing: 5) {
                        ForEach(0..<max(count, 1), id: \.self) { index in
                            Circle().fill(index < Int(round(fraction * Double(count))) ? fill : track).frame(width: 8, height: 8)
                        }
                    }
                    label
                }
            case .textOnly:
                label
            case .hidden:
                EmptyView()
            }
        }
        .animation(theme.motion.pop, value: strength)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(KitoLocalization.format("strength.accessibility", "Password strength: %@", ui.label(for: strength)))
    }

    @ViewBuilder private var label: some View {
        if ui.showsLabel {
            HStack(spacing: 6) {
                Text(ui.label(for: strength))
                if ui.showsScoreOutOf, ui.meterStyle != .ring {
                    Text("\(strength.rawValue) / \(KitoPasswordStrength.allCases.count - 1)").monospacedDigit()
                }
            }
            .font(theme.helperFont)
            .foregroundColor(strength.rawValue == 0 ? theme.helperColor : fill)
        }
    }
}

// MARK: - Checklist

/// Requirement checklist honouring `KitoPasswordUIConfiguration`.
public struct KitoRequirementChecklistView: View {
    public var rules: [KitoRule]
    public var value: String
    public var ui: KitoPasswordUIConfiguration
    @Environment(\.kitoFieldTheme) private var theme

    public init(rules: [KitoRule], value: String, ui: KitoPasswordUIConfiguration = KitoPasswordUIConfiguration()) {
        self.rules = rules
        self.value = value
        self.ui = ui
    }

    private func met(_ rule: KitoRule) -> Bool { !value.isEmpty && rule.validate(value) }
    private var metCount: Int { rules.filter(met).count }
    private var allMet: Bool { !rules.isEmpty && metCount == rules.count }
    private var visibleRules: [KitoRule] { ui.showsOnlyUnmet ? rules.filter { !met($0) } : rules }
    private var metColor: Color { ui.metColor ?? theme.successColor }
    private var unmetColor: Color { ui.unmetColor ?? theme.helperColor }
    private var font: Font { ui.checklistFont ?? theme.helperFont }

    public var body: some View {
        if ui.checklistStyle == .hidden || (ui.hidesChecklistWhenAllMet && allMet) {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 6) {
                if ui.showsProgressHeader || ui.checklistStyle == .compact { progress }
                switch ui.checklistStyle {
                case .list:
                    VStack(alignment: .leading, spacing: 3) { ForEach(visibleRules) { row($0) } }
                case .grid:
                    LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], alignment: .leading, spacing: 4) {
                        ForEach(visibleRules) { row($0) }
                    }
                case .chips:
                    FlowLayoutCompat(spacing: 6) {
                        ForEach(visibleRules) { rule in
                            let ok = met(rule)
                            HStack(spacing: 4) {
                                Image(systemName: ok ? ui.metSymbol : ui.unmetSymbol).font(.caption2)
                                Text(rule.message).font(font)
                            }
                            .padding(.horizontal, 9).padding(.vertical, 5)
                            .foregroundColor(ok ? metColor : unmetColor)
                            .background(Capsule().fill(ok ? metColor.opacity(0.14) : theme.borderColor.opacity(0.25)))
                            .overlay(Capsule().stroke(ok ? metColor.opacity(0.6) : theme.borderColor.opacity(0.6), lineWidth: 1))
                        }
                    }
                case .compact, .hidden:
                    EmptyView()
                }
            }
            .animation(theme.motion.pop, value: metCount)
            .animation(theme.motion.pop, value: value.isEmpty)
        }
    }

    private func row(_ rule: KitoRule) -> some View {
        let ok = met(rule)
        return Label {
            Text(rule.message).strikethrough(ui.strikesThroughMet && ok)
        } icon: {
            Image(systemName: ok ? ui.metSymbol : ui.unmetSymbol)
                .id(ok).transition(.scale.combined(with: .opacity))
        }
        .font(font)
        .foregroundColor(ok ? metColor : unmetColor)
    }

    private var progress: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(KitoLocalization.format("password.requirementsMet", "%d of %d requirements met", metCount, rules.count))
                .font(font).foregroundColor(allMet ? metColor : theme.helperColor).monospacedDigit()
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(theme.borderColor.opacity(0.6))
                    Capsule().fill(allMet ? metColor : (theme.tintColor ?? theme.focusedBorderColor))
                        .frame(width: rules.isEmpty ? 0 : proxy.size.width * CGFloat(metCount) / CGFloat(rules.count))
                }
            }
            .frame(height: 4)
        }
    }
}

/// Wrapping row of chips; falls back to a wrapping HStack implementation for iOS 15.
struct FlowLayoutCompat<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *) {
            FlowLayout(spacing: spacing) { content() }
        } else {
            VStack(alignment: .leading, spacing: spacing) { content() }
        }
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width == .infinity ? x : width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX { x = bounds.minX; y += rowHeight + spacing; rowHeight = 0 }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Extra password rules

public extension KitoRule {
    /// Rejects passwords found in the evaluator's common-password list.
    static func notCommonPassword(message: String = KitoLocalization.string("password.common", "Too common, choose something less guessable")) -> KitoRule {
        let common = KitoPasswordStrengthEvaluator().commonPasswords
        return KitoRule(id: "inputkit.notCommon", message: message) { !common.contains($0.lowercased()) }
    }

    /// Rejects the same character repeated `max` or more times in a row ("aaa").
    static func noRepeatedCharacters(max: Int = 3, message: String? = nil) -> KitoRule {
        KitoRule(id: "inputkit.noRepeats.\(max)", message: message ?? KitoLocalization.format("password.repeats", "No character repeated %d times in a row", max)) { value in
            var run = 1
            for (a, b) in zip(value, value.dropFirst()) { run = a == b ? run + 1 : 1; if run >= max { return false } }
            return true
        }
    }

    /// Rejects runs like "abcd" or "4321" of the given length.
    static func noSequences(length: Int = 4, message: String? = nil) -> KitoRule {
        KitoRule(id: "inputkit.noSequences.\(length)", message: message ?? KitoLocalization.format("password.sequences", "No sequences like abcd or 1234")) { value in
            let scalars = value.lowercased().unicodeScalars.map { Int($0.value) }
            guard scalars.count >= length else { return true }
            for start in 0...(scalars.count - length) {
                let slice = Array(scalars[start..<start + length])
                let diffs = zip(slice, slice.dropFirst()).map { $1 - $0 }
                if diffs.allSatisfy({ $0 == 1 }) || diffs.allSatisfy({ $0 == -1 }) { return false }
            }
            return true
        }
    }

    /// Rejects passwords containing the value of another field (email local part, username, name).
    static func notContaining(_ other: @escaping () -> String, message: String = KitoLocalization.string("password.containsPersonal", "Must not contain your name or email")) -> KitoRule {
        KitoRule(id: "inputkit.notContaining", message: message) { value in
            let needle = other().lowercased()
            let local = needle.split(separator: "@").first.map(String.init) ?? needle
            guard local.count >= 3 else { return true }
            return !value.lowercased().contains(local)
        }
    }

    /// A stricter bundle: strong password plus not common, no repeats, no sequences.
    static func strictPassword(minLength: Int = 10) -> [KitoRule] {
        strongPassword(minLength: minLength) + [.notCommonPassword(), .noRepeatedCharacters(), .noSequences()]
    }
}
