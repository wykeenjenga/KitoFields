//
//  FieldSampleCatalog.swift
//  KitoFieldsExample
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI
import KitoFields

enum FieldSampleCatalog {
    static let all: [FieldSample] = text + identity + password + phone + numbers + dates + choice + errors + validation + icons + styles + forms

    // Helper for a text-field sample: the same modifier chain is rendered and shown as code.
    private static func textSample(_ title: String, _ subtitle: String, category: FieldCategory, label: String?, prompt: String?, code modifiers: String, _ configure: @escaping (KitoTextField) -> KitoTextField) -> FieldSample {
        let labelCode = label.map { "\"\($0)\", " } ?? ""
        let promptCode = prompt.map { ", prompt: \"\($0)\"" } ?? ""
        return FieldSample(title, subtitle, category: category, code: "KitoTextField(\(labelCode)text: $text\(promptCode))\n\(modifiers)") {
            Stateful { text in configure(KitoTextField(label, text: text, prompt: prompt)) }
        }
    }

    // MARK: Text

    static let text: [FieldSample] = [
        textSample("Plain text field", "Title above, placeholder inside.", category: .text, label: "Full name", prompt: "Jane Doe", code: "") { $0 },
        textSample("No title", "Placeholder only, leading icon.", category: .text, label: nil, prompt: "Search products", code: "    .leadingIcon(\"magnifyingglass\")") { $0.leadingIcon("magnifyingglass") },
        textSample("Helper text", "Neutral hint under the field.", category: .text, label: "Display name", prompt: nil, code: "    .helperText(\"Shown to other members\")") { $0.helperText("Shown to other members") },
        textSample("Clear button", "Appears when there is text.", category: .text, label: "City", prompt: "Nairobi", code: "    .clearButton()") { $0.clearButton() },
        textSample("Hard character cap", "Blocks input past 12 characters, shows a counter.", category: .text, label: "Handle", prompt: nil, code: "    .characterLimit(12, showsCounter: true)") { $0.characterLimit(12, showsCounter: true) },
        textSample("Soft character cap", "Lets you type past the limit but flags it.", category: .text, label: "Tweet", prompt: "What's happening?", code: "    .characterLimit(40, showsCounter: true, hard: false, counter: .remaining)") { $0.characterLimit(40, showsCounter: true, hard: false, counter: .remaining) },
        textSample("Multiline", "Grows between 3 and 6 lines.", category: .text, label: "Bio", prompt: "Tell us about yourself", code: "    .multiline(3...6)") { $0.multiline(3...6) },
        textSample("Uppercase transform", "Transforms input as you type.", category: .text, label: "Promo code", prompt: "SAVE20", code: "    .transform { $0.uppercased() }\n    .autocapitalization(.characters)") { $0.transform { $0.uppercased() }.autocapitalization(.characters) },
        textSample("Digits only", "Filter keeps digits.", category: .text, label: "Reference", prompt: nil, code: "    .keyboard(.numberPad)\n    .transform { $0.filter(\\.isNumber) }") { $0.keyboard(.numberPad).transform { $0.filter(\.isNumber) } },
        textSample("Disabled", "Dimmed and non-interactive.", category: .text, label: "Account ID", prompt: nil, code: "    .disabled(true)") { $0 },
        FieldSample("Text area", "Multi-line with a remaining-characters counter.", category: .text, code: "KitoTextArea(\"Notes\", text: $notes, lines: 3...8, limit: 200)") {
            Stateful { KitoTextArea("Notes", text: $0, prompt: "Anything the driver should know?", lines: 3...8, limit: 200) }
        },
    ]

    // MARK: Identity

    static let identity: [FieldSample] = [
        FieldSample("Name field", "Words capitalization, letters only, animated person icon.", category: .identity, code: "KitoNameField(text: $name).required()") { Stateful { KitoNameField(text: $0).required() } },
        FieldSample("Given / family name", "Two name parts with autofill hints.", category: .identity, code: "KitoNameField(\"First name\", text: $first).part(.givenName)\nKitoNameField(\"Last name\", text: $last).part(.familyName)") {
            VStack(spacing: 14) {
                Stateful { KitoNameField("First name", text: $0, prompt: "Wycliff").part(.givenName) }
                Stateful { KitoNameField("Last name", text: $0, prompt: "Njenga").part(.familyName) }
            }
        },
        FieldSample("Email", "Email keyboard, whitespace stripped, validates on blur.", category: .identity, code: "KitoEmailField(text: $email).required()") { Stateful { KitoEmailField(text: $0).required() } },
        FieldSample("Email with typo suggestions", "Type name@gmial.com and tap the wand.", category: .identity, code: "KitoEmailField(text: $email)\n    .suggestsDomainCorrections()") { Stateful("wycliff@gmial.com") { KitoEmailField(text: $0).suggestsDomainCorrections() } },
        FieldSample("Email · live tick", "Live validation with a success indicator.", category: .identity, code: "KitoEmailField(text: $email)\n    .validationTrigger(.live)\n    .validationIndicators()") { Stateful { KitoEmailField(text: $0).validationTrigger(.live).validationIndicators() } },
        FieldSample("Username with availability", "Debounced async check: try “admin” (taken) or anything else.", category: .identity, code: "KitoUsernameField(text: $username)\n    .availability { name in\n        try await api.isAvailable(name)   // true = free\n    }") {
            Stateful { KitoUsernameField(text: $0).availability { name in
                try? await Task.sleep(nanoseconds: 700_000_000)
                return !["admin", "root", "wykee", "kito"].contains(name)
            } }
        },
        FieldSample("Website", "URL keyboard and validation.", category: .identity, code: "KitoURLField(text: $site)") { Stateful { KitoURLField(text: $0) } },
    ]

    // MARK: Password

