//
//  HRConfig.swift
//  SetLogKit
//
//  User max-heart-rate setting, persisted via `@AppStorage`. Default is the
//  `220 − age` estimate; a non-zero manual override replaces it. Used to show
//  each set's heart rate as a percentage of max. (Was each app's `HRSettings`.)
//

import Foundation

public enum HRConfig {
    public static let ageKey = "userAge"
    public static let overrideKey = "hrMaxOverride"

    /// `manualOverride == 0` means "no override — use the 220 − age estimate".
    public static func effectiveMax(age: Int, manualOverride: Int) -> Int {
        manualOverride > 0 ? manualOverride : max(220 - age, 1)
    }
}

/// Per-set heart-rate summary shown at the top of the form.
public struct HRStats: Sendable, Equatable {
    public let min: Int
    public let max: Int
    public let avg: Int

    public init(min: Int, max: Int, avg: Int) {
        self.min = min
        self.max = max
        self.avg = avg
    }
}
