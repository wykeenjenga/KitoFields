# Contributing to KitoFields

Thanks for your interest. KitoFields is open source and contributions of every size are welcome: bug reports, ideas, documentation, translations, new samples and code.

## How it works

1. **Open an issue first** for anything beyond a typo fix. Use the bug or feature template so we have the details (iOS version, Xcode version, steps to reproduce, or the use case). This avoids duplicate work and lets us agree on the approach.
2. **Fork the repository and create a branch** from `main`, named for the change (`fix/phone-caret`, `feat/date-field`, `docs/swahili`).
3. **Make the change with tests.** Run `swift test` and build the example app in `Example/` for the iOS Simulator. New UI needs a screenshot or GIF in the PR; new strings need entries in every `Localizable.strings`.
4. **Open a pull request** that references the issue. Describe what changed and why, and how you verified it. CI runs the package tests, the iOS example build and the podspec lint.
5. **Review.** A maintainer reviews the PR. Once approved it is merged into `main` and shipped in the next release (SwiftPM tag, GitHub release and CocoaPods push).

## Ground rules

- Follow the existing code style: fluent modifiers on the public types, themes and motion presets rather than hard-coded values, everything documented with `///`.
- Keep public API changes backwards compatible within a major version. Deprecate before removing.
- Every user-facing string goes through the localization layer.
- Be kind and constructive in issues and reviews.

## Reporting a security issue

Please email wycliffnjenga19@gmail.com instead of opening a public issue.