    static let password: [FieldSample] = [
        FieldSample("Password", "Secure entry with reveal toggle.", category: .password, code: "KitoPasswordField(text: $password)") { Stateful { KitoPasswordField(text: $0) } },
        FieldSample("Animated lock icon", "Lock fills on focus, opens when revealed, wiggles on error.", category: .password, code: "KitoPasswordField(text: $password)\n    .animatedLockIcon()\n    .required()\n    .validation(.minLength(8), trigger: .live)") { Stateful { KitoPasswordField(text: $0).animatedLockIcon().required().validation(.minLength(8), trigger: .live) } },
        FieldSample("Strength meter", "Four-segment bar with label.", category: .password, code: "KitoPasswordField(text: $password)\n    .newPassword()\n    .strengthMeter()") { Stateful { KitoPasswordField(text: $0).newPassword().strengthMeter() } },
        FieldSample("Requirements checklist", "Ticks as each rule passes.", category: .password, code: "KitoPasswordField(text: $password)\n    .requirements(KitoRule.strongPassword())") { Stateful { KitoPasswordField(text: $0).requirements(KitoRule.strongPassword()) } },
        FieldSample("Checklist · chips", "Requirements as capsule chips that fill in.", category: .password, code: "KitoPasswordField(text: $pw)\n    .requirements(KitoRule.strongPassword())\n    .checklistStyle(.chips)") { Stateful("Kito") { KitoPasswordField(text: $0).requirements(KitoRule.strongPassword()).checklistStyle(.chips) } },
        FieldSample("Checklist · grid + progress", "Two columns with a “3 of 5 met” header.", category: .password, code: "KitoPasswordField(text: $pw)\n    .requirements(KitoRule.strongPassword())\n    .passwordUI { $0.checklistStyle = .grid; $0.showsProgressHeader = true }") { Stateful("Kito1") { KitoPasswordField(text: $0).requirements(KitoRule.strongPassword()).passwordUI { $0.checklistStyle = .grid; $0.showsProgressHeader = true } } },
        FieldSample("Checklist · compact", "Single line with a progress bar.", category: .password, code: "KitoPasswordField(text: $pw)\n    .requirements(KitoRule.strongPassword())\n    .checklistStyle(.compact)") { Stateful("Kit") { KitoPasswordField(text: $0).requirements(KitoRule.strongPassword()).checklistStyle(.compact) } },
        FieldSample("Checklist · only unmet, hides when done", "Rules disappear as they pass.", category: .password, code: "KitoPasswordField(text: $pw)\n    .requirements(KitoRule.strongPassword())\n    .passwordUI { $0.showsOnlyUnmet = true; $0.hidesChecklistWhenAllMet = true }") { Stateful("Kito!") { KitoPasswordField(text: $0).requirements(KitoRule.strongPassword()).passwordUI { $0.showsOnlyUnmet = true; $0.hidesChecklistWhenAllMet = true } } },
        FieldSample("Checklist · custom icons & colours", "Seal icons, strikethrough, indigo palette.", category: .password, code: "KitoPasswordField(text: $pw)\n    .requirements(KitoRule.strongPassword())\n    .passwordUI { ui in\n        ui.metSymbol = \"checkmark.seal.fill\"; ui.unmetSymbol = \"seal\"\n        ui.metColor = .indigo; ui.unmetColor = .gray\n        ui.strikesThroughMet = true\n    }") { Stateful("Kito!2") { KitoPasswordField(text: $0).requirements(KitoRule.strongPassword()).passwordUI { ui in ui.metSymbol = "checkmark.seal.fill"; ui.unmetSymbol = "seal"; ui.metColor = .indigo; ui.unmetColor = .gray; ui.strikesThroughMet = true } } },
        FieldSample("Meter · bar", "Continuous bar that fills and recolours.", category: .password, code: "KitoPasswordField(text: $pw).strengthMeter().meterStyle(.bar)") { Stateful("Kito!20") { KitoPasswordField(text: $0).strengthMeter().meterStyle(.bar) } },
        FieldSample("Meter · ring", "Ring with the score inside.", category: .password, code: "KitoPasswordField(text: $pw).strengthMeter()\n    .passwordUI { $0.meterStyle = .ring; $0.showsScoreOutOf = true }") { Stateful("Kito!2026") { KitoPasswordField(text: $0).strengthMeter().passwordUI { $0.meterStyle = .ring; $0.showsScoreOutOf = true } } },
        FieldSample("Meter · dots, custom labels & colours", "Six dots, your own level names and palette.", category: .password, code: "KitoPasswordField(text: $pw).strengthMeter()\n    .passwordUI { ui in\n        ui.meterStyle = .dots(6)\n        ui.levelLabels = [.veryWeak: \"Nope\", .weak: \"Meh\", .fair: \"Okay\", .strong: \"Nice\", .veryStrong: \"Fort Knox\"]\n        ui.levelColors = [.fair: .yellow, .strong: .teal, .veryStrong: .mint]\n    }") { Stateful("Kito!2026") { KitoPasswordField(text: $0).strengthMeter().passwordUI { ui in ui.meterStyle = .dots(6); ui.levelLabels = [.veryWeak: "Nope", .weak: "Meh", .fair: "Okay", .strong: "Nice", .veryStrong: "Fort Knox"]; ui.levelColors = [.fair: .yellow, .strong: .teal, .veryStrong: .mint] } } },
        FieldSample("Meter · text only, checklist first", "Label only; requirements above the meter.", category: .password, code: "KitoPasswordField(text: $pw).strengthMeter().requirements(KitoRule.strongPassword())\n    .passwordUI { $0.meterStyle = .textOnly; $0.order = .checklistThenMeter }") { Stateful("Kito!2026") { KitoPasswordField(text: $0).strengthMeter().requirements(KitoRule.strongPassword()).passwordUI { $0.meterStyle = .textOnly; $0.order = .checklistThenMeter } } },
        FieldSample("Custom scorer", "Your own strength function, e.g. length-based.", category: .password, code: "KitoPasswordField(text: $pw).strengthMeter()\n    .passwordUI { $0.scorer = { pw in\n        switch pw.count { case 0..<6: return .veryWeak; case 6..<8: return .weak; case 8..<12: return .fair; case 12..<16: return .strong; default: return .veryStrong }\n    } }") { Stateful("Kito!2026") { KitoPasswordField(text: $0).strengthMeter().passwordUI { $0.scorer = { pw in switch pw.count { case 0..<6: return .veryWeak; case 6..<8: return .weak; case 8..<12: return .fair; case 12..<16: return .strong; default: return .veryStrong } } } } },
        FieldSample("Strict rules", "Strong + not common, no repeats, no sequences, not your email.", category: .password, code: "KitoPasswordField(text: $pw)\n    .requirements(KitoRule.strictPassword() + [.notContaining({ email })])\n    .checklistStyle(.chips)") { Stateful("password1234") { KitoPasswordField(text: $0).requirements(KitoRule.strictPassword() + [.notContaining({ "wycliff@triply.co" })]).checklistStyle(.chips) } },
        FieldSample("Custom messages", "Rule text in your own words (or language).", category: .password, code: "KitoPasswordField(text: $pw).requirements([\n    .minLength(8, message: \"8+ characters\"),\n    .containsUppercase(message: \"A capital letter\"),\n    .containsDigit(message: \"A number\"),\n])") { Stateful { KitoPasswordField(text: $0).requirements([.minLength(8, message: "8+ characters"), .containsUppercase(message: "A capital letter"), .containsDigit(message: "A number")]) } },
        FieldSample("Confirm password", "Fails while the two differ.", category: .password, code: "KitoPasswordField(\"Confirm\", text: $confirm)\n    .mustMatch($password)\n    .validationTrigger(.live)") { ConfirmSample() },
        FieldSample("No reveal button", "Reveal disabled.", category: .password, code: "KitoPasswordField(text: $pin).revealable(false)") { Stateful { KitoPasswordField("PIN", text: $0, prompt: "••••").revealable(false).keyboard(.numberPad).characterLimit(4) } },
        FieldSample("CVV", "3 digits, hidden, reveal available.", category: .password, code: "KitoCVVField(text: $cvv, length: 3)") { Stateful { KitoCVVField(text: $0) } },
    ]

