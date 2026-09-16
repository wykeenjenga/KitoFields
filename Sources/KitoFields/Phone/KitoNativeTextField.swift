//
//  KitoNativeTextField.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

#if os(iOS)
import SwiftUI
import UIKit

/// UIKit-backed text field used by `KitoPhoneField` on iOS. Formatting happens inside
/// `shouldChangeCharactersIn`, so the text is rewritten synchronously with the keystroke and no
/// character can be lost however fast the user (or a hardware keyboard) types.
struct KitoNativeTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    var keyboard: UIKeyboardType = .phonePad
    var contentType: UITextContentType? = .telephoneNumber
    var textColor: Color
    var tint: Color
    var accessibilityLabel: String
    /// Receives the proposed text after an edit and returns what should be displayed.
    var onEdit: (String) -> String
    var onSubmit: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        field.borderStyle = .none
        field.backgroundColor = .clear
        field.font = .preferredFont(forTextStyle: .body)
        field.adjustsFontForContentSizeCategory = true
        field.keyboardType = keyboard
        field.textContentType = contentType
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.returnKeyType = .done
        field.setContentHuggingPriority(.defaultHigh, for: .vertical)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.parent = self
        if field.text != text { field.text = text }
        field.textColor = UIColor(textColor)
        field.tintColor = UIColor(tint)
        field.keyboardType = keyboard
        field.textContentType = contentType
        field.accessibilityLabel = accessibilityLabel
        if isFocused, !field.isFirstResponder, field.window != nil {
            DispatchQueue.main.async { field.becomeFirstResponder() }
        } else if !isFocused, field.isFirstResponder {
            DispatchQueue.main.async { field.resignFirstResponder() }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: KitoNativeTextField

        init(parent: KitoNativeTextField) { self.parent = parent }

        func textField(_ field: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let current = field.text ?? ""
            guard let swiftRange = Range(range, in: current) else { return false }
            let proposed = current.replacingCharacters(in: swiftRange, with: string)
            // Digits typed before the caret: used to restore a sensible caret after reformatting.
            let caretUTF16 = range.location + (string as NSString).length
            let digitsBeforeCaret = (proposed as NSString).substring(to: min(caretUTF16, (proposed as NSString).length))
                .filter { $0.isNumber }.count

            let formatted = parent.onEdit(proposed)
            field.text = formatted
            parent.text = formatted
            placeCaret(in: field, afterDigits: digitsBeforeCaret, deleting: string.isEmpty)
            return false
        }

        /// Handles edits that bypass the delegate (dictation, some autofill paths).
        @objc func editingChanged(_ field: UITextField) {
            let current = field.text ?? ""
            guard current != parent.text else { return }
            let formatted = parent.onEdit(current)
            if formatted != current { field.text = formatted }
            parent.text = formatted
        }

        func textFieldDidBeginEditing(_ field: UITextField) {
            if !parent.isFocused { parent.isFocused = true }
        }

        func textFieldDidEndEditing(_ field: UITextField) {
            if parent.isFocused { parent.isFocused = false }
        }

        func textFieldShouldReturn(_ field: UITextField) -> Bool {
            parent.onSubmit()
            field.resignFirstResponder()
            return true
        }

        private func placeCaret(in field: UITextField, afterDigits count: Int, deleting: Bool) {
            let text = field.text ?? ""
            var seen = 0
            var offset = text.count
            for (index, character) in text.enumerated() where character.isNumber {
                seen += 1
                if seen == count {
                    offset = index + 1
                    break
                }
            }
            if count == 0 { offset = deleting ? 0 : min(text.count, offset) }
            if count == 0 && !deleting { offset = text.count }
            // Skip trailing separators so typing continues naturally after e.g. "(201) ".
            if !deleting {
                while offset < text.count, !text[text.index(text.startIndex, offsetBy: offset)].isNumber { offset += 1 }
            }
            if let position = field.position(from: field.beginningOfDocument, offset: offset) {
                field.selectedTextRange = field.textRange(from: position, to: position)
            }
        }
    }
}
#endif
