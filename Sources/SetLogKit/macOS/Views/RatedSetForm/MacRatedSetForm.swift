//
//  MacRatedSetForm.swift
//  SetLogKit
//
//  macOS chrome for the set-logging form. The Mac gets a pinned sheet size
//  (unsized, the form stretches off the presenting window and clips every
//  field label), a grouped form, and an explicit Cancel/Save bar along the
//  bottom instead of navigation-bar actions — which on a Mac sheet are easy
//  to miss even when they do render.
//
//  The navigation stack stays: `TempoRow` pushes `TempoDetailView`, and that
//  push needs a stack on both platforms.
//
//  Defines `struct RatedSetForm` for macOS; the file name differs from the
//  iOS one only because a single target can't emit two
//  `RatedSetForm.stringsdata`.
//

#if os(macOS)
import SwiftUI
import EquipmentKit

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

    @State private var model = RatedSetFormModel<Equipment.Payload>()

    // Last saved tempo, carried into the next new set (any skill).
    @AppStorage("setLog.lastTempo.eccentric") private var lastTempoEccentric = 0
    @AppStorage("setLog.lastTempo.bottomPause") private var lastTempoBottomPause = 0
    @AppStorage("setLog.lastTempo.concentric") private var lastTempoConcentric = 0
    @AppStorage("setLog.lastTempo.topPause") private var lastTempoTopPause = 0

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

    private var resolvedHR: HRStats? { editing?.hr ?? liveHR }

    private var canSave: Bool {
        !config.equipmentRequired || Equipment.isValid(model.payload ?? suggestedPayload)
    }

    private var title: String { editing == nil ? "Log Set" : "Edit Set" }

    public var body: some View {
        VStack(spacing: 0) {
            NavigationStack {
                Form {
                    RatedSetFormSections<Skill, Equipment, Header>(
                        skill: skill,
                        config: config,
                        suggestedPayload: suggestedPayload,
                        hr: resolvedHR,
                        maxHR: HRConfig.effectiveMax(age: hrAge, manualOverride: hrMaxOverride),
                        header: header,
                        model: model
                    )
                }
                .formStyle(.grouped)
                .navigationTitle(title)
            }

            Divider()

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { onCancel?(); dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save", action: save)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canSave)
                    .accessibilityIdentifier("ratedSetForm.save")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(width: 560, height: 720)
        .onAppear(perform: initModel)
    }

    private func initModel() {
        model.initIfNeeded(
            editing: editing,
            priorSets: skill.priorSets,
            defaultSliceCount: skill.defaultSliceCount,
            suggestedDecision: suggestedDecision,
            initialIsometric: initialIsometric,
            lastTempo: .init(eccentric: lastTempoEccentric, bottomPause: lastTempoBottomPause,
                             concentric: lastTempoConcentric, topPause: lastTempoTopPause)
        )
    }

    private func save() {
        let tempo = model.tempo
        lastTempoEccentric = tempo.eccentric
        lastTempoBottomPause = tempo.bottomPause
        lastTempoConcentric = tempo.concentric
        lastTempoTopPause = tempo.topPause
        onSave(model.entry(fallbackPayload: suggestedPayload))
        dismiss()
    }
}
#endif
