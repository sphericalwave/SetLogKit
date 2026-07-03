//
//  CompletionScorer.swift
//  SetLogKit
//
//  Two distinct scores, driven by a QUALITY fraction (0…1):
//    - technique-based (rings/kettlebell/gpp/clubs): clamp(rpt / rptTarget)
//    - ROM-based (progYog): clamp(rom / romMin)
//
//  SET SCORE (per-set, shown in SetLogSheet):
//      quality × 100 — depth-independent; full quality at any level = 100%.
//
//  WORKOUT SCORE (per-session/family, shown in lists and summaries):
//      (depth × quality) / maxDepth × 100
//      Banked depth levels are scaled by this session's quality, not assumed
//      perfect. 100% requires the highest-depth skill AND full quality.
//      Callers use the LAST set logged for that family in the session.
//
//  RPE / RPD remain advisory (logged, shown in history) but don't affect
//  either score.
//
//  Session/family aggregation stays in the host app (it walks the app's own
//  model graph); apps extend this enum with `familyPercent`/`sessionPercent`
//  built on `workoutScore`.
//

import Foundation

/// Thresholds backing the % completed metric. Editable in Settings.
/// Reads from `UserDefaults.standard`; falls back to the defaults below
/// when the key is absent or zero (the initial @AppStorage value).
public enum CompletionSettings {
    public static let rptMinKey = "completion.rptMin"
    public static let rpeMaxKey = "completion.rpeMax"
    public static let rpdMaxKey = "completion.rpdMax"
    public static let romMinKey = "completion.romMin"

    public static let defaultRptMin = 8
    public static let defaultRpeMax = 6
    public static let defaultRpdMax = 1
    public static let defaultRomMin = 95

    private static func read(_ key: String, fallback: Int) -> Int {
        let stored = UserDefaults.standard.integer(forKey: key)
        return stored == 0 ? fallback : stored
    }

    public static var rptMin: Int { read(rptMinKey, fallback: defaultRptMin) }
    public static var rpeMax: Int { read(rpeMaxKey, fallback: defaultRpeMax) }
    public static var rpdMax: Int { read(rpdMaxKey, fallback: defaultRpdMax) }
    public static var romMin: Int { read(romMinKey, fallback: defaultRomMin) }

    public static func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: rptMinKey)
        UserDefaults.standard.removeObject(forKey: rpeMaxKey)
        UserDefaults.standard.removeObject(forKey: rpdMaxKey)
        UserDefaults.standard.removeObject(forKey: romMinKey)
    }
}

public enum CompletionScorer {

    // MARK: - Quality fractions

    /// clamp(rpt / rptTarget, 0...1) — the technique-quality fraction.
    public static func techniqueFraction(rpt: Int) -> Double {
        let target = Double(CompletionSettings.rptMin > 0
                            ? CompletionSettings.rptMin
                            : CompletionSettings.defaultRptMin)
        return min(1.0, max(0.0, Double(rpt) / target))
    }

    /// clamp(rom / romMin, 0...1) — the range-of-motion fraction (progYog).
    public static func romFraction(rom: Int) -> Double {
        let target = Double(CompletionSettings.romMin > 0
                            ? CompletionSettings.romMin
                            : CompletionSettings.defaultRomMin)
        return min(1.0, max(0.0, Double(rom) / target))
    }

    // MARK: - Scores

    /// Depth-independent: full quality at any level = 100%.
    public static func setScore(quality: Double) -> Double {
        min(1.0, max(0.0, quality)) * 100
    }

    /// (depth × quality) / maxDepth × 100. 100% only at the highest
    /// skill level with full quality.
    public static func workoutScore(quality: Double, depth: Int, maxDepth: Int) -> Double? {
        guard maxDepth > 0 else { return nil }
        let achieved = Double(depth) * min(1.0, max(0.0, quality))
        return min(100, (achieved / Double(maxDepth)) * 100)
    }
}
