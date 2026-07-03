//
//  ProgressionDecision.swift
//  SetLogKit
//

import SwiftUI

public enum ProgressionDecision: String, CaseIterable, Sendable {
    case regress
    case `repeat` // swift keyword
    case progress

    public var color: Color {
        switch self {
        case .progress: return .green
        case .repeat:   return .orange
        case .regress:  return .red
        }
    }

    public var label: String { rawValue.capitalized }
}

public struct RatedSet: Equatable, Sendable {
    public let rpt: Int        // technique 1–10
    public let rpe: Int        // exertion 1–10
    public let rpd: Int        // discomfort 1–10
    public let loggedAt: Date

    public init(rpt: Int, rpe: Int, rpd: Int, loggedAt: Date) {
        self.rpt = rpt
        self.rpe = rpe
        self.rpd = rpd
        self.loggedAt = loggedAt
    }
}
