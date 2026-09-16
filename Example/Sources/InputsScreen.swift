//
//  InputsScreen.swift
//  KitoFieldsExample
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI
import KitoFields

struct InputsScreen: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Sign-up form") { SignUpFormDemo() }
                NavigationLink("Text field options") { TextFieldOptionsDemo() }
                NavigationLink("Phone number") { PhoneDemo() }
                NavigationLink("Country & currency") { CountryDemo() }
                NavigationLink("Password & strength") { PasswordDemo() }
                NavigationLink("One-time code") { OTPDemo() }
                NavigationLink("Style gallery") { StyleGalleryDemo() }
                NavigationLink("Animations") { AnimationsDemo() }
            }
            .navigationTitle("KitoFields")
        }
    }
}

// MARK: - Sign-up form

struct SignUpFormDemo: View {
    @EnvironmentObject private var appearance: AppearanceModel
    @State private var name = ""
    @State private var email = ""
    @State private var phone: KitoPhoneNumber?
    @State private var password = ""
    @State private var confirm = ""
    @State private var nameValid = false
    @State private var emailValid = false
    @State private var phoneValid = false
    @State private var passwordValid = false
    @State private var confirmValid = false
    @State private var serverError: String?
    @State private var submitted = false
    @State private var isSubmitting = false

    private var formIsValid: Bool { nameValid && emailValid && phoneValid && passwordValid && confirmValid }

