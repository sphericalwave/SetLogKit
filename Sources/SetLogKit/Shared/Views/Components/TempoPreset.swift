//
//  TempoPreset.swift
//  SetLogKit
//
//  Predefined eccentric-pause-concentric-pause tempo schemes, tap-selected
//  from `TempoDetailView` instead of dialed in via four narrow steppers.
//

import Foundation

/// Four phase durations in seconds — the shape `TempoPreset`, `RatedSetDraft`,
/// and the tempo coach all speak. Hosts build one to seed a new set's tempo
/// from a per-exercise value (`RatedSetForm(suggestedTempo:)`).
public struct TempoValue: Equatable, Sendable {
    public var eccentric: Int
    public var bottomPause: Int
    public var concentric: Int
    public var topPause: Int

    public init(eccentric: Int = 0, bottomPause: Int = 0,
                concentric: Int = 0, topPause: Int = 0) {
        self.eccentric = eccentric
        self.bottomPause = bottomPause
        self.concentric = concentric
        self.topPause = topPause
    }

    public var isEmpty: Bool {
        eccentric == 0 && bottomPause == 0 && concentric == 0 && topPause == 0
    }
}

public struct TempoPreset: Identifiable, Equatable, Sendable {
    public let label: String
    public let eccentric: Int
    public let bottomPause: Int
    public let concentric: Int
    public let topPause: Int
    public let description: String
    /// True for host-supplied presets — the picker lets those be deleted, the
    /// seven built-ins can't be.
    public let isCustom: Bool

    public init(label: String, eccentric: Int, bottomPause: Int, concentric: Int, topPause: Int,
                description: String, isCustom: Bool = false) {
        self.label = label
        self.eccentric = eccentric
        self.bottomPause = bottomPause
        self.concentric = concentric
        self.topPause = topPause
        self.description = description
        self.isCustom = isCustom
    }

    public var id: String { (isCustom ? "custom-" : "") + tempoString }
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

/// A host's custom tempo presets plus the hooks to add and remove them. The
/// presets themselves live wherever the host keeps them (gpp: a
/// CloudKit-synced model); SetLogKit just renders and edits the list.
///
/// Not `Sendable` — it carries the callbacks — so it rides alongside
/// `RatedSetFormConfig` rather than inside it.
public struct TempoPresetLibrary {
    public var custom: [TempoPreset]
    public var onAdd: ((TempoPreset) -> Void)?
    public var onDelete: ((TempoPreset) -> Void)?

    public init(custom: [TempoPreset] = [],
                onAdd: ((TempoPreset) -> Void)? = nil,
                onDelete: ((TempoPreset) -> Void)? = nil) {
        self.custom = custom
        self.onAdd = onAdd
        self.onDelete = onDelete
    }

    /// No custom presets, no add affordance — the default for consumers that
    /// only want the seven built-ins.
    public static let none = TempoPresetLibrary()

    var isEditable: Bool { onAdd != nil }
}