    // MARK: Phone & country

    static let phone: [FieldSample] = [
        FieldSample("Phone number", "US default, as-you-type formatting, E.164 output.", category: .phone, code: "KitoPhoneField(\"Mobile\", phoneNumber: $phone)") { PhoneSample(nil) },
        FieldSample("Phone · circle flag", "Flag clipped to a circle.", category: .phone, code: "KitoPhoneField(phoneNumber: $phone).flagStyle(.circle)") { PhoneSample { $0.flagStyle(.circle) } },
        FieldSample("Phone · device region", "Follows the device locale instead of the US default.", category: .phone, code: "KitoPhoneField(phoneNumber: $phone).defaultCountry(.deviceRegion)") { PhoneSample { $0.defaultCountry(.deviceRegion) } },
        FieldSample("Phone · locked to Kenya", "No selector; digits only.", category: .phone, code: "KitoPhoneField(phoneNumber: $phone)\n    .defaultCountry(\"KE\")\n    .countrySelection(.locked)\n    .showsChevron(false)") { PhoneSample { $0.defaultCountry("KE").countrySelection(.locked).showsChevron(false) } },
        FieldSample("Phone · allowed list", "East Africa only, menu selection.", category: .phone, code: "KitoPhoneField(phoneNumber: $phone)\n    .countries(allowed: [\"KE\", \"UG\", \"TZ\", \"RW\"], preferred: [\"KE\"])\n    .countrySelection(.menu)") { PhoneSample { $0.countries(allowed: ["KE", "UG", "TZ", "RW"], preferred: ["KE"]).countrySelection(.menu) } },
        FieldSample("Phone · required + indicators", "Error and success icons.", category: .phone, code: "KitoPhoneField(phoneNumber: $phone)\n    .required()\n    .validationIndicators()") { PhoneSample { $0.required().validationIndicators() } },
        FieldSample("Country field", "Flag, name, dial code and currency.", category: .phone, code: "KitoCountryField(\"Country\", selection: $country)\n    .shows(flag: true, name: true, dialCode: true, currency: true)") { CountrySample { $0.shows(flag: true, name: true, dialCode: true, currency: true) } },
        FieldSample("Country · ISO badge", "Two-letter badge instead of an emoji flag.", category: .phone, code: "KitoCountryField(selection: $country).flagStyle(.isoCode)") { CountrySample { $0.flagStyle(.isoCode) } },
        FieldSample("Country · tile flag", "Flag on a soft tile.", category: .phone, code: "KitoCountryField(selection: $country).flagStyle(.tile)") { CountrySample { $0.flagStyle(.tile) } },
        FieldSample("Country · menu", "Compact menu for short lists.", category: .phone, code: "KitoCountryField(selection: $country)\n    .countries(allowed: [\"KE\", \"UG\", \"TZ\"])\n    .selectionMode(.menu)") { CountrySample { $0.countries(allowed: ["KE", "UG", "TZ"]).selectionMode(.menu) } },
    ]

    // MARK: Numbers & money

