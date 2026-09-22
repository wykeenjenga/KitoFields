//
//  KitoCodeField.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// A separator's default look, used at group boundaries set by `.groups(_:separator:)`. For
/// anything else, pass a view directly to `.groups(_:separator:)` or `.separator(after:view:)`.
public enum KitoCodeSeparatorStyle: Sendable {
    case dash, dot, none
}

/// Preset box chrome. `.outlined` (default) and `.filled` share the field's usual bordered/filled
/// box, drawn through `KitoFieldChrome` exactly as before this existed; `.underline` switches to
/// `KitoFieldShape.underline`, a single line under each digit.
public enum KitoCodeBoxStyle: Sendable, Equatable {
    case outlined, filled, underline
}

/// How the boxes lay out horizontally.
public enum KitoCodeDistribution: Sendable, Equatable {
    /// The row hugs its content at `boxSize`/`spacing`, exactly as `KitoCodeField` always has.
    case fixedSpacing
    /// The row claims the full width offered to it; boxes shrink (down to `minimumBoxWidth`) to
    /// fit a narrow screen, and never grow past `boxSize`.
    case fill
}

/// Where the row sits when it doesn't need the full width offered to it (`.distribution(.fill)`
/// on a wide screen, or any distribution inside a wider parent).
public enum KitoCodeAlignment: Sendable, Equatable {
    case leading, center
}

/// Which characters `KitoCodeField` accepts; everything else is filtered out as it's typed or
/// pasted.
public enum KitoCodeCharacterSet: Sendable, Equatable {
    case digits
    case alphanumeric
    case custom(CharacterSet)
}

/// Feedback played once when `.showsSuccess(_:)` flips to true.
public enum KitoCodeSuccessAnimation: Sendable, Equatable {
    /// A brief scale pulse across the whole row.
    case pulse
    /// A checkmark fades in over the row, then fades out.
    case tick
    /// Border/fill recolour only (see `theme.successBorderColor`), no extra motion.
    case none
}

/// One-time-code entry rendered as individual boxes, backed by a single hidden text field so
/// paste and SMS autofill work.
///
/// ```swift
/// KitoCodeField(code: $code, length: 6)
///     .onComplete { code in verify(code) }
/// ```
public struct KitoCodeField: View {
    @Binding private var code: String
    private let length: Int
    private var isSecure = false
    private var boxSize = CGSize(width: 46, height: 54)
    private var spacing: CGFloat = 10
    private var showsCaret = true
    private var digitFont: Font?
    var filledFill: Color?
    var filledBorderColor: Color?
    var filledBorderWidth: CGFloat?
    var filledShadow: KitoShadow?
    var activeFill: Color?
    var activeBorderColor: Color?
    var activeBorderWidth: CGFloat?
    var activeShadow: KitoShadow?
    var errorFill: Color?
    var errorBorderColor: Color?
    var errorBorderWidth: CGFloat?
    var errorShadow: KitoShadow?
    var boxStylePreset: KitoCodeBoxStyle = .outlined
    var boxShapeOverride: KitoFieldShape?
    var digitColorFilled: Color?
    var digitColorActive: Color?
    var distributionValue: KitoCodeDistribution = .fixedSpacing
    var alignmentValue: KitoCodeAlignment = .center
    var minimumBoxWidthValue: CGFloat = 32
    var characterSetValue: KitoCodeCharacterSet = .digits
    var uppercasesValue = true
    var selectAllOnFocusValue = false
    var revealLastEnteredDuration: TimeInterval?
    var maskCharacterValue: Character = "●"
    var successAnimationValue: KitoCodeSuccessAnimation = .none
    var hapticsOnDigit = false
    var hapticsOnComplete = false
    var hapticsOnError = false
    var customStyle: AnyKitoCodeFieldStyle?
    private var groupSizes: [Int]?
    private var groupSeparatorStyle: KitoCodeSeparatorStyle = .dash
    private var groupSeparatorView: (() -> AnyView)?
    private var customSeparators: [Int: () -> AnyView] = [:]
    private var errorMessage: String?
    private var clearsOnErrorAfter: TimeInterval?
    private var onComplete: ((String) -> Void)?
    private var focusBinding: Binding<Bool>?
    private var successBinding: Binding<Bool>?
    private var resendConfig: (cooldown: TimeInterval, title: ((Int) -> String)?, action: () -> Void)?

