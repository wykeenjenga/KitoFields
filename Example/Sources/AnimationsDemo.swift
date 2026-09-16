//
//  AnimationsDemo.swift
//  KitoFieldsExample
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import SwiftUI
import KitoFields

/// Shake on error, focus lift, floating label spring, animated flag swap, success pop.
struct AnimationsDemo: View {
    @State private var username = ""
    @State private var email = ""
    @State private var phone: KitoPhoneNumber?
    @State private var code = ""
    @State private var codeError: String?
    @State private var failedSubmits = 0
    @State private var note = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Errors shake the field the moment they appear. Type a short name and tap elsewhere.")
                    .font(.footnote).foregroundColor(.secondary)
                Themed {
                    VStack(spacing: 18) {
                        KitoTextField("Username", text: $username, prompt: "at least 4 characters")
                            .leadingIcon("person")
                            .required()
                            .validation(.minLength(4), .noWhitespace(), trigger: .onBlur)
                            .validationIndicators()

                        KitoEmailField(text: $email)
                            .validationTrigger(.live)
                            .validationIndicators()
                            .helperText("Live validation: the tick pops in when the address becomes valid")

                        KitoPhoneField("Phone", phoneNumber: $phone)
                            .countries(preferred: ["KE", "GB", "US", "JP", "BR"])
                            .helperText("Change country: the flag and dial code animate in")

                        KitoTextField("Note", text: $note, prompt: "Counter pulses at the limit")
                            .characterLimit(24, showsCounter: true)
                    }
                }
                .kitoFieldStyle(.floatingLabel)
                .kitoFieldTheme { $0.motion = .lively }

                Divider()

                Text("One-time code shakes on a wrong code").font(.footnote).foregroundColor(.secondary)
                KitoCodeField(code: $code, length: 4)
                    .errorMessage(codeError)
                    .onComplete { value in
                        codeError = value == "1234" ? nil : "Wrong code (try 1234)"
                        if value != "1234" { DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { code = "" } }
                    }

                Divider()

                Text("Shake anything with .kitoFieldShake(trigger:)").font(.footnote).foregroundColor(.secondary)
                Button("Submit (fails)") { failedSubmits += 1 }
                    .buttonStyle(.borderedProminent)
                    .kitoFieldShake(trigger: failedSubmits)

                Text("Motion presets: default · lively (lift + glow) · subtle (no shake). Switch them in the Appearance tab.")
                    .font(.footnote).foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("Animations")
        .navigationBarTitleDisplayMode(.inline)
    }
}
