//
//  TempoPreset.swift
//  SetLogKit
//
//  Predefined eccentric-pause-concentric-pause tempo schemes, tap-selected
//  from `TempoDetailView` instead of dialed in via four narrow steppers.
//

import Foundation

public struct TempoPreset: Identifiable, Sendable {
    public let label: String
    public let eccentric: Int
    public let bottomPause: Int
    public let concentric: Int
    public let topPause: Int
    public let description: String

    public init(label: String, eccentric: Int, bottomPause: Int, concentric: Int, topPause: Int, description: String) {
        self.label = label
        self.eccentric = eccentric
        self.bottomPause = bottomPause
        self.concentric = concentric
        self.topPause = topPause
        self.description = description
    }

    public var id: String { tempoString }
    public var tempoString: String { "\(eccentric)-\(bottomPause)-\(concentric)-\(topPause)" }

    public func matches(eccentric: Int, bottomPause: Int, concentric: Int, topPause: Int) -> Bool {
        self.eccentric == eccentric && self.bottomPause == bottomPause
            && self.concentric == concentric && self.topPause == topPause
    }

    public static let all: [TempoPreset] = [
        .init(label: "None", eccentric: 0, bottomPause: 0, concentric: 0, topPause: 0,
              description: "Not tracking tempo for this set."),
        .init(label: "Moderate", eccentric: 2, bottomPause: 0, concentric: 2, topPause: 0,
              description: "Steady lowering and lifting, no pauses."),
        .init(label: "Standard", eccentric: 3, bottomPause: 1, concentric: 1, topPause: 0,
              description: "Controlled lowering, brief pause at the bottom, controlled lift."),
        .init(label: "Slow eccentric", eccentric: 4, bottomPause: 0, concentric: 1, topPause: 0,
              description: "Emphasizes eccentric strength with a fast concentric."),
        .init(label: "Explosive", eccentric: 1, bottomPause: 0, concentric: 1, topPause: 0,
              description: "Fast lowering and lifting, power-focused."),
        .init(label: "Time under tension", eccentric: 3, bottomPause: 3, concentric: 3, topPause: 0,
              description: "Long eccentric, pause, and lift for maximum time under tension."),
        .init(label: "Eccentric overload", eccentric: 5, bottomPause: 0, concentric: 1, topPause: 0,
              description: "Very slow lowering, fast lift."),
    ]
}