    static let numbers: [FieldSample] = [
        FieldSample("Number", "Decimal keyboard, locale separators, grouping on blur.", category: .numbers, code: "KitoNumberField(\"Weight\", value: $weight).unit(\"kg\")") { NumberSample { $0.unit("kg") } },
        FieldSample("Integer with stepper", "Whole numbers, plus/minus, range 1…99.", category: .numbers, code: "KitoNumberField(\"Quantity\", value: $qty)\n    .integer()\n    .range(1...99)\n    .stepper()") { NumberSample(1) { $0.integer().range(1...99).stepper() } },
        FieldSample("Percentage", "0…100 with a % suffix.", category: .numbers, code: "KitoNumberField(\"Discount\", value: $pct)\n    .integer().range(0...100).unit(\"%\")") { NumberSample { $0.integer().range(0...100).unit("%") } },
        FieldSample("Currency · KES", "Two decimals, symbol prefix, formatted on blur.", category: .numbers, code: "KitoCurrencyField(\"Amount\", value: $amount, currencyCode: \"KES\")") { CurrencySample("KES") },
        FieldSample("Currency · USD", "Same field, different currency.", category: .numbers, code: "KitoCurrencyField(\"Price\", value: $price, currencyCode: \"USD\")") { CurrencySample("USD") },
        FieldSample("Currency from country", "Currency follows a country selection.", category: .numbers, code: "KitoCurrencyField(\"Amount\", value: $amount, country: country)") { CurrencySample("EUR") },
    ]

    // MARK: Dates & cards

    static let dates: [FieldSample] = [
        FieldSample("Date · dd/MM/yyyy", "Masked entry, rejects impossible dates, calendar button.", category: .dates, code: "KitoDateField(\"Date of birth\", date: $dob)\n    .range(max: Date())") { DateSample { $0.range(max: Date()) } },
        FieldSample("Date · MM/dd/yyyy", "US ordering.", category: .dates, code: "KitoDateField(\"Start date\", date: $start).format(\"MM/dd/yyyy\")") { DateSample { $0.format("MM/dd/yyyy") } },
        FieldSample("Date · future only", "Booking dates must be after today.", category: .dates, code: "KitoDateField(\"Check-in\", date: $date).future()") { DateSample { $0.future() } },
        FieldSample("Card number", "Brand detection, grouping and Luhn. Try 4111 1111 1111 1111 or 3782 822463 10005.", category: .dates, code: "KitoCardNumberField(number: $card)\n    .onBrandChange { brand in cvvLength = brand.cvvLength }") { Stateful { KitoCardNumberField(number: $0) } },
        FieldSample("Expiry + CVV", "MM/YY with not-expired check, 3-digit code.", category: .dates, code: "HStack {\n    KitoCardExpiryField(text: $expiry)\n    KitoCVVField(text: $cvv)\n}") {
            HStack(spacing: 12) {
                Stateful { KitoCardExpiryField(text: $0) }
                Stateful { KitoCVVField(text: $0) }
            }
        },
        FieldSample("Full card form", "Number, expiry, CVV and name together.", category: .dates, code: "KitoCardNumberField(number: $number)\nHStack { KitoCardExpiryField(text: $expiry); KitoCVVField(text: $cvv) }\nKitoNameField(\"Name on card\", text: $name)") {
            VStack(spacing: 14) {
                Stateful { KitoCardNumberField(number: $0) }
                HStack(spacing: 12) { Stateful { KitoCardExpiryField(text: $0) }; Stateful { KitoCVVField(text: $0) } }
                Stateful { KitoNameField("Name on card", text: $0, prompt: "WYCLIFF NJENGA").autocapitalization(.characters) }
            }
        },
    ]

    // MARK: Select, search & code