    @FocusState private var isFocused: Bool
    @State private var shakeTrigger = 0
    @State private var previousCodeCount = 0
    @State private var revealedIndex: Int?
    @State private var successPulse = false
    @State private var showsTick = false
    @Environment(\.kitoFieldTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(code: Binding<String>, length: Int = 6) {
        _code = code
        self.length = max(1, length)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.helperSpacing) {
            ZStack {
                boxesRow
                hiddenField
                if successAnimationValue == .tick, showsTick {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: resolvedBoxSize.height * 0.6, weight: .semibold))
                        .foregroundColor(theme.successBorderColor ?? theme.successColor)
                        .transition(.scale.combined(with: .opacity))
                        .allowsHitTesting(false)
                }
            }
            .scaleEffect(successPulse ? 1.05 : 1)
            .contentShape(Rectangle())
            .modifier(FocusOnTap { isFocused = true })
            .kitoFieldShake(trigger: reduceMotion ? 0 : shakeTrigger, animation: theme.motion.shake)
            if let errorMessage {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if let icon = theme.errorIcon {
                        Image(systemName: icon).font(theme.errorIconFont ?? theme.errorFont ?? theme.helperFont)
                    }
                    Text(errorMessage).font(theme.errorFont ?? theme.helperFont)
                }
                .foregroundColor(theme.errorColor)
            }
            resendButtonView
        }
        .opacity(isEnabled ? 1 : theme.disabledOpacity)
        .animation(reduceMotion ? .easeOut(duration: 0.1) : theme.animation, value: code)
        .animation(reduceMotion ? .easeOut(duration: 0.1) : theme.animation, value: isFocused)
        .onChange(of: code) { sanitize($0) }
        .onChange(of: errorMessage) { newValue in
            guard newValue != nil else { return }
            shakeTrigger += 1
            if hapticsOnError { fireHaptic(.error) }
            guard let delay = clearsOnErrorAfter else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { code = "" }
        }
        .onChange(of: isFocused) { focused in
            if let focusBinding, focusBinding.wrappedValue != focused { focusBinding.wrappedValue = focused }
            if focused, selectAllOnFocusValue, !code.isEmpty { code = "" }
        }
        .onChange(of: focusBinding?.wrappedValue) { requested in
            if let requested, requested != isFocused { isFocused = requested }
        }
        .onChange(of: successBinding?.wrappedValue) { newValue in
            guard newValue == true else { return }
            switch successAnimationValue {
            case .pulse:
                withAnimation(theme.motion.shake) { successPulse = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { withAnimation(theme.motion.shake) { successPulse = false } }
            case .tick:
                withAnimation { showsTick = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { withAnimation { showsTick = false } }
            case .none:
                break
            }
        }
        .onChange(of: activeIndex) { newIndex in
            guard let newIndex else { return }
            #if os(iOS)
            UIAccessibility.post(notification: .announcement, argument: KitoLocalization.format("code.digitPosition", "Digit %d of %d", newIndex + 1, length))
            #endif
        }
        .onAppear {
            previousCodeCount = Array(code).count
            if focusBinding?.wrappedValue == true { isFocused = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(KitoLocalization.string("code.accessibilityLabel", "Verification code"))
        .accessibilityValue(code.map(String.init).joined(separator: " "))
    }

    private var hiddenField: some View {
        TextField("", text: $code)
            .focused($isFocused)
            .kitoKeyboard(usesNumericKeyboard ? .numberPad : .asciiCapable)
            .kitoContentType(.oneTimeCode)
            .kitoAutocapitalization(.characters)
            .disableAutocorrection(true)
            .foregroundColor(.clear)
            .accentColor(.clear)
            .frame(maxWidth: .infinity)
            .frame(height: resolvedBoxSize.height)
            .opacity(0.02)
            .accessibilityHidden(true)
    }

    private var usesNumericKeyboard: Bool {
        if case .digits = characterSetValue { return true }
        return false
    }

    /// `boxSize` grown up to 1.3x for large accessibility Dynamic Type sizes, so a scalable
    /// `.digitFont` isn't clipped. Only kicks in once `.digitFont(_:)` has been set — the default
    /// theme font renders exactly at `boxSize` as it always has.
    private var resolvedBoxSize: CGSize {
        guard digitFont != nil else { return boxSize }
        let factor = Self.dynamicTypeScaleFactor(for: dynamicTypeSize)
        return CGSize(width: boxSize.width * factor, height: boxSize.height * factor)
    }

    static func dynamicTypeScaleFactor(for size: DynamicTypeSize) -> Double {
        let allCases = DynamicTypeSize.allCases
        guard let index = allCases.firstIndex(of: size), let baseline = allCases.firstIndex(of: .large) else { return 1 }
        let steps = index - baseline
        guard steps > 0 else { return 1 }
        return min(1.3, 1.0 + Double(steps) * 0.05)
    }

    // MARK: Boxes row and distribution

    @ViewBuilder private var boxesRow: some View {
        switch distributionValue {
        case .fixedSpacing:
            HStack(spacing: 0) {
                ForEach(Array(rowItems.enumerated()), id: \.element.id) { offset, item in
                    rowItemView(item, boxWidth: resolvedBoxSize.width)
                        .padding(.trailing, offset == rowItems.count - 1 ? 0 : spacing)
                }
            }
        case .fill:
            GeometryReader { proxy in
                let width = Self.resolvedBoxWidth(
                    availableWidth: proxy.size.width,
                    boxCount: length,
                    separatorCount: rowItems.count - length,
                    spacing: spacing,
                    nominalBoxWidth: resolvedBoxSize.width,
                    minimumBoxWidth: minimumBoxWidthValue
                )
                HStack(spacing: 0) {
                    ForEach(Array(rowItems.enumerated()), id: \.element.id) { offset, item in
                        rowItemView(item, boxWidth: width)
                            .padding(.trailing, offset == rowItems.count - 1 ? 0 : spacing)
                    }
                }
                .frame(maxWidth: .infinity, alignment: alignmentValue == .leading ? .leading : .center)
            }
            .frame(height: resolvedBoxSize.height)
        }
    }

    /// Shrinks (never grows) `nominalBoxWidth` to fit `boxCount` boxes plus `separatorCount`
    /// separators (estimated at `separatorWidth` each) into `availableWidth`, floored at
    /// `minimumBoxWidth`.
    static func resolvedBoxWidth(availableWidth: CGFloat, boxCount: Int, separatorCount: Int, spacing: CGFloat, nominalBoxWidth: CGFloat, minimumBoxWidth: CGFloat, separatorWidth: CGFloat = 12) -> CGFloat {
        guard boxCount > 0, availableWidth > 0 else { return nominalBoxWidth }
        let totalSlots = boxCount + separatorCount
        let totalSpacing = spacing * CGFloat(max(0, totalSlots - 1))
        let totalSeparatorWidth = separatorWidth * CGFloat(separatorCount)
        let remaining = availableWidth - totalSpacing - totalSeparatorWidth
        guard remaining > 0 else { return minimumBoxWidth }
        let perBox = remaining / CGFloat(boxCount)
        return min(nominalBoxWidth, max(minimumBoxWidth, perBox))
    }

    private func box(at index: Int, width: CGFloat) -> AnyView {
        let characters = Array(code)
        let hasValue = index < characters.count
        let isActive = Self.isActiveBox(index: index, characterCount: characters.count, length: length, isFocused: isFocused)
        let hasError = errorMessage != nil
        let isSuccess = successBinding?.wrappedValue == true
        let baseFill: Color = {
            switch boxStylePreset {
            case .filled: return theme.filledBackgroundColor
            case .underline: return .clear
            case .outlined: return theme.backgroundColor == .clear ? theme.filledBackgroundColor : theme.backgroundColor
            }
        }()
        let presetBorderWidth: CGFloat? = boxStylePreset == .filled ? 0 : nil
        let appearance = Self.boxAppearance(
            hasError: hasError,
            hasValue: hasValue,
            isActive: isActive,
            baseFill: baseFill,
            filledFill: filledFill,
            filledBorderColor: filledBorderColor,
            filledBorderWidth: filledBorderWidth,
            filledShadow: filledShadow,
            theme: theme,
            activeFill: activeFill,
            activeBorderColor: activeBorderColor,
            activeBorderWidth: activeBorderWidth,
            activeShadow: activeShadow,
            errorFill: errorFill,
            errorBorderColor: errorBorderColor,
            errorBorderWidth: errorBorderWidth,
            errorShadow: errorShadow,
            isSuccess: isSuccess,
            successBorderColor: theme.successBorderColor,
            presetBorderWidth: presetBorderWidth
        )

        let displayCharacter: Character? = hasValue ? (isSecure && revealedIndex != index ? maskCharacterValue : characters[index]) : nil
        let resolvedHeight = resolvedBoxSize.height

        if let customStyle {
            let configuration = KitoCodeBoxStyleConfiguration(
                index: index, character: displayCharacter, isActive: isActive, hasError: hasError,
                isFocused: isFocused, isEnabled: isEnabled, boxSize: CGSize(width: width, height: resolvedHeight), theme: theme
            )
            return AnyView(customStyle.makeBox(configuration).frame(width: width, height: resolvedHeight))
        }

        let digitColorValue = isActive ? (digitColorActive ?? digitColorFilled ?? theme.textColor) : (digitColorFilled ?? theme.textColor)

        return AnyView(
            ZStack {
                if let displayCharacter {
                    Text(String(displayCharacter))
                        .font(digitFont ?? theme.font.weight(.semibold))
                        .foregroundColor(digitColorValue)
                        .transition(.scale.combined(with: .opacity))
                } else if isActive && showsCaret {
                    Rectangle()
                        .fill(theme.focusedBorderColor)
                        .frame(width: 2, height: resolvedHeight * 0.45)
                        .modifier(Blink())
                }
            }
            .frame(width: width, height: resolvedHeight)
            .modifier(KitoFieldChrome(
                shape: boxShapeOverride ?? (boxStylePreset == .underline ? .underline : theme.shape),
                fill: appearance.fill,
                borderColor: appearance.borderColor,
                borderWidth: theme.showsBorder ? appearance.borderWidth : 0,
                shadow: appearance.shadow
            ))
        )
    }

    private enum RowItem {
        case box(Int)
        case separator(Int, AnyView)
        var id: String {
            switch self {
            case .box(let index): return "box-\(index)"
            case .separator(let index, _): return "separator-\(index)"
            }
        }
    }

    static func groupBoundaries(sizes: [Int]?, length: Int) -> Set<Int> {
        guard let sizes, sizes.count > 1 else { return [] }
        var boundaries = Set<Int>()
        var index = -1
        for size in sizes.dropLast() {
            index += size
            if index >= 0, index < length - 1 { boundaries.insert(index) }
        }
        return boundaries
    }

    private var rowItems: [RowItem] {
        let boundaries = Self.groupBoundaries(sizes: groupSizes, length: length)
        var items: [RowItem] = []
        for index in 0..<length {
            items.append(.box(index))
            if let custom = customSeparators[index] {
                items.append(.separator(index, custom()))
            } else if boundaries.contains(index) {
                let view = groupSeparatorView?() ?? AnyView(defaultSeparator(groupSeparatorStyle))
                items.append(.separator(index, view))
            }
        }
        return items
    }

    @ViewBuilder
    private func rowItemView(_ item: RowItem, boxWidth: CGFloat) -> some View {
        switch item {
        case .box(let index): box(at: index, width: boxWidth)
        case .separator(_, let view): view
        }
    }

    @ViewBuilder
    private func defaultSeparator(_ style: KitoCodeSeparatorStyle) -> some View {
        switch style {
        case .dash:
            Rectangle().fill(theme.borderColor).frame(width: 8, height: 2)
        case .dot:
            Circle().fill(theme.borderColor).frame(width: 5, height: 5)
        case .none:
            EmptyView()
        }
    }

    static func isActiveBox(index: Int, characterCount: Int, length: Int, isFocused: Bool) -> Bool {
        guard isFocused else { return false }
        return index == characterCount || (characterCount == length && index == length - 1)
    }

    private var activeIndex: Int? {
        guard isFocused else { return nil }
        let count = Array(code).count
        if count == length { return length - 1 }
        return count < length ? count : nil
    }

    static func boxAppearance(
        hasError: Bool,
        hasValue: Bool,
        isActive: Bool,
        baseFill: Color,
        filledFill: Color?,
        filledBorderColor: Color?,
        filledBorderWidth: CGFloat?,
        filledShadow: KitoShadow?,
        theme: KitoFieldTheme,
        activeFill: Color? = nil,
        activeBorderColor: Color? = nil,
        activeBorderWidth: CGFloat? = nil,
        activeShadow: KitoShadow? = nil,
        errorFill: Color? = nil,
        errorBorderColor: Color? = nil,
        errorBorderWidth: CGFloat? = nil,
        errorShadow: KitoShadow? = nil,
        isSuccess: Bool = false,
        successBorderColor: Color? = nil,
        presetBorderWidth: CGFloat? = nil
    ) -> (fill: Color, borderColor: Color, borderWidth: CGFloat, shadow: KitoShadow?) {
        let hasFilledOverride = filledFill != nil || filledBorderColor != nil || filledBorderWidth != nil || filledShadow != nil
        let hasActiveOverride = activeFill != nil || activeBorderColor != nil || activeBorderWidth != nil || activeShadow != nil

        if hasError {
            return (errorFill ?? baseFill, errorBorderColor ?? theme.errorColor, errorBorderWidth ?? theme.focusedBorderWidth, errorShadow ?? theme.shadow)
        }
        if isSuccess {
            return (baseFill, successBorderColor ?? theme.successColor, theme.focusedBorderWidth, theme.shadow)
        }
        if isActive {
            if hasActiveOverride {
                return (activeFill ?? baseFill, activeBorderColor ?? theme.focusedBorderColor, activeBorderWidth ?? theme.focusedBorderWidth, activeShadow ?? theme.shadow)
            }
            if hasValue, hasFilledOverride {
                return (filledFill ?? baseFill, filledBorderColor ?? theme.focusedBorderColor, filledBorderWidth ?? theme.focusedBorderWidth, filledShadow ?? theme.shadow)
            }
            return (baseFill, theme.focusedBorderColor, theme.focusedBorderWidth, theme.shadow)
        }
        if hasValue, hasFilledOverride {
            return (filledFill ?? baseFill, filledBorderColor ?? theme.borderColor, filledBorderWidth ?? (presetBorderWidth ?? theme.borderWidth), filledShadow ?? theme.shadow)
        }
        return (baseFill, theme.borderColor, presetBorderWidth ?? theme.borderWidth, theme.shadow)
    }

    // MARK: Input handling

    private func sanitize(_ value: String) {
        let cleaned = Self.sanitize(value, characterSet: characterSetValue, uppercases: uppercasesValue, length: length)
        if cleaned != value {
            code = cleaned
            return
        }
        if cleaned.count > previousCodeCount {
            if isSecure, let duration = revealLastEnteredDuration {
                let revealed = cleaned.count - 1
                revealedIndex = revealed
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    if revealedIndex == revealed { revealedIndex = nil }
                }
            }
            if hapticsOnDigit { fireHaptic(.light) }
        }
        previousCodeCount = cleaned.count
        if cleaned.count == length {
            onComplete?(cleaned)
            if hapticsOnComplete { fireHaptic(.success) }
        }
    }

    /// Filters to the configured character set, optionally uppercases, then truncates. Pasting
    /// (spaces/dashes stripped as a side effect of filtering) and a full field being typed over
    /// (kept as the *last* `length` characters, so the newest input replaces the oldest, not the
    /// other way around) both flow through here.
    static func sanitize(_ value: String, characterSet: KitoCodeCharacterSet, uppercases: Bool, length: Int) -> String {
        var cleaned: String
        switch characterSet {
        case .digits:
            cleaned = value.filter { $0.isASCII && $0.isNumber }
        case .alphanumeric:
            cleaned = value.filter { $0.isLetter || $0.isNumber }
        case .custom(let set):
            cleaned = String(String.UnicodeScalarView(value.unicodeScalars.filter { set.contains($0) }))
        }
        if uppercases { cleaned = cleaned.uppercased() }
        if cleaned.count > length { cleaned = String(cleaned.suffix(length)) }
        return cleaned
    }

    private enum HapticKind { case light, success, error }

    private func fireHaptic(_ kind: HapticKind) {
        #if os(iOS)
        switch kind {
        case .light: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .success: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .error: UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        #endif
    }

    // MARK: Resend

    @ViewBuilder private var resendButtonView: some View {
        if let resendConfig {
            if let title = resendConfig.title {
                KitoResendCodeButton(cooldown: resendConfig.cooldown, action: resendConfig.action).title(title)
            } else {
                KitoResendCodeButton(cooldown: resendConfig.cooldown, action: resendConfig.action)
            }
        }
    }

    // MARK: Configuration

    private func mutating(_ change: (inout KitoCodeField) -> Void) -> KitoCodeField {
        var copy = self
        change(&copy)
        return copy
    }

    /// Masks digits with `.maskCharacter(_:)` (a dot, by default).
    public func secure(_ enabled: Bool = true) -> KitoCodeField { mutating { $0.isSecure = enabled } }
    public func boxSize(_ size: CGSize) -> KitoCodeField { mutating { $0.boxSize = size } }
    public func spacing(_ value: CGFloat) -> KitoCodeField { mutating { $0.spacing = value } }
    /// Hide the blinking caret in the active box; the box then shows focus through its border only.
    public func showsCaret(_ enabled: Bool) -> KitoCodeField { mutating { $0.showsCaret = enabled } }
    /// Font for the entered digits; defaults to the theme font at semibold. A scalable text-style
    /// font also grows the boxes with Dynamic Type, up to 1.3x — see `resolvedBoxSize`.
    public func digitFont(_ font: Font) -> KitoCodeField { mutating { $0.digitFont = font } }
    /// Styling for a box that already holds a character. Anything left nil falls back to the theme.
    public func filledBox(fill: Color? = nil, borderColor: Color? = nil, borderWidth: CGFloat? = nil, shadow: KitoShadow? = nil) -> KitoCodeField {
        mutating {
            $0.filledFill = fill
            $0.filledBorderColor = borderColor
            $0.filledBorderWidth = borderWidth
            $0.filledShadow = shadow
        }
    }
    /// Styling for the box currently accepting input. Wins over `.filledBox(...)` when both would
    /// apply (a filled, still-focused box). Anything left nil falls back to the theme.
    public func activeBox(fill: Color? = nil, borderColor: Color? = nil, borderWidth: CGFloat? = nil, shadow: KitoShadow? = nil) -> KitoCodeField {
        mutating {
            $0.activeFill = fill
            $0.activeBorderColor = borderColor
            $0.activeBorderWidth = borderWidth
            $0.activeShadow = shadow
        }
    }
    /// Styling while `.errorMessage(_:)` is set. Beats every other state. Anything left nil falls
    /// back to the theme's error colour/width.
    public func errorBox(fill: Color? = nil, borderColor: Color? = nil, borderWidth: CGFloat? = nil, shadow: KitoShadow? = nil) -> KitoCodeField {
        mutating {
            $0.errorFill = fill
            $0.errorBorderColor = borderColor
            $0.errorBorderWidth = borderWidth
            $0.errorShadow = shadow
        }
    }
    /// Quick preset for the box chrome. `.filled` also drops the idle border to 0 unless you set
    /// one explicitly via `.filledBox(borderWidth:)`; `.underline` switches to `KitoFieldShape.underline`
    /// unless overridden with `.boxShape(_:)`.
    public func boxStyle(_ style: KitoCodeBoxStyle) -> KitoCodeField { mutating { $0.boxStylePreset = style } }
    /// Overrides the box shape (theme's shape by default, or `.underline` under `.boxStyle(.underline)`).
    public func boxShape(_ shape: KitoFieldShape?) -> KitoCodeField { mutating { $0.boxShapeOverride = shape } }
    /// Digit text colour for a filled box and/or the active box; nil keeps `theme.textColor`. The
    /// active colour wins when a box is both filled and active.
    public func digitColor(filled: Color? = nil, active: Color? = nil) -> KitoCodeField {
        mutating { $0.digitColorFilled = filled; $0.digitColorActive = active }
    }
    /// `.fixedSpacing` (default, unchanged) hugs its content; `.fill` claims the full width offered
    /// to it and shrinks boxes (down to `.minimumBoxWidth(_:)`) to fit a narrow screen.
    public func distribution(_ distribution: KitoCodeDistribution) -> KitoCodeField { mutating { $0.distributionValue = distribution } }
    /// Where the row sits when it has room to spare. Matters most with `.distribution(.fill)`.
    public func alignment(_ alignment: KitoCodeAlignment) -> KitoCodeField { mutating { $0.alignmentValue = alignment } }
    /// Floor for `.distribution(.fill)`'s proportional shrinking. Defaults to 32pt.
    public func minimumBoxWidth(_ width: CGFloat) -> KitoCodeField { mutating { $0.minimumBoxWidthValue = width } }
    /// Splits the boxes into groups, e.g. `.groups([3, 3])` on a 6-digit code renders "123 - 456".
    /// The last group has no trailing separator. `style` defaults to a themed dash.
    public func groups(_ sizes: [Int], separator style: KitoCodeSeparatorStyle = .dash) -> KitoCodeField {
        mutating { $0.groupSizes = sizes; $0.groupSeparatorStyle = style; $0.groupSeparatorView = nil }
    }
    /// Same as `groups(_:separator:)`, but with your own view at every group boundary instead of
    /// one of the built-in styles.
    public func groups<V: View>(_ sizes: [Int], @ViewBuilder separator view: @escaping () -> V) -> KitoCodeField {
        mutating { $0.groupSizes = sizes; $0.groupSeparatorView = { AnyView(view()) } }
    }
    /// A one-off separator after the box at `index` (0-based), e.g. `.separator(after: 2) { Text("-") }`
    /// on a 6-digit code places it between the 3rd and 4th boxes. Takes priority over a separator
    /// from `.groups(_:separator:)` at the same index.
    public func separator<V: View>(after index: Int, @ViewBuilder view: @escaping () -> V) -> KitoCodeField {
        mutating { $0.customSeparators[index] = { AnyView(view()) } }
    }
    /// Which characters are accepted; anything else is filtered out as it's typed or pasted.
    public func characterSet(_ set: KitoCodeCharacterSet) -> KitoCodeField { mutating { $0.characterSetValue = set } }
    /// Uppercases accepted input (on by default — a no-op for `.digits`, matters for `.alphanumeric`
    /// and `.custom`).
    public func uppercases(_ enabled: Bool = true) -> KitoCodeField { mutating { $0.uppercasesValue = enabled } }
    /// Accepts letters as well as digits (uppercased). Shorthand for `.characterSet(.alphanumeric)`.
    public func alphanumeric(_ enabled: Bool = true) -> KitoCodeField { mutating { $0.characterSetValue = enabled ? .alphanumeric : .digits } }
    /// Clears the code when the field gains focus while it already holds a value, so typing
    /// immediately starts a fresh code instead of appending. SwiftUI doesn't expose true text
    /// selection on this field's hidden input, so this is the practical equivalent.
    public func selectAllOnFocus(_ enabled: Bool = true) -> KitoCodeField { mutating { $0.selectAllOnFocusValue = enabled } }
    /// With `.secure(true)`, briefly shows a just-typed digit before masking it (like the system
    /// passcode field) instead of masking it immediately.
    public func revealLastEntered(for duration: TimeInterval) -> KitoCodeField { mutating { $0.revealLastEnteredDuration = duration } }
    /// Character used to mask digits under `.secure(true)`. Defaults to "●".
    public func maskCharacter(_ character: Character) -> KitoCodeField { mutating { $0.maskCharacterValue = character } }
    /// Feedback played once when the binding passed to `.showsSuccess(_:)` flips to true.
    public func successAnimation(_ style: KitoCodeSuccessAnimation) -> KitoCodeField { mutating { $0.successAnimationValue = style } }
    /// Recolours the boxes with `theme.successBorderColor` (falling back to `theme.successColor`)
    /// while `binding.wrappedValue` is true, and triggers `.successAnimation(_:)`.
    public func showsSuccess(_ binding: Binding<Bool>) -> KitoCodeField { mutating { $0.successBinding = binding } }
    /// Haptic feedback (iOS only) for each accepted digit, on completion, and/or when an error is set.
    public func haptics(onDigit: Bool = false, onComplete: Bool = false, onError: Bool = false) -> KitoCodeField {
        mutating { $0.hapticsOnDigit = onDigit; $0.hapticsOnComplete = onComplete; $0.hapticsOnError = onError }
    }
    /// Places a `KitoResendCodeButton` below the boxes (and below the error message, if shown),
    /// counting down from `cooldown` seconds after each tap. `title` overrides the button's own
    /// localized copy, given seconds remaining (0 once re-enabled); nil keeps it.
    public func resendButton(after cooldown: TimeInterval, title: ((Int) -> String)? = nil, action: @escaping () -> Void) -> KitoCodeField {
        mutating { $0.resendConfig = (cooldown, title, action) }
    }
    public func errorMessage(_ message: String?) -> KitoCodeField { mutating { $0.errorMessage = message } }
    /// Clears the entered code automatically `delay` seconds after `errorMessage` is set, once the
    /// shake has played. Without this, clearing the wrong code back out is on you (as in earlier
    /// versions of this field).
    public func clearsOnError(after delay: TimeInterval = 0.6) -> KitoCodeField { mutating { $0.clearsOnErrorAfter = delay } }
    public func onComplete(_ handler: @escaping (String) -> Void) -> KitoCodeField { mutating { $0.onComplete = handler } }
    public func focused(_ binding: Binding<Bool>) -> KitoCodeField { mutating { $0.focusBinding = binding } }
    /// Coordinates focus with `@FocusState` when several fields on screen share one focus enum,
    /// e.g. `@FocusState private var focusedField: Field?` and `.focused($focusedField, equals: .code)`.
    public func focused<V: Hashable>(_ binding: FocusState<V?>.Binding, equals value: V) -> KitoCodeField {
        let bridged = Binding<Bool>(
            get: { binding.wrappedValue == value },
            set: { binding.wrappedValue = $0 ? value : nil }
        )
        return mutating { $0.focusBinding = bridged }
    }
    /// Fully replaces the box chrome with your own `KitoCodeFieldStyle`. `KitoCodeUnderlineBoxStyle`
    /// and `KitoCodePillBoxStyle` ship as worked examples. Without this, `.filledBox`/`.activeBox`/
    /// `.errorBox`/`.boxStyle`/`.boxShape`/`.digitColor` keep working exactly as before.
    public func style<S: KitoCodeFieldStyle>(_ style: S) -> KitoCodeField { mutating { $0.customStyle = AnyKitoCodeFieldStyle(style) } }

    private struct Blink: ViewModifier {
        @State private var visible = true
        func body(content: Content) -> some View {
            content
                .opacity(visible ? 1 : 0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { visible = false }
                }
        }
    }
}


/// `onTapGesture` does not exist on tvOS; focus comes from the remote there.
private struct FocusOnTap: ViewModifier {
    let action: () -> Void
    func body(content: Content) -> some View {
        #if os(tvOS)
        content
        #else
        content.onTapGesture(perform: action)
        #endif
    }
}