    var body: some View {
        ScrollView {
            Themed {
                VStack(spacing: 18) {
                    KitoTextField("Full name", text: $name, prompt: "Jane Doe")
                        .leadingIcon("person")
                        .required()
                        .contentType(.name)
                        .autocapitalization(.words)
                        .validation(.minLength(2))
                        .isValid($nameValid)

                    KitoEmailField(text: $email)
                        .leadingIcon("envelope")
                        .required()
                        .errorMessage(serverError)
                        .validationIndicators()
                        .isValid($emailValid)

                    KitoPhoneField("Mobile number", phoneNumber: $phone)
                        .required()
                        .countries(preferred: ["KE", "UG", "TZ", "US", "GB"])
                        .countryPicker { $0.locale = appearance.locale }
                        .helperText("We'll text you a verification code")
                        .validationIndicators()
                        .isValid($phoneValid)

                    KitoPasswordField(text: $password)
                        .newPassword()
                        .required()
                        .strengthMeter()
                        .requirements(KitoRule.strongPassword())
                        .isValid($passwordValid)

                    KitoPasswordField("Confirm password", text: $confirm, prompt: "Re-enter your password")
                        .required()
                        .mustMatch($password)
                        .validationTrigger(.live)
                        .isValid($confirmValid)

                    Button {
                        Task {
                            isSubmitting = true
                            try? await Task.sleep(nanoseconds: 1_200_000_000)
                            serverError = email.hasSuffix("@taken.com") ? "That email is already registered" : nil
                            submitted = serverError == nil
                            isSubmitting = false
                        }
                    } label: {
                        Group {
                            if isSubmitting { ProgressView().tint(.white) } else { Text("Create account").bold() }
                        }
                        .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!formIsValid || isSubmitting)

                    if submitted {
                        Label("Account created for \(phone?.international ?? "")", systemImage: "checkmark.seal.fill")
                            .foregroundColor(.green)
                    }
                    Text("Tip: use an @taken.com address to see a server-side error.")
                        .font(.footnote).foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .navigationTitle("Sign up")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Text field options

struct TextFieldOptionsDemo: View {
    @State private var basic = ""
    @State private var noTitle = ""
    @State private var limited = ""
    @State private var bio = ""
    @State private var amount = ""
    @State private var username = ""
    @State private var disabled = "Read only value"

    var body: some View {
        ScrollView {
            Themed {
                VStack(spacing: 18) {
                    KitoTextField("With title", text: $basic, prompt: "Placeholder text")
                    KitoTextField(text: $noTitle)
                        .placeholder("No title, just a placeholder")
                        .leadingIcon("magnifyingglass")
                        .clearButton()
                    KitoTextField("Optional field", text: $limited, prompt: "Up to 20 characters")
                        .characterLimit(20, showsCounter: true)
                        .helperText("Shown with the theme's optional indicator when enabled")
                    KitoTextField("Bio", text: $bio, prompt: "Tell us about yourself")
                        .multiline(3...6)
                        .characterLimit(160, showsCounter: true)
                    KitoTextField("Amount", text: $amount, prompt: "0.00")
                        .leadingAccessory(.text("KES"))
                        .trailingAccessory(.systemImage("banknote"))
                        .keyboard(.decimalPad)
                        .validation(.decimal(), trigger: .live)
                    KitoTextField("Username", text: $username, prompt: "lowercase, no spaces")
                        .leadingAccessory(.text("@"))
                        .transform { $0.lowercased().filter { !$0.isWhitespace } }
                        .required(message: "Pick a username")
                        .validation(.minLength(3), .alphanumeric(), trigger: .live)
                        .validationIndicators()
                    KitoTextField("Disabled", text: $disabled)
                        .disabled(true)
                }
                .padding()
            }
            .kitoFieldTheme { $0.optionalIndicator = "(optional)" }
        }
        .navigationTitle("Text fields")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Phone

struct PhoneDemo: View {
    @State private var phone: KitoPhoneNumber?
    @State private var e164 = "+254712123456"
    @State private var kenyaOnly = ""
    @State private var state: KitoPhoneState = .empty

    var body: some View {
        ScrollView {
            Themed {
                VStack(alignment: .leading, spacing: 18) {
                    KitoPhoneField("Default (United States)", phoneNumber: $phone)
                        .validationIndicators()
                        .onPhoneValidationChange { state = $0 }
                    Group {
                        Text("E.164: ").bold() + Text(phone?.e164 ?? "—")
                        Text("International: ").bold() + Text(phone?.international ?? "—")
                        Text("National: ").bold() + Text(phone?.formatted(.nationalWithTrunkPrefix) ?? "—")
                        Text("State: ").bold() + Text(String(describing: state))
                    }
                    .font(.footnote.monospaced())

                    KitoPhoneField("Bound to an E.164 string", e164: $e164)
                        .clearButton()

                    KitoPhoneField("Device region", phoneNumber: .constant(nil))
                        .defaultCountry(.deviceRegion)
                    Text(e164.isEmpty ? "(empty)" : e164).font(.footnote.monospaced())

                    KitoPhoneField("Locked to Kenya", country: .constant(KitoCountryDatabase.country(isoCode: "KE")!), nationalNumber: $kenyaOnly)
                        .countrySelection(.locked)
                        .showsChevron(false)

                    KitoPhoneField("Menu picker, East Africa only", phoneNumber: .constant(nil))
                        .countries(allowed: ["KE", "UG", "TZ", "RW", "ET"], preferred: ["KE"])
                        .countrySelection(.menu)
                        .flagStyle(.isoCode)

                    Text("Try pasting +44 7400 123456 or typing 00 1 416 555 0123 into any field: the region switches automatically.")
                        .font(.footnote).foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .navigationTitle("Phone number")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Password

struct PasswordDemo: View {
    @State private var password = ""
    @State private var simple = ""
    @State private var revealed = false

    var body: some View {
        ScrollView {
            Themed {
                VStack(spacing: 18) {
                    KitoPasswordField("New password", text: $password, prompt: "At least 8 characters")
                        .newPassword()
                        .strengthMeter()
                        .requirements(KitoRule.strongPassword())
                        .revealed($revealed)
                    KitoPasswordField("Same reveal state", text: $simple)
                        .revealed($revealed)
                    Toggle("Reveal both", isOn: $revealed)
                    KitoPasswordField("No reveal button", text: $simple)
                        .revealable(false)
                        .leadingIcon("lock")
                }
                .padding()
            }
        }
        .navigationTitle("Password")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - OTP

struct OTPDemo: View {
    @State private var code = ""
    @State private var error: String?
    @State private var verified = false

    var body: some View {
        Themed {
            VStack(spacing: 24) {
                Text("Enter the 6-digit code we sent you").font(.headline)
                KitoCodeField(code: $code, length: 6)
                    .errorMessage(error)
                    .onComplete { value in
                        verified = value == "123456"
                        error = verified ? nil : "Incorrect code, try 123456"
                    }
                if verified {
                    Label("Verified", systemImage: "checkmark.seal.fill").foregroundColor(.green)
                }
                Button("Resend code") { code = ""; error = nil; verified = false }
                Spacer()
            }
            .padding()
        }
        .navigationTitle("One-time code")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Style gallery

struct StyleGalleryDemo: View {
    @State private var values = Array(repeating: "", count: 5)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                gallery("Outlined · rounded") { $0.kitoFieldStyle(.outlined) }
                gallery("Filled · capsule") { $0.kitoFieldStyle(.filled).kitoFieldShape(.capsule) }
                gallery("Outlined · rectangle · thick") { $0.kitoFieldStyle(.outlined).kitoFieldTheme(.sharp) }
                gallery("Underlined (one line)") { $0.kitoFieldStyle(.underlined) }
                gallery("Floating label · soft shadow") { $0.kitoFieldStyle(.floatingLabel).kitoFieldTheme(.soft) }
                gallery("Plain (no chrome)") { $0.kitoFieldStyle(.plain) }
                gallery("Custom brand theme") {
                    $0.kitoFieldStyle(.filled).kitoFieldTheme { theme in
                        theme.shape = .roundedRectangle(cornerRadius: 6)
                        theme.filledBackgroundColor = Color.indigo.opacity(0.08)
                        theme.focusedBorderColor = .indigo
                        theme.textColor = .indigo
                        theme.labelColor = .indigo
                        theme.font = .system(.body, design: .rounded)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Style gallery")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func gallery<Modified: View>(_ title: String, _ modify: @escaping (AnyView) -> Modified) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.subheadline.weight(.semibold)).foregroundColor(.secondary)
            modify(AnyView(
                VStack(spacing: 14) {
                    KitoTextField("Name", text: $values[0], prompt: "Jane Doe").leadingIcon("person").required()
                    KitoEmailField(text: $values[1]).errorMessage("Inline error looks like this")
                    KitoPasswordField(text: $values[2])
                    KitoPhoneField("Phone", e164: $values[3])
                }
            ))
        }
    }
}


// MARK: - Country

struct CountryDemo: View {
    @State private var country: KitoCountry? = KitoCountryDatabase.country(isoCode: "KE")
    @State private var iso = ""
    @State private var picked: KitoCountry?

    var body: some View {
        ScrollView {
            Themed {
                VStack(alignment: .leading, spacing: 18) {
                    KitoCountryField("Country", selection: $country)
                        .shows(flag: true, name: true, dialCode: true, currency: true)
                        .flagStyle(.circle)
                        .required()
                        .countries(preferred: ["KE", "UG", "TZ", "US", "GB"])
                        .onCountryChange { picked = $0 }

                    if let c = country {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Callback data").font(.subheadline.weight(.semibold))
                            Group {
                                Text("Flag: \(c.flag)   ISO: \(c.isoCode)   Dial: \(c.formattedDialCode)")
                                Text("Name: \(c.localizedName) (\(c.englishName))")
                                Text("Currency: \(c.currencyCode ?? "—") \(c.currencySymbol ?? "") · \(c.localizedCurrencyName ?? "")")
                                Text("Amount: \(c.formatCurrency(1250) ?? "—")")
                            }
                            .font(.footnote.monospaced())
                        }
                    }

                    Text("Flag styles").font(.subheadline.weight(.semibold)).foregroundColor(.secondary)
                    KitoCountryField("Emoji", selection: $country).flagStyle(.emoji).showsChevron(false)
                    KitoCountryField("Circle", selection: $country).flagStyle(.circle).showsChevron(false)
                    KitoCountryField("Rounded", selection: $country).flagStyle(.rounded).showsChevron(false)
                    KitoCountryField("Tile", selection: $country).flagStyle(.tile).showsChevron(false)
                    KitoCountryField("ISO badge", selection: $country).flagStyle(.isoCode).showsChevron(false)
                    KitoCountryField("No flag, name only", selection: $country).shows(flag: false, name: true).showsChevron(false)

                    Text("ISO code binding").font(.subheadline.weight(.semibold)).foregroundColor(.secondary)
                    KitoCountryField("Ship to", isoCode: $iso)
                        .placeholder("Choose a destination")
                        .clearButton()
                        .countryPicker { $0.showsCurrency = true }
                    Text("iso = \"\(iso)\"").font(.footnote.monospaced())
                }
                .padding()
            }
        }
        .navigationTitle("Country & currency")
        .navigationBarTitleDisplayMode(.inline)
    }
}