    static let choice: [FieldSample] = [
        FieldSample("Select · sheet", "Searchable list with subtitles and icons.", category: .choice, code: "KitoSelectField(\"Delivery speed\", selection: $speed, options: [\n    KitoSelectOption(\"Standard\", subtitle: \"3–5 days\", systemImage: \"tortoise\"),\n    KitoSelectOption(\"Express\", subtitle: \"Tomorrow\", systemImage: \"hare\"),\n])") { SelectSample(menu: false) },
        FieldSample("Select · menu", "Compact menu for short lists.", category: .choice, code: "KitoSelectField(\"Size\", selection: $size, options: [\"S\", \"M\", \"L\", \"XL\"]).menu()") { SelectSample(menu: true) },
        FieldSample("Search field", "Magnifier, clear button, debounced onSearch.", category: .choice, code: "KitoSearchField(text: $query)\n    .onSearch { term in results = search(term) }") { SearchSample() },
        FieldSample("One-time code · 6 digits", "Boxes backed by one hidden field.", category: .choice, code: "KitoCodeField(code: $code, length: 6)") { Stateful { KitoCodeField(code: $0, length: 6) } },
        FieldSample("One-time code · 4 secure", "Masked digits, error on wrong code (try 1234).", category: .choice, code: "KitoCodeField(code: $code, length: 4)\n    .secure()\n    .errorMessage(wrong ? \"Incorrect code\" : nil)") { CodeSample() },
        FieldSample("Alphanumeric code", "Letters and digits, uppercased.", category: .choice, code: "KitoCodeField(code: $code, length: 5).alphanumeric()") { Stateful { KitoCodeField(code: $0, length: 5).alphanumeric() } },
        FieldSample("One-time code + resend", "KitoResendCodeButton disables itself and counts down after each tap.", category: .choice, code: "KitoCodeField(code: $code, length: 4)\nKitoResendCodeButton(cooldown: 30) { resend() }") { CodeWithResendSample() },
        FieldSample("Large boxes · no caret", "Big grey boxes, focus shown by the border only.", category: .choice, code: "KitoCodeField(code: $code, length: 4)\n    .boxSize(CGSize(width: 64, height: 72))\n    .spacing(20)\n    .showsCaret(false)\n    .digitFont(.system(size: 28, weight: .semibold))\n    .kitoFieldTheme(largeBoxTheme)") { Stateful { KitoCodeField(code: $0, length: 4).boxSize(CGSize(width: 64, height: 72)).spacing(20).showsCaret(false).digitFont(.system(size: 28, weight: .semibold)).kitoFieldTheme(FieldSampleCatalog.largeBoxTheme) } },
        FieldSample("Filled box · tinted", "A typed box turns white with a tinted border and shadow; empty boxes stay grey.", category: .choice, code: "KitoCodeField(code: $code, length: 4)\n    .filledBox(fill: .white, borderColor: .accentColor, shadow: KitoShadow(color: .accentColor.opacity(0.2), radius: 8, y: 2))\n    .kitoFieldTheme(filledBoxTheme)") { Stateful { KitoCodeField(code: $0, length: 4).filledBox(fill: .white, borderColor: .accentColor, shadow: KitoShadow(color: .accentColor.opacity(0.2), radius: 8, y: 2)).kitoFieldTheme(FieldSampleCatalog.filledBoxTheme) } },
        FieldSample("Grouped · \"123 - 456\"", "groups([3, 3]) places a themed dash between the two halves.", category: .choice, code: "KitoCodeField(code: $code, length: 6).groups([3, 3])") { Stateful { KitoCodeField(code: $0, length: 6).groups([3, 3]) } },
        FieldSample("Grouped · dot", "groups(_:separator:) also takes .dot, or your own view.", category: .choice, code: "KitoCodeField(code: $code, length: 6).groups([3, 3], separator: .dot)") { Stateful { KitoCodeField(code: $0, length: 6).groups([3, 3], separator: .dot) } },
        FieldSample("Underline boxes", "boxStyle(.underline) drops the box and leaves one line per digit.", category: .choice, code: "KitoCodeField(code: $code, length: 6)\n    .boxStyle(.underline)") { Stateful { KitoCodeField(code: $0, length: 6).boxStyle(.underline) } },
        FieldSample("Filled boxes · no border", "boxStyle(.filled) fills each box and drops the idle border.", category: .choice, code: "KitoCodeField(code: $code, length: 6)\n    .boxStyle(.filled)\n    .boxShape(.capsule)") { Stateful { KitoCodeField(code: $0, length: 6).boxStyle(.filled).boxShape(.capsule) } },
        FieldSample("Six wide boxes on any phone", "distribution(.fill) shrinks 58pt boxes proportionally instead of running off a small screen.", category: .choice, code: "KitoCodeField(code: $code, length: 6)\n    .boxSize(CGSize(width: 58, height: 64))\n    .distribution(.fill)\n    .minimumBoxWidth(36)") { Stateful { KitoCodeField(code: $0, length: 6).boxSize(CGSize(width: 58, height: 64)).distribution(.fill).minimumBoxWidth(36) } },
        FieldSample("Per-state box styling", "activeBox and errorBox mirror filledBox for the focused and error states.", category: .choice, code: "KitoCodeField(code: $code, length: 4)\n    .filledBox(fill: .white)\n    .activeBox(borderColor: .accentColor, borderWidth: 2)\n    .errorBox(fill: .red.opacity(0.06), borderColor: .red)\n    .digitColor(filled: .primary, active: .accentColor)") { CodeStateStylingSample() },
        FieldSample("Reveal the last digit", "secure() + revealLastEntered shows a digit briefly before masking it, like the system passcode field.", category: .choice, code: "KitoCodeField(code: $code, length: 6)\n    .secure()\n    .revealLastEntered(for: 0.8)\n    .maskCharacter(\"•\")") { Stateful { KitoCodeField(code: $0, length: 6).secure().revealLastEntered(for: 0.8).maskCharacter("•") } },
        FieldSample("Success tick", "showsSuccess recolours the boxes; successAnimation(.tick) fades a checkmark over them.", category: .choice, code: "KitoCodeField(code: $code, length: 4)\n    .showsSuccess($verified)\n    .successAnimation(.tick)\n    .haptics(onDigit: true, onComplete: true)") { CodeSuccessSample() },
        FieldSample("Built-in resend", "resendButton(after:) places a KitoResendCodeButton under the boxes for you.", category: .choice, code: "KitoCodeField(code: $code, length: 4)\n    .resendButton(after: 8) { resend() }") { CodeBuiltInResendSample() },
        FieldSample("Custom box style", "KitoCodeFieldStyle replaces the chrome entirely; KitoCodePillBoxStyle ships as a worked example.", category: .choice, code: "KitoCodeField(code: $code, length: 5)\n    .style(KitoCodePillBoxStyle())") { Stateful { KitoCodeField(code: $0, length: 5).style(KitoCodePillBoxStyle()) } },
    ]

    static var largeBoxTheme: KitoFieldTheme {
        var theme = KitoFieldTheme()
        theme.shape = .roundedRectangle(cornerRadius: 14)
        theme.backgroundColor = Color(.systemGray6)
        theme.borderColor = Color(.systemGray4)
        theme.borderWidth = 1
        theme.focusedBorderColor = Color(.systemGray)
        theme.focusedBorderWidth = 2
        return theme
    }

    static var filledBoxTheme: KitoFieldTheme {
        var theme = KitoFieldTheme()
        theme.shape = .roundedRectangle(cornerRadius: 12)
        theme.backgroundColor = Color(.systemGray6)
        theme.borderColor = .clear
        theme.borderWidth = 1
        return theme
    }

    // MARK: Error presentation

