//
//  WeightProgression.swift
//  SetLogKit
//
//  Turns a categorical ProgressionDecision into a numeric weight suggestion,
//  for equipment (dumbbells, plates) that only moves in fixed increments
//  rather than continuously. The step size is caller-supplied — increments
//  vary a lot in practice (adjustable dumbbells can move in small
//  micro-plate steps, fixed pairs often jump by more), so there's no
//  built-in "standard" step list to guess at.
//

import Foundation

public enum WeightProgression {
    /// The next suggested weight given the last logged weight and a
    /// progression decision. `stepLbs` nil or 0 means continuous (no
    /// auto-adjustment) — `last` is returned unchanged for `.progress`/
    /// `.regress` too, since there's no step size to apply.
    public static func nextWeight(last: Double, decision: ProgressionDecision, stepLbs: Double?) -> Double {
        guard let stepLbs, stepLbs != 0 else { return last }
        switch decision {
        case .progress: return last + stepLbs
        case .regress: return max(0, last - stepLbs)
        case .repeat: return last
        }
    }
}
