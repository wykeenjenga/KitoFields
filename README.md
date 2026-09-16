# KitoFields

Professional, fully customisable SwiftUI form inputs: text, email, password, phone number with country picker, and one-time code. One style and theme system drives every field, so a whole app can switch from rounded outlines to capsules or a single underline with one modifier.

- iOS 15+ / macOS 12+, pure SwiftUI, no dependencies
- Author: **Wycliff Njenga**
- Licence: MIT

<p align="center">
  <img src="Assets/signup-empty.png" width="200" alt="Sign-up form with required indicators" />
  <img src="Assets/signup-filled.png" width="200" alt="Sign-up form with validation, strength meter and inline errors" />
  <img src="Assets/phone.png" width="200" alt="Phone number field with country picker and E.164 output" />
  <img src="Assets/style-gallery.png" width="200" alt="Outlined, filled, underlined, floating label and plain styles" />
</p>

<p align="center">
  <img src="Assets/animations.gif" width="260" alt="Shake on error, focus lift, animated ticks and flags" />
  <img src="Assets/style-gallery-2.png" width="200" alt="Underlined and floating label styles" />
  <img src="Assets/animations.png" width="200" alt="Inline errors, live validation, one-time code" />
</p>

## Installation

### Swift Package Manager (recommended)

**In Xcode**

1. File ▸ Add Package Dependencies…
2. Paste `https://github.com/wykeenjenga/KitoFields.git`
3. Dependency rule: *Up to Next Major Version* from `1.1.1`
4. Add the `KitoFields` product to your app target

**In `Package.swift`**

```swift
dependencies: [
    .package(url: "https://github.com/wykeenjenga/KitoFields.git", from: "1.1.1")
],
targets: [
    .target(name: "MyApp", dependencies: ["KitoFields"])
]
```

### CocoaPods

```ruby
pod 'KitoFields', '~> 1.1'
```

Then `pod install` and open the `.xcworkspace`.

### Import

```swift
import KitoFields
```

### Requirements

| | Minimum |
| --- | --- |
| iOS | 15.0 |
| macOS | 12.0 |
| Swift | 5.9 |
| Xcode | 15 |