    static let errors: [FieldSample] = [
        textSample("Inline error", "Text under the field (default).", category: .errors, label: "Username", prompt: "at least 4 characters", code: "    .required()\n    .validation(.minLength(4), trigger: .live)") { $0.required().validation(.minLength(4), trigger: .live) },
        textSample("Floating bubble", "Error floats above the field while it exists.", category: .errors, label: "Username", prompt: "at least 4 characters", code: "    .validation(.minLength(4), trigger: .live)\n    .errorPresentation(.floating)") { $0.validation(.minLength(4), trigger: .live).errorPresentation(.floating) },
        textSample("Bubble while focused", "Bubble only while editing; border stays red.", category: .errors, label: "Username", prompt: "at least 4 characters", code: "    .validation(.minLength(4), trigger: .live)\n    .errorPresentation(.floatingWhenFocused)") { $0.validation(.minLength(4), trigger: .live).errorPresentation(.floatingWhenFocused) },
        textSample("Indicator only", "No message; border and icon change.", category: .errors, label: "Username", prompt: "at least 4 characters", code: "    .validation(.minLength(4), trigger: .live)\n    .errorPresentation(.none)\n    .validationIndicators()") { $0.validation(.minLength(4), trigger: .live).errorPresentation(.none).validationIndicators() },
        textSample("Server-side error", "An error you set from an API response.", category: .errors, label: "Email", prompt: nil, code: "    .errorMessage(serverError)   // e.g. \"Already registered\"") { $0.errorMessage("That email is already registered") },
        FieldSample("All errors listed", "Theme errorDisplay = .all shows every failing rule.", category: .errors, code: "KitoTextField(\"Password\", text: $text)\n    .validation(.minLength(8), .containsDigit(), .containsSymbol(), trigger: .live)\n    .kitoFieldTheme { $0.errorDisplay = .all }") {
            Stateful("abc") { KitoTextField("Password", text: $0).validation(.minLength(8), .containsDigit(), .containsSymbol(), trigger: .live).kitoFieldTheme { $0.errorDisplay = .all } }
        },
    ]

    // MARK: Validation & limits

    static let validation: [FieldSample] = [
        textSample("Required", "Asterisk in the label, error on blur when empty.", category: .validation, label: "Company", prompt: nil, code: "    .required()") { $0.required() },
        textSample("Optional indicator", "Theme optionalIndicator shows “(optional)”.", category: .validation, label: "Middle name", prompt: nil, code: "    .kitoFieldTheme { $0.optionalIndicator = \"(optional)\" }") { $0 },
        textSample("Live validation", "Errors appear as you type.", category: .validation, label: "Slug", prompt: "lowercase-with-dashes", code: "    .validation(.regex(\"^[a-z0-9-]+$\", message: \"Lowercase letters, digits and dashes\"), trigger: .live)") { $0.validation(.regex("^[a-z0-9-]+$", message: "Lowercase letters, digits and dashes"), trigger: .live) },
        textSample("Validate on submit", "Errors only after pressing Return.", category: .validation, label: "Coupon", prompt: nil, code: "    .validation(.exactLength(6), trigger: .onSubmit)") { $0.validation(.exactLength(6), trigger: .onSubmit) },
        textSample("Custom rule", "Any predicate with a message.", category: .validation, label: "Even number", prompt: nil, code: "    .validation(.custom(message: \"Must be even\") { Int($0).map { $0 % 2 == 0 } ?? false }, trigger: .live)") { $0.keyboard(.numberPad).validation(.custom(message: "Must be even") { Int($0).map { $0 % 2 == 0 } ?? false }, trigger: .live) },
        textSample("Success indicator", "Tick when every rule passes.", category: .validation, label: "Postal code", prompt: "00100", code: "    .validation(.numeric(), .exactLength(5), trigger: .live)\n    .validationIndicators()") { $0.keyboard(.numberPad).validation(.numeric(), .exactLength(5), trigger: .live).validationIndicators() },
        textSample("isValid binding", "Drive a submit button from the field's validity.", category: .validation, label: "Team name", prompt: nil, code: "    .required()\n    .isValid($canSubmit)      // Binding<Bool>") { $0.required() },
    ]

    // MARK: Icons & accessories

    static let icons: [FieldSample] = [
        textSample("Animated icon · bounce", "Fills and bounces on focus.", category: .icons, label: "Name", prompt: nil, code: "    .leadingIcon(\"person\", focused: \"person.fill\", motion: .bounce)") { $0.leadingIcon("person", focused: "person.fill", motion: .bounce) },
        textSample("Animated icon · wiggle", "Wiggles on focus and on error.", category: .icons, label: "Email", prompt: nil, code: "    .leadingIcon(\"envelope\", focused: \"envelope.open.fill\", motion: .wiggle)\n    .validation(.email, trigger: .live)") { $0.leadingIcon("envelope", focused: "envelope.open.fill", motion: .wiggle).validation(.email, trigger: .live) },
        textSample("Animated icon · pulse", "Pulse ring on focus.", category: .icons, label: "Location", prompt: nil, code: "    .leadingIcon(\"location\", focused: \"location.fill\", motion: .pulse)") { $0.leadingIcon("location", focused: "location.fill", motion: .pulse) },
        textSample("Error glyph", "Different symbol while invalid.", category: .icons, label: "Age", prompt: nil, code: "    .leadingIcon(\"calendar\", focused: \"calendar\", error: \"calendar.badge.exclamationmark\", motion: .swap)\n    .validation(.numeric(), trigger: .live)") { $0.leadingIcon("calendar", focused: "calendar", error: "calendar.badge.exclamationmark", motion: .swap).validation(.numeric(), trigger: .live) },
        textSample("Text accessories", "Prefix and suffix text.", category: .icons, label: "Price", prompt: "0.00", code: "    .leadingAccessory(.text(\"KES\"))\n    .trailingAccessory(.text(\"/ month\"))") { $0.leadingAccessory(.text("KES")).trailingAccessory(.text("/ month")).keyboard(.decimalPad) },
        textSample("Trailing button", "Any action in the trailing slot.", category: .icons, label: "Referral link", prompt: nil, code: "    .trailingAccessory(.button(systemImage: \"doc.on.doc\", accessibilityLabel: \"Copy\") { copy() })") { $0.trailingAccessory(.button(systemImage: "doc.on.doc", accessibilityLabel: "Copy") {}) },
        textSample("Reactive custom accessory", "Reads focus/error state.", category: .icons, label: "Handle", prompt: nil, code: "    .leadingAccessory(.reactive { ctx in\n        Circle().fill(ctx.hasError ? .red : ctx.isFocused ? .green : .gray).frame(width: 10, height: 10)\n    })") { $0.leadingAccessory(.reactive { ctx in Circle().fill(ctx.hasError ? Color.red : ctx.isFocused ? Color.green : Color.gray).frame(width: 10, height: 10) }).validation(.minLength(3), trigger: .live) },
        textSample("Custom image", "Your own asset as the icon.", category: .icons, label: "Payment", prompt: nil, code: "    .leadingAccessory(.image(Image(\"mpesa\")))") { $0.leadingAccessory(.image(Image(systemName: "creditcard.fill"))) },
    ]

