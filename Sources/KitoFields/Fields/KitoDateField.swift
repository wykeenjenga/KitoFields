//
//  KitoDateField.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI

/// Masked date entry ("dd/MM/yyyy" by default) bound to a `Date?`, with real-date validation,
/// optional min/max and a calendar button that opens a graphical picker.
///
/// ```swift
/// KitoDateField("Date of birth", date: $dob)
///     .format("MM/dd/yyyy")
///     .range(min: nil, max: Date())
/// ```
public struct KitoDateField: View, KitoFieldConfigurable {
    public var options = KitoFieldOptions()
    @Binding private var date: Date?
    @State private var text = ""
    @State private var showsPicker = false
    private var format = "dd/MM/yyyy"
    private var minDate: Date?
    private var maxDate: Date?
    private var showsCalendarButton = true
    private var mustBeFuture = false

    public init(_ label: String? = nil, date: Binding<Date?>, prompt: String? = nil) {
        _date = date
        options.label = label
        options.placeholder = prompt
        options.keyboard = .numberPad
        options.leading = .systemImage("calendar")
    }

    private var mask: String { format.map { $0.isLetter ? "#" : $0 }.reduce(into: "") { $0.append($1) } }

    public static func parse(_ text: String, format: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = format
        f.locale = Locale(identifier: "en_US_POSIX")
        f.isLenient = false
        guard text.count == format.count, let d = f.date(from: text) else { return nil }
        return f.string(from: d) == text ? d : nil   // rejects 31/02
    }

    private func string(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = format; f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: date)
    }

    public var body: some View {
        var field = KitoTextField(options.label, text: $text, prompt: options.placeholder ?? format.uppercased())
        field.options = options
        field.options.mask = mask
        field.options.characterLimit = mask.count
        #if !os(iOS)
        field.options.transform = { KitoPhoneFormatter().apply(mask: mask, to: String($0.asciiDigits.prefix(mask.digitCount))) }
        #endif
        var rules = options.rules
        rules.append(.date(format: format))
        if mustBeFuture {
            rules.append(KitoRule(id: "inputkit.date.future", message: KitoLocalization.string("date.past", "Date must be in the future")) { Self.parse($0, format: format).map { $0 > Date() } ?? true })
        }
        if let minDate {
            rules.append(KitoRule(id: "inputkit.date.min", message: KitoLocalization.format("number.min", "Must be at least %@", string(minDate))) { Self.parse($0, format: format).map { $0 >= minDate } ?? true })
        }
        if let maxDate {
            rules.append(KitoRule(id: "inputkit.date.max", message: KitoLocalization.format("number.max", "Must be at most %@", string(maxDate))) { Self.parse($0, format: format).map { $0 <= maxDate } ?? true })
        }
        field.options.rules = rules
        if showsCalendarButton, options.trailing == nil {
            field.options.trailing = .button(systemImage: "calendar.badge.clock", accessibilityLabel: "Pick a date") { showsPicker = true }
        }
        return field
            .onChange(of: text) { newText in
                let parsed = Self.parse(newText, format: format)
                if parsed != date { date = parsed }
            }
            .onChange(of: date) { newDate in
                if let newDate, string(newDate) != text { text = string(newDate) }
                if newDate == nil, Self.parse(text, format: format) != nil { text = "" }
            }
            .onAppear { if let date { text = string(date) } }
            .sheet(isPresented: $showsPicker) { pickerSheet }
    }

    @ViewBuilder private var pickerSheet: some View {
        NavigationView {
            VStack {
                DatePicker("", selection: Binding(get: { date ?? Date() }, set: { date = $0 }), in: (minDate ?? .distantPast)...(maxDate ?? .distantFuture), displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                Spacer()
            }
            .navigationTitle(options.label ?? "")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button(KitoLocalization.string("picker.done", "Done")) { showsPicker = false } }
            }
        }
        .modifier(DateSheetDetents())
    }

    private struct DateSheetDetents: ViewModifier {
        func body(content: Content) -> some View {
            #if os(tvOS)
            content
            #else
            if #available(iOS 16.0, macOS 13.0, watchOS 9.0, visionOS 1.0, *) { content.presentationDetents([.medium, .large]) } else { content }
            #endif
        }
    }

    private func mutating(_ change: (inout KitoDateField) -> Void) -> KitoDateField { var c = self; change(&c); return c }
    /// Unicode date pattern using d, M and y, e.g. "MM/dd/yyyy" or "yyyy-MM-dd".
    public func format(_ pattern: String) -> KitoDateField { mutating { $0.format = pattern } }
    public func range(min: Date? = nil, max: Date? = nil) -> KitoDateField { mutating { $0.minDate = min; $0.maxDate = max } }
    public func future() -> KitoDateField { mutating { $0.mustBeFuture = true } }
    public func calendarButton(_ shows: Bool) -> KitoDateField { mutating { $0.showsCalendarButton = shows } }
}
