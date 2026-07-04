//
//  ProgressionEvaluator.swift
//  SetLogKit
//
//  Intuitive Training Protocol — suggests progress / repeat / regress
//  from the last 3 logged sets for a given skill.
//
//  Rule (from manual):
//    Sustained RPT ≥ 8, RPD ≤ 3, RPE ≥ 6 across 3 sessions → progress.
//    High RPD or low RPT → regress. Otherwise repeat at the same level.
//

import Foundation

public struct ProgressionEvaluator: Sendable {
    public static let progressWindow = 3
    public static let rptMin = 8
    public static let rpdMax = 3
    public static let rpeMin = 6
    public static let regressRpdMin = 7
    public static let regressRptMax = 4

    public init() {}

    public nonisolated func suggest(from recent: [RatedSet]) -> ProgressionDecision {
        let last3 = Array(recent.suffix(Self.progressWindow))
        guard last3.count == Self.progressWindow else { return .repeat }

        let meets = last3.allSatisfy {
            $0.rpt >= Self.rptMin && $0.rpd <= Self.rpdMax && $0.rpe >= Self.rpeMin
        }
        if meets { return .progress }

        let regressSignal = last3.contains {
            $0.rpd >= Self.regressRpdMin || $0.rpt <= Self.regressRptMax
        }
        if regressSignal { return .regress }

        return .repeat
    }
}