    // MARK: Styles & shapes

    static let styles: [FieldSample] = [
        FieldSample("Outlined", "Border, transparent background (default).", category: .styles, code: ".kitoFieldStyle(.outlined)") { StyleSample { AnyView($0.kitoFieldStyle(.outlined)) } },
        FieldSample("Filled", "Solid fill, border on focus.", category: .styles, code: ".kitoFieldStyle(.filled)") { StyleSample { AnyView($0.kitoFieldStyle(.filled)) } },
        FieldSample("Underlined", "One line under the text.", category: .styles, code: ".kitoFieldStyle(.underlined)") { StyleSample { AnyView($0.kitoFieldStyle(.underlined)) } },
        FieldSample("Floating label", "Label floats from placeholder to top.", category: .styles, code: ".kitoFieldStyle(.floatingLabel)") { StyleSample { AnyView($0.kitoFieldStyle(.floatingLabel)) } },
        FieldSample("Plain", "No chrome at all.", category: .styles, code: ".kitoFieldStyle(.plain)") { StyleSample { AnyView($0.kitoFieldStyle(.plain)) } },
        FieldSample("Capsule", "Any style, capsule shape.", category: .styles, code: ".kitoFieldShape(.capsule)") { StyleSample { AnyView($0.kitoFieldShape(.capsule)) } },
        FieldSample("Rectangle · thick border", "Sharp corners, heavier border.", category: .styles, code: ".kitoFieldTheme(.sharp)") { StyleSample { AnyView($0.kitoFieldTheme(.sharp)) } },
        FieldSample("Soft shadow", "No border, drop shadow.", category: .styles, code: ".kitoFieldTheme(.soft)") { StyleSample { AnyView($0.kitoFieldTheme(.soft)) } },
        FieldSample("Brand theme", "Custom colours and fonts.", category: .styles, code: ".kitoFieldStyle(.filled)\n.kitoFieldTheme { t in\n    t.filledBackgroundColor = .indigo.opacity(0.08)\n    t.focusedBorderColor = .indigo\n    t.textColor = .indigo\n    t.font = .system(.body, design: .rounded)\n}") { StyleSample { AnyView($0.kitoFieldStyle(.filled).kitoFieldTheme { t in t.filledBackgroundColor = .indigo.opacity(0.08); t.focusedBorderColor = .indigo; t.textColor = .indigo; t.labelColor = .indigo; t.font = .system(.body, design: .rounded) }) } },
        FieldSample("Lively motion", "Spring focus with lift and glow.", category: .styles, code: ".kitoFieldTheme { $0.motion = .lively }") { StyleSample { AnyView($0.kitoFieldTheme { $0.motion = .lively }) } },
    ]

    // MARK: Complete forms

    static let forms: [FieldSample] = [
        FieldSample("Sign-up form", "Name, email, phone, password, confirm.", category: .forms, code: "See SignUpFormDemo in the example app.") { SignUpFormDemo().frame(height: 640) },
        FieldSample("Sign-up form (KitoForm)", "One controller validates every field and jumps focus to the first failure.", category: .forms, code: "KitoTextField(...).kitoFormField(.name, form: form, focus: $focus, equals: .name)\n// ... one field per case ...\nButton(\"Create account\") { guard form.validate() else { return } }") { KitoFormDemo().frame(height: 700) },
        FieldSample("Checkout", "Card, expiry, CVV, name, country.", category: .forms, code: "KitoCardNumberField(number: $card)\nHStack { KitoCardExpiryField(text: $exp); KitoCVVField(text: $cvv) }\nKitoNameField(\"Name on card\", text: $name)\nKitoCountryField(\"Billing country\", selection: $country)") {
            VStack(spacing: 14) {
                Stateful { KitoCardNumberField(number: $0) }
                HStack(spacing: 12) { Stateful { KitoCardExpiryField(text: $0) }; Stateful { KitoCVVField(text: $0) } }
                Stateful { KitoNameField("Name on card", text: $0) }
                CountrySample { $0.shows(flag: true, name: true) }
            }
        },
        FieldSample("Booking", "Dates, guests and contact.", category: .forms, code: "KitoDateField(\"Check-in\", date: $in).future()\nKitoDateField(\"Check-out\", date: $out).future()\nKitoNumberField(\"Guests\", value: $guests).integer().range(1...8).stepper()\nKitoPhoneField(\"Contact\", phoneNumber: $phone)") {
            VStack(spacing: 14) {
                DateSample { $0.future() }
                NumberSample(2) { $0.integer().range(1...8).stepper() }
                PhoneSample(nil)
            }
        },
    ]
}

// MARK: - Stateful sample views

private struct ConfirmSample: View {
    @State private var password = ""
    @State private var confirm = ""
    var body: some View {
        VStack(spacing: 14) {
            KitoPasswordField(text: $password)
            KitoPasswordField("Confirm", text: $confirm, prompt: "Re-enter").mustMatch($password).validationTrigger(.live)
        }
    }
}

