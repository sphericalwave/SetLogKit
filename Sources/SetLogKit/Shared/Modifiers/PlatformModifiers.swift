//
//  PlatformModifiers.swift
//  SetLogKit
//
//  Cosmetic cross-platform shims so shared view bodies stay free of
//  `#if os(...)`. Anything with a real layout difference gets its own view
//  file per platform instead.
//

import SwiftUI

extension View {
    /// Decimal keypad on iOS; a no-op on macOS, which has a hardware keyboard.
    @ViewBuilder
    func decimalKeyboard() -> some View {
        #if os(iOS)
        self.keyboardType(.decimalPad)
        #else
        self
        #endif
    }

    /// `.navigationBarTitleDisplayMode(.inline)` on iOS; a no-op elsewhere.
    @ViewBuilder
    func inlineNavTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}
