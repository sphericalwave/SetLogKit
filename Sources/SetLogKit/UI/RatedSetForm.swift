//
//  RatedSetForm.swift
//  SetLogKit
//
//  The shared set-logging sheet. Apps conform their Skill to `RatedSetSkill`,
//  supply an `EquipmentModel` (from EquipmentKit) for the equipment input,
//  and provide their own skill-thumbnail header; the form owns everything
//  else — score chips, reps, TED metrics, notes, decision, isometric/slices,
//  and the equipment slot — driven by `RatedSetFormConfig`.
//
//  A new equipment app becomes a near-drop-in: conform + provide an
//  EquipmentModel and it gets this whole sheet.
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

    public init(reps: Int, rpt: Int, rpe: Int, rpd: Int, notes: String,
                decision: ProgressionDecision, isometric: Bool, sliceCount: Int,
                payload: Payload?, hr: HRStats? = nil) {
        self.reps = reps; self.rpt = rpt; self.rpe = rpe; self.rpd = rpd
        self.notes = notes; self.decision = decision; self.isometric = isometric
        self.sliceCount = sliceCount; self.payload = payload; self.hr = hr
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

    public init(showsIsometric: Bool = true,
                showsSlices: Bool = true,
                tedStyle: TEDMetricStepper.Style = .described,
                showsDecision: Bool = true,
                equipmentRequired: Bool = false,
                repsInfo: String = "",
                slicesInfo: String = "") {
        self.showsIsometric = showsIsometric
        self.showsSlices = showsSlices
        self.tedStyle = tedStyle
        self.showsDecision = showsDecision
        self.equipmentRequired = equipmentRequired
        self.repsInfo = repsInfo
        self.slicesInfo = slicesInfo
    }
}

// MARK: - The form

public struct RatedSetForm<Skill: RatedSetSkill, Equipment: EquipmentModel, Header: View>: View {
    private let skill: Skill
    private let editing: RatedSetDraft<Equipment.Payload>?
    private let suggestedDecision: ProgressionDecision
    private let suggestedPayload: Equipment.Payload?
    private let liveHR: HRStats?
    private let config: RatedSetFormConfig
    private let initialIsometric: Bool
    private let header: () -> Header
    private let onSave: (RatedSetEntry<Equipment.Payload>) -> Void
    private let onCancel: (() -> Void)?

    @State private var reps = 1
    @State private var rpt = 7
    @State private var rpe = 6
    @State private var rpd = 3
    @State private var notes = ""
    @State private var decision: ProgressionDecision = .repeat
    @State private var isometric = false
    @State private var sliceCount = 0
    @State private var payload: Equipment.Payload?
    @State private var didInit = false

    @AppStorage(HRConfig.ageKey) private var hrAge = 30
    @AppStorage(HRConfig.overrideKey) private var hrMaxOverride = 0
    @Environment(\.dismiss) private var dismiss

    public init(
        skill: Skill,
        equipment: Equipment.Type,
        suggestedDecision: ProgressionDecision,
        editing: RatedSetDraft<Equipment.Payload>? = nil,
        suggestedPayload: Equipment.Payload? = nil,
        liveHR: HRStats? = nil,
        config: RatedSetFormConfig = .init(),
        initialIsometric: Bool = false,
        @ViewBuilder header: @escaping () -> Header,
        onSave: @escaping (RatedSetEntry<Equipment.Payload>) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.skill = skill
        self.editing = editing
        self.suggestedDecision = suggestedDecision
        self.suggestedPayload = suggestedPayload
        self.liveHR = liveHR
        self.config = config
        self.initialIsometric = initialIsometric
        self.header = header
        self.onSave = onSave
        self.onCancel = onCancel
    }

    private var sortedPrior: [PriorSet] { skill.priorSets.sorted { $0.loggedAt < $1.loggedAt } }