private struct PhoneSample: View {
    @State private var phone: KitoPhoneNumber?
    let configure: ((KitoPhoneField) -> KitoPhoneField)?
    init(_ configure: ((KitoPhoneField) -> KitoPhoneField)?) { self.configure = configure }
    var body: some View {
        let field = KitoPhoneField("Mobile", phoneNumber: $phone)
        VStack(alignment: .leading, spacing: 6) {
            configure?(field) ?? field
            Text(phone?.e164 ?? "—").font(.footnote.monospaced()).foregroundColor(.secondary)
        }
    }
}

private struct CountrySample: View {
    @State private var country: KitoCountry? = KitoCountryDatabase.country(isoCode: "KE")
    let configure: (KitoCountryField) -> KitoCountryField
    var body: some View { configure(KitoCountryField("Country", selection: $country)) }
}

private struct NumberSample: View {
    @State private var value: Double?
    let configure: (KitoNumberField) -> KitoNumberField
    init(_ initial: Double? = nil, _ configure: @escaping (KitoNumberField) -> KitoNumberField) { _value = State(initialValue: initial); self.configure = configure }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            configure(KitoNumberField("Value", value: $value))
            Text(value.map { "\($0)" } ?? "nil").font(.footnote.monospaced()).foregroundColor(.secondary)
        }
    }
}

private struct CurrencySample: View {
    @State private var amount: Double?
    let code: String
    init(_ code: String) { self.code = code }
    var body: some View { KitoCurrencyField("Amount", value: $amount, currencyCode: code) }
}

private struct DateSample: View {
    @State private var date: Date?
    let configure: (KitoDateField) -> KitoDateField
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            configure(KitoDateField("Date", date: $date))
            Text(date.map { $0.formatted(date: .long, time: .omitted) } ?? "nil").font(.footnote.monospaced()).foregroundColor(.secondary)
        }
    }
}

private struct SelectSample: View {
    @State private var option: KitoSelectOption?
    let menu: Bool
    var body: some View {
        if menu {
            KitoSelectField("Size", selection: $option, options: ["XS", "S", "M", "L", "XL", "XXL"].map { KitoSelectOption($0) }).menu()
        } else {
            KitoSelectField("Delivery speed", selection: $option, options: [
                KitoSelectOption("Standard", subtitle: "3–5 days · free", systemImage: "tortoise"),
                KitoSelectOption("Express", subtitle: "Tomorrow · KES 300", systemImage: "hare"),
                KitoSelectOption("Same day", subtitle: "Within 4 hours · KES 600", systemImage: "bolt"),
                KitoSelectOption("Pickup", subtitle: "Westlands store", systemImage: "bag"),
            ]).required()
        }
    }
}

private struct SearchSample: View {
    @State private var query = ""
    @State private var results: [String] = []
    private let items = ["Trail runners", "Rain jacket", "Camp stove", "Headlamp", "Water bottle", "Trekking poles", "Tent", "Sleeping bag"]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            KitoSearchField(text: $query).onSearch { term in results = term.isEmpty ? [] : items.filter { $0.localizedCaseInsensitiveContains(term) } }
            ForEach(results, id: \.self) { Text($0).font(.footnote) }
        }
    }
}

private struct CodeSample: View {
    @State private var code = ""
    @State private var wrong = false
    var body: some View {
        KitoCodeField(code: $code, length: 4)
            .secure()
            .errorMessage(wrong ? "Incorrect code (try 1234)" : nil)
            .clearsOnError()   // shakes, then clears the boxes for you — no DispatchQueue needed
            .onChange(of: code) { value in
                guard value.count == 4 else { wrong = false; return }
                wrong = value != "1234"
            }
    }
}

private struct CodeWithResendSample: View {
    @State private var code = ""
    @State private var sentCount = 1
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            KitoCodeField(code: $code, length: 4)
            KitoResendCodeButton(cooldown: 8) { sentCount += 1 }
            Text("Sent \(sentCount) time\(sentCount == 1 ? "" : "s") · cooldown shortened to 8s for this demo")
                .font(.caption2).foregroundColor(.secondary)
        }
    }
}

private struct CodeStateStylingSample: View {
    @State private var code = ""
    @State private var wrong = false
    var body: some View {
        KitoCodeField(code: $code, length: 4)
            .filledBox(fill: .white)
            .activeBox(borderColor: .accentColor, borderWidth: 2)
            .errorBox(fill: .red.opacity(0.06), borderColor: .red)
            .digitColor(filled: .primary, active: .accentColor)
            .errorMessage(wrong ? "Incorrect code (try 1234)" : nil)
            .clearsOnError()
            .onChange(of: code) { value in
                guard value.count == 4 else { wrong = false; return }
                wrong = value != "1234"
            }
    }
}

private struct CodeSuccessSample: View {
    @State private var code = ""
    @State private var verified = false
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            KitoCodeField(code: $code, length: 4)
                .showsSuccess($verified)
                .successAnimation(.tick)
                .haptics(onDigit: true, onComplete: true)
                .onChange(of: code) { verified = $0 == "1234" }
            Text("Enter 1234 to see the success state.")
                .font(.caption2).foregroundColor(.secondary)
        }
    }
}

private struct CodeBuiltInResendSample: View {
    @State private var code = ""
    @State private var sentCount = 1
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            KitoCodeField(code: $code, length: 4)
                .resendButton(after: 8) { sentCount += 1 }
            Text("Sent \(sentCount) time\(sentCount == 1 ? "" : "s") · cooldown shortened to 8s for this demo")
                .font(.caption2).foregroundColor(.secondary)
        }
    }
}

private struct StyleSample: View {
    @State private var name = "Wycliff Njenga"
    @State private var email = ""
    let style: (AnyView) -> AnyView
    var body: some View {
        style(AnyView(VStack(spacing: 14) {
            KitoTextField("Name", text: $name, prompt: "Jane Doe").leadingIcon("person", focused: "person.fill")
            KitoEmailField(text: $email).required()
        }))
    }
}