Pair it with [KitoButtons](https://github.com/wykeenjenga/KitoButtons) for matching capsule buttons and add-to-cart animations.

## Fields at a glance

| Field | What you get |
| --- | --- |
| `KitoTextField` | General text input: title or no title, placeholder, leading/trailing accessories, clear button, character limit + counter, multiline, transforms, validation |
| `KitoEmailField` | Email keyboard and autofill, whitespace stripped, `.email` rule on blur |
| `KitoPasswordField` | Secure entry, reveal toggle, strength meter, live requirement checklist, confirm-password matching via `.mustMatch($password)` |
| `KitoPhoneField` | Country selector (sheet / menu / locked), flags, as-you-type formatting, `+`/`00` paste detection, E.164 output, 220+ regions |
| `KitoCodeField` | OTP boxes backed by one hidden field so SMS autofill and paste work |

Every field conforms to `KitoFieldConfigurable`, so they share the same fluent modifiers.

## Quick start

```swift
import KitoFields

struct SignUp: View {
    @State private var name = ""
    @State private var email = ""
    @State private var phone: KitoPhoneNumber?
    @State private var password = ""
    @State private var formValid = false

    var body: some View {
        VStack(spacing: 18) {
            KitoTextField("Full name", text: $name, prompt: "Jane Doe")
                .leadingIcon("person")
                .required()
                .validation(.minLength(2))

            KitoEmailField(text: $email)
                .required()
                .validationIndicators()

            KitoPhoneField("Mobile number", phoneNumber: $phone)
                .required()
                .countries(preferred: ["KE", "UG", "TZ"])
                .helperText("We'll text you a verification code")

            KitoPasswordField(text: $password)
                .newPassword()
                .strengthMeter()
                .requirements(KitoRule.strongPassword())
        }
        .kitoFieldStyle(.outlined)
        .kitoFieldShape(.capsule)
    }
}
```

## Shared modifiers (all fields)

```swift
.label("Title")                 // or omit for no title
.placeholder("Hint")
.helperText("Neutral hint under the field")
.errorMessage(serverError)      // inline error you control (e.g. from an API)
.required()                     // adds "*" to the label and a required rule
.required(false)                // shows the theme's optional indicator if set
.leadingIcon("envelope")        // or .leadingAccessory(.text("KES")) / .custom { AnyView }
.trailingAccessory(.button(systemImage: "info.circle", accessibilityLabel: "Info") { ... })
.clearButton()
.characterLimit(120, showsCounter: true)
.validation(.minLength(3), .alphanumeric(), trigger: .live)   // .live / .onBlur / .onSubmit / .never
.validationIndicators()         // ✓ / ! trailing icons
.keyboard(.decimalPad).contentType(.username).autocapitalization(.never).autocorrectionDisabled()
.multiline(3...6)
.transform { $0.lowercased() }
.focused($isNameFocused)        // Binding<Bool>
.isValid($nameIsValid)          // continuously written, handy for enabling a submit button
.onValidationChange { state in } .onSubmit { } .onFocusChange { focused in }
```

### Validation rules

`KitoRule` presets: `.required`, `.email`, `.url()`, `.minLength(n)`, `.maxLength(n)`, `.exactLength(n)`, `.numeric()`, `.decimal()`, `.alphanumeric()`, `.containsUppercase()`, `.containsLowercase()`, `.containsDigit()`, `.containsSymbol()`, `.noWhitespace()`, `.regex(pattern, message:)`, `.matches({ other }, message:)`, `.custom(message:) { value in Bool }`, and the bundle `KitoRule.strongPassword()`.

Rules other than `.required` pass on empty input, so optional fields stay quiet until the user types.

## Styles and shapes

```swift
.kitoFieldStyle(.outlined)       // default: border, transparent background
.kitoFieldStyle(.filled)         // solid fill, border only on focus/error
.kitoFieldStyle(.underlined)     // one line under the text
.kitoFieldStyle(.floatingLabel)  // label floats from placeholder position to the top
.kitoFieldStyle(.plain)          // no chrome

.kitoFieldShape(.capsule)        // .rectangle, .roundedRectangle(cornerRadius:), .capsule, .underline
```

### Theme tokens

```swift
.kitoFieldTheme { theme in
    theme.shape = .roundedRectangle(cornerRadius: 8)
    theme.showsBorder = false
    theme.filledBackgroundColor = .indigo.opacity(0.08)
    theme.focusedBorderColor = .indigo
    theme.errorColor = .pink
    theme.font = .system(.body, design: .rounded)
    theme.requiredIndicator = "*"          // nil to hide
    theme.optionalIndicator = "(optional)" // nil to hide
    theme.errorDisplay = .all              // .first / .all / .none
    theme.shadow = KitoShadow()
}
```

Presets: `KitoFieldTheme.default`, `.soft`, `.capsule`, `.sharp`, `.underline`.

### Custom style

Implement `KitoFieldStyle` to control layout completely. The configuration hands you the label, placeholder, input, accessories, footer, error messages and state; reuse `KitoFieldRow`, `KitoFieldStack`, `KitoFieldMessages` and `.kitoFieldChrome(...)` or draw everything yourself.

```swift
struct CardFieldStyle: KitoFieldStyle {
    func makeBody(configuration c: Configuration) -> some View {
        KitoFieldStack(c) {
            KitoFieldRow(c)
                .kitoFieldChrome(c, fill: .white, borderWidth: c.isFocused ? 2 : 0)
        }
    }
}
```

## Motion

Every field animates focus, errors, success ticks, floating labels and flag swaps through
`KitoFieldTheme.motion` (`KitoFieldMotion`):

```swift
.kitoFieldTheme { $0.motion = .lively }        // spring focus, 2% lift, glow; .subtle disables the shake
.kitoFieldTheme { $0.motion.shakesOnError = false; $0.motion.focusScale = 1.03 }
```

- Fields shake horizontally the moment an error first appears (`shakesOnError`).
- `focusScale` and `focusedShadow` lift the focused field.
- Floating labels spring into place (`motion.label`); ticks, clear buttons, counters and flags pop (`motion.pop`).
- `KitoPhoneField` animates the flag and dial code when the country changes.
- `KitoCodeField` shakes when you set an error message.
- Shake any view yourself with `.kitoFieldShake(trigger:)`.

## Localization

Every built-in string (rule messages, picker titles, password strength labels, accessibility labels)
is localized. English, Swahili (`sw`) and French (`fr`) ship in the package; country names come from
the system for every language. To override or add languages, supply a provider once at launch:

```swift
KitoLocalization.provider = { key, english in
    NSLocalizedString("kito.\(key)", value: english, comment: "")   // return nil to keep the bundled copy
}
```

Per-field messages still win: `.required(message:)`, `.validation(.minLength(8, message: "…"))`,
`.phoneErrorMessages { … }` and `.countryPicker { $0.strings.title = "…" }`.

## Phone numbers

```swift
KitoPhoneField(phoneNumber: $phone)               // Binding<KitoPhoneNumber?>
KitoPhoneField(e164: $e164String)                 // "+254712123456" or ""
KitoPhoneField(country: $country, nationalNumber: $digits)

    .countries(allowed: ["KE", "UG"], excluded: [], preferred: ["KE"])
    .defaultCountry("KE")
    .countrySelection(.sheet)      // .menu / .locked
    .flagStyle(.emoji)             // .isoCode / .hidden
    .showsDialCode(true).showsChevron(true).showsDivider(true)
    .formatsAsYouType(true).limitsToMaxLength(true).detectsInternationalInput(true)
    .countryPicker { $0.strings.title = "Choose a country" }
    .phoneValidator(KitoPhoneValidator { number in number.nationalNumber.hasPrefix("7") ? nil : .custom("Mobile numbers only") })
    .phoneErrorMessages { error in localized(error) }
    .onPhoneNumberChange { number in } .onCountryChange { country in }
```

`KitoPhoneNumber` gives you `e164`, `international`, `national`, `formatted(.nationalWithTrunkPrefix)`, `rfc3966`, `url`, `isValid`, and is `Codable` as `{ isoCode, nationalNumber }`. Parse anything with `KitoPhoneNumber(parsing: "+44 7400 123456")` or `KitoPhoneNumber(e164:)`.

`KitoCountryDatabase` exposes all regions with flags, localized names, dial codes, formats and example numbers. Shared dial codes (+1, +7, +44, +61, …) are resolved by area or leading digits.

## One-time code

```swift
KitoCodeField(code: $code, length: 6)
    .secure()
    .errorMessage(wrongCode ? "Incorrect code" : nil)
    .onComplete { code in verify(code) }
```

## Example app

`Example/KitoFieldsExample.xcodeproj` (in this repository) demonstrates every field, style, shape, theme and motion preset: sign-up form, text field options, phone, password, one-time code, style gallery and an animations screen. Regenerate the project with `xcodegen generate` after editing `Example/project.yml`.
