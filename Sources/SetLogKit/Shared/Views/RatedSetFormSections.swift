//
//  RatedSetFormSections.swift
//  SetLogKit
//
//  The fields both platforms show, as `Section`s to drop inside a `Form`.
//  Chrome — navigation container, title, Cancel/Save placement, sizing —
//  belongs to the per-platform form that wraps this.
//

import SwiftUI
import EquipmentKit

struct RatedSetFormSections<Skill: RatedSetSkill, Equipment: EquipmentModel, Header: View>: View {
    let skill: Skill
    let config: RatedSetFormConfig
    let suggestedPayload: Equipment.Payload?
    let hr: HRStats?
    let maxHR: Int
    var tempoPresets: TempoPresetLibrary = .none
    let header: () -> Header
    @Bindable var model: RatedSetFormModel<Equipment.Payload>

    @State private var showTempoCoach = false

    private var lastNote: String? {
        skill.priorSets.sorted { $0.loggedAt < $1.loggedAt }.reversed().lazy
            .compactMap(\.notes)
            .first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private var setScore: Double {
        CompletionScorer.setScore(quality: CompletionScorer.techniqueFraction(rpt: model.rpt))
    }

    private var workoutScore: Double? {
        CompletionScorer.workoutScore(
            quality: CompletionScorer.techniqueFraction(rpt: model.rpt),
            depth: skill.depth, maxDepth: skill.maxDepth
        )
    }

    var body: some View {
        if let hr {
            Section("Heart rate") {
                HRStatRow(label: "Min", bpm: hr.min, maxHR: maxHR)
                HRStatRow(label: "Avg", bpm: hr.avg, maxHR: maxHR)
                HRStatRow(label: "Max", bpm: hr.max, maxHR: maxHR)
            }
        }

        mainSection

        if config.showsIsometric || config.showsSlices {
            equipmentSection
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

            DatePicker("Date", selection: $model.loggedAt, displayedComponents: .date)
                .accessibilityIdentifier("ratedSetForm.date")

            MetricStepperRow(label: "Reps", value: $model.reps, range: 0...200, info: config.repsInfo)
                .accessibilityIdentifier("ratedSetForm.reps")

            if config.showsTempo {
                TempoRow(eccentric: $model.tempoEccentric, bottomPause: $model.tempoBottomPause,
                         concentric: $model.tempoConcentric, topPause: $model.tempoTopPause,
                         info: config.tempoInfo, library: tempoPresets)
                    .accessibilityIdentifier("ratedSetForm.tempo")

                if config.showsTempoCoach && !model.tempoIsEmpty {
                    Button {
                        showTempoCoach = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "waveform")
                            Text("Start tempo coach")
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("ratedSetForm.tempoCoach")
                    .sheet(isPresented: $showTempoCoach) {
                        TempoCoachView(
                            eccentric: model.tempoEccentric,
                            bottomPause: model.tempoBottomPause,
                            concentric: model.tempoConcentric,
                            topPause: model.tempoTopPause,
                            targetReps: model.reps,
                            onFinish: { model.reps = $0 }
                        )
                    }
                }
            }

            if Equipment.self != NoEquipment.self {
                Equipment.inputView(payload: $model.payload, suggested: suggestedPayload)
            }

            HStack(alignment: .top, spacing: 0) {
                TEDMetricStepper(label: "Technique", value: $model.rpt,
                                 colorFor: FalseColor.technique,
                                 describe: TEDDescription.technique, style: config.tedStyle)
                Spacer()
                TEDMetricStepper(label: "Effort", value: $model.rpe,
                                 colorFor: FalseColor.exertion,
                                 describe: TEDDescription.exertion, style: config.tedStyle)
                Spacer()
                TEDMetricStepper(label: "Discomfort", value: $model.rpd,
                                 colorFor: FalseColor.discomfort,
                                 describe: TEDDescription.discomfort, style: config.tedStyle)
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))

            VStack(spacing: 8) {
                HStack {
                    TextField("Notes (optional)", text: $model.notes,
                              prompt: Text(lastNote ?? "Notes (optional)"), axis: .vertical)
                        .lineLimit(2...6)
                        .padding(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor, lineWidth: 1))
                        .accessibilityIdentifier("ratedSetForm.notes")
                    Button(action: { if let last = lastNote { model.notes = last } }) {
                        Image(systemName: "arrow.uturn.left").imageScale(.large)
                    }
                    .buttonStyle(.bordered)
                    .disabled(lastNote == nil)
                }

                if config.showsDecision {
                    Picker("Decision", selection: $model.decision) {
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
                Toggle("Isometric", isOn: $model.isometric)
                    .tint(.accentColor)
                    .onChange(of: model.isometric) { _, on in if on { model.reps = 1 } }
            }
            if config.showsSlices {
                MetricStepperRow(
                    label: "Slices", value: $model.sliceCount, range: 0...30,
                    suffix: model.sliceCount > 0 ? " · \(model.sliceCount * 30)s" : "",
                    info: config.slicesInfo
                )
            }
        }
    }
}
