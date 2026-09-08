//
//  RatedSetFormTypes.swift
//  SetLogKit
//
//  The public contract of the set-logging sheet: what the form reads from an
//  app's skill (`RatedSetSkill`, `PriorSet`), what it takes in and hands back
//  (`RatedSetDraft`, `RatedSetEntry`), and what it shows (`RatedSetFormConfig`).
//
//  The form itself is split by platform — `iOS/Views/RatedSetForm` and
//  `macOS/Views/RatedSetForm` own the chrome, `Shared/Views/RatedSetFormSections`
//  owns the fields they both show, and `Shared/ViewModels/RatedSetFormModel`
//  owns the state. Apps conform their Skill, supply an `EquipmentModel` (from
//  EquipmentKit) for the equipment input, and provide a header view; the form
//  owns everything else.
//

import SwiftUI
import EquipmentKit

// MARK: - What the form reads from an app's skill

/// A previously logged set, for carry-forward defaults and the "reuse last
/// note" affordance. Order-independent; the form sorts by `loggedAt`.
public struct PriorSet: Sendable {
    public let reps: Int
    public let rpt: Int
    public let rpe: Int
    public let rpd: Int
    public let notes: String?
    public let loggedAt: Date

    public init(reps: Int, rpt: Int, rpe: Int, rpd: Int, notes: String?, loggedAt: Date) {
        self.reps = reps
        self.rpt = rpt
        self.rpe = rpe
        self.rpd = rpd
        self.notes = notes
        self.loggedAt = loggedAt
    }
}

public protocol RatedSetSkill {
    var displayName: String { get }
    var familyName: String? { get }
    var depth: Int { get }
    var maxDepth: Int { get }
    /// Prior sets for THIS skill, for carry-forward + last-note.
    var priorSets: [PriorSet] { get }
    /// Slice count to seed a new set with (per-skill default). Defaults to 0.
    var defaultSliceCount: Int { get }
}

public extension RatedSetSkill {
    var defaultSliceCount: Int { 0 }
}

// MARK: - Editing input / save output

/// Prefill values when editing an existing set.
public struct RatedSetDraft<Payload: Codable & Equatable & Sendable>: Sendable {
    public let reps: Int
    public let rpt: Int
    public let rpe: Int
    public let rpd: Int
    public let notes: String
    public let decision: ProgressionDecision
    public let isometric: Bool
    public let sliceCount: Int
    public let payload: Payload?
    public let hr: HRStats?
    /// The date the set was logged, prefilled into the date picker when editing.
    public let loggedAt: Date?
    public let tempoEccentric: Int
    public let tempoBottomPause: Int
    public let tempoConcentric: Int
    public let tempoTopPause: Int

    public init(reps: Int, rpt: Int, rpe: Int, rpd: Int, notes: String,
                decision: ProgressionDecision, isometric: Bool, sliceCount: Int,
                payload: Payload?, hr: HRStats? = nil, loggedAt: Date? = nil,
                tempoEccentric: Int = 0, tempoBottomPause: Int = 0,
                tempoConcentric: Int = 0, tempoTopPause: Int = 0) {
        self.reps = reps; self.rpt = rpt; self.rpe = rpe; self.rpd = rpd
        self.notes = notes; self.decision = decision; self.isometric = isometric
        self.sliceCount = sliceCount; self.payload = payload; self.hr = hr
        self.loggedAt = loggedAt
        self.tempoEccentric = tempoEccentric; self.tempoBottomPause = tempoBottomPause
        self.tempoConcentric = tempoConcentric; self.tempoTopPause = tempoTopPause
    }
}

/// The value the form emits on Save; the app maps it onto its model write.
public struct RatedSetEntry<Payload: Codable & Equatable & Sendable>: Sendable {
    public let reps: Int
    public let rpt: Int
    public let rpe: Int
    public let rpd: Int
    public let notes: String
    public let decision: ProgressionDecision
    public let isometric: Bool
    public let sliceCount: Int
    public let payload: Payload?
    /// The date the user picked for the set (defaults to now for new sets).
    public let loggedAt: Date
    public let tempoEccentric: Int
    public let tempoBottomPause: Int
    public let tempoConcentric: Int
    public let tempoTopPause: Int

    public init(reps: Int, rpt: Int, rpe: Int, rpd: Int, notes: String,
                decision: ProgressionDecision, isometric: Bool, sliceCount: Int,
                payload: Payload?, loggedAt: Date,
                tempoEccentric: Int = 0, tempoBottomPause: Int = 0,
                tempoConcentric: Int = 0, tempoTopPause: Int = 0) {
        self.reps = reps; self.rpt = rpt; self.rpe = rpe; self.rpd = rpd
        self.notes = notes; self.decision = decision; self.isometric = isometric
        self.sliceCount = sliceCount; self.payload = payload; self.loggedAt = loggedAt
        self.tempoEccentric = tempoEccentric; self.tempoBottomPause = tempoBottomPause
        self.tempoConcentric = tempoConcentric; self.tempoTopPause = tempoTopPause
    }
}

// MARK: - Config

public struct RatedSetFormConfig: Sendable {
    public var showsIsometric: Bool
    public var showsSlices: Bool
    public var tedStyle: TEDMetricStepper.Style
    public var showsDecision: Bool
    /// When true, Save is disabled until the equipment payload is valid
    /// (`EquipmentModel.isValid`). Apps compute this per-skill (e.g. only for
    /// workout sets) and pass the result.
    public var equipmentRequired: Bool
    public var repsInfo: String
    public var slicesInfo: String
    /// Shows the eccentric/pause/concentric/pause tempo row. Off by default
    /// so existing consumer apps are unaffected.
    public var showsTempo: Bool
    public var tempoInfo: String
    /// Adds a "Start tempo coach" row under the tempo row, which counts reps
    /// aloud at the set's tempo and writes the count back into Reps. Needs
    /// `showsTempo`; off by default.
    public var showsTempoCoach: Bool

    public init(showsIsometric: Bool = true,
                showsSlices: Bool = true,
                tedStyle: TEDMetricStepper.Style = .described,
                showsDecision: Bool = true,
                equipmentRequired: Bool = false,
                repsInfo: String = "",
                slicesInfo: String = "",
                showsTempo: Bool = false,
                tempoInfo: String = "",
                showsTempoCoach: Bool = false) {
        self.showsIsometric = showsIsometric
        self.showsSlices = showsSlices
        self.tedStyle = tedStyle
        self.showsDecision = showsDecision
        self.equipmentRequired = equipmentRequired
        self.repsInfo = repsInfo
        self.slicesInfo = slicesInfo
        self.showsTempo = showsTempo
        self.tempoInfo = tempoInfo
        self.showsTempoCoach = showsTempoCoach
    }
}

/// Sentinel equipment model for apps that log no equipment (bodyweight, e.g.
/// progYog). `RatedSetForm(equipment: NoEquipment.self, …)` renders no
/// equipment row.
public enum NoEquipment: EquipmentModel {
    public struct Payload: Codable, Equatable, Sendable {}
    public static let equipmentID = "none"
    public static let displayName = "None"
    public static let inputTitle = ""
    public static func summary(_ payload: Payload) -> String { "" }
    @MainActor
    public static func inputView(payload: Binding<Payload?>, suggested: Payload?) -> EmptyView {
        EmptyView()
    }
}