    private var lastNote: String? {
        sortedPrior.reversed().lazy
            .compactMap(\.notes)
            .first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private var setScore: Double {
        CompletionScorer.setScore(quality: CompletionScorer.techniqueFraction(rpt: rpt))
    }
    private var workoutScore: Double? {
        CompletionScorer.workoutScore(
            quality: CompletionScorer.techniqueFraction(rpt: rpt),
            depth: skill.depth, maxDepth: skill.maxDepth
        )
    }

    private var resolvedHR: HRStats? { editing?.hr ?? liveHR }

    private var canSave: Bool {
        !config.equipmentRequired || Equipment.isValid(payload)
    }

    public var body: some View {
        NavigationStack {
            Form {
                if let hr = resolvedHR {
                    Section("Heart rate") {
                        let maxHR = HRConfig.effectiveMax(age: hrAge, manualOverride: hrMaxOverride)
                        HRStatRow(label: "Min", bpm: hr.min, maxHR: maxHR)
                        HRStatRow(label: "Avg", bpm: hr.avg, maxHR: maxHR)
                        HRStatRow(label: "Max", bpm: hr.max, maxHR: maxHR)
                    }
                }

                mainSection

                if config.showsIsometric || config.showsSlices || Equipment.self != NoEquipment.self {
                    equipmentSection
                }
            }
            .navigationTitle(editing == nil ? "Log Set" : "Edit Set")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel?(); dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(RatedSetEntry(
                            reps: reps, rpt: rpt, rpe: rpe, rpd: rpd, notes: notes,
                            decision: decision, isometric: isometric,
                            sliceCount: sliceCount, payload: payload
                        ))
                        dismiss()
                    }
                    .bold()
                    .disabled(!canSave)
                }
            }
            .onAppear(perform: initStateIfNeeded)
        }
    }

    @ViewBuilder
    private var mainSection: some View {
        Section {
            HStack {
                Text("Score").font(.callout)
                Spacer()
                VStack(spacing: 2) {
                    Text("Set").font(.caption2).foregroundStyle(.secondary)
                    CompletionChip(percent: setScore)
                }
                VStack(spacing: 2) {
                    Text("Workout").font(.caption2).foregroundStyle(.secondary)
                    CompletionChip(percent: workoutScore)
                }
            }

            MetricStepperRow(label: "Reps", value: $reps, range: 0...200, info: config.repsInfo)

            HStack(alignment: .top, spacing: 0) {
                TEDMetricStepper(label: "Technique", value: $rpt,
                                 colorFor: FalseColor.technique,
                                 describe: TEDDescription.technique, style: config.tedStyle)
                Spacer()
                TEDMetricStepper(label: "Exertion", value: $rpe,
                                 colorFor: FalseColor.exertion,
                                 describe: TEDDescription.exertion, style: config.tedStyle)
                Spacer()
                TEDMetricStepper(label: "Discomfort", value: $rpd,
                                 colorFor: FalseColor.discomfort,
                                 describe: TEDDescription.discomfort, style: config.tedStyle)
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))

            VStack(spacing: 8) {
                HStack {
                    TextField("Notes (optional)", text: $notes,
                              prompt: Text(lastNote ?? "Notes (optional)"), axis: .vertical)
                        .lineLimit(2...6)
                        .padding(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor, lineWidth: 1))
                    Button(action: { if let last = lastNote { notes = last } }) {
                        Image(systemName: "arrow.uturn.left").imageScale(.large)
                    }
                    .buttonStyle(.bordered)
                    .disabled(lastNote == nil)
                }

                if config.showsDecision {
                    Picker("Decision", selection: $decision) {
                        ForEach(ProgressionDecision.allCases, id: \.self) { d in
                            Text(d.label).tag(d)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(.accentColor)
                }
            }
        } header: {
            HStack(spacing: 12) {
                header()
                VStack(alignment: .leading, spacing: 2) {
                    Text(skill.displayName).font(.headline).foregroundStyle(.primary)
                    if let fam = skill.familyName {
                        Text(fam).font(.caption).foregroundStyle(.secondary)
                    }
                    Text("Level \(skill.depth)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 4)
            .textCase(nil)
        }
    }

    @ViewBuilder
    private var equipmentSection: some View {
        Section {
            if config.showsIsometric {
                Toggle("Isometric", isOn: $isometric)
                    .tint(.accentColor)
                    .onChange(of: isometric) { _, on in if on { reps = 1 } }
            }
            if Equipment.self != NoEquipment.self {
                Equipment.inputView(payload: $payload, suggested: suggestedPayload)
            }
            if config.showsSlices {
                MetricStepperRow(
                    label: "Slices", value: $sliceCount, range: 0...30,
                    suffix: sliceCount > 0 ? " · \(sliceCount * 30)s" : "",
                    info: config.slicesInfo
                )
            }
        }
    }

    private func initStateIfNeeded() {
        guard !didInit else { return }
        didInit = true
        if let edit = editing {
            reps = edit.reps; rpt = edit.rpt; rpe = edit.rpe; rpd = edit.rpd
            notes = edit.notes; decision = edit.decision
            isometric = edit.isometric; sliceCount = edit.sliceCount
            payload = edit.payload
        } else {
            if let last = sortedPrior.last {
                reps = last.reps; rpt = last.rpt; rpe = last.rpe; rpd = last.rpd
            }
            decision = suggestedDecision
            isometric = initialIsometric
            sliceCount = skill.defaultSliceCount
            payload = suggestedPayload
        }
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
