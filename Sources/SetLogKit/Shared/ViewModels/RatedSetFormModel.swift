//
//  RatedSetFormModel.swift
//  SetLogKit
//
//  State for the set-logging form, shared by the iOS and macOS chromes.
//  Platform-agnostic: no SwiftUI view code, no UIKit/AppKit. The views own
//  presentation and the `@AppStorage` carry-forward values, and hand those in.
//

import Foundation

@MainActor
@Observable
final class RatedSetFormModel<Payload: Codable & Equatable & Sendable> {
    var reps = 1
    var rpt = 7
    var rpe = 6
    var rpd = 3
    var notes = ""
    var decision: ProgressionDecision = .repeat
    var isometric = false
    var sliceCount = 0
    var payload: Payload?
    var loggedAt = Date()
    var tempoEccentric = 0
    var tempoBottomPause = 0
    var tempoConcentric = 0
    var tempoTopPause = 0

    private var didInit = false

    /// Four tempo phases. `lastTempo` is the global carry-forward from the last
    /// saved set (any skill); `suggestedTempo`, when a host supplies it, is a
    /// per-exercise tempo that takes precedence for a new set.
    typealias Tempo = TempoValue

    /// Seeds the form once: from the set being edited, or — for a new set —
    /// from the skill's last set plus a tempo. The tempo seed is
    /// `suggestedTempo` when the host passed one (a per-exercise tempo),
    /// otherwise the global `lastTempo` carry-forward.
    /// Re-entrant on purpose — `onAppear` can fire more than once.
    func initIfNeeded(editing: RatedSetDraft<Payload>?,
                      priorSets: [PriorSet],
                      defaultSliceCount: Int,
                      suggestedDecision: ProgressionDecision,
                      initialIsometric: Bool,
                      lastTempo: Tempo,
                      suggestedTempo: Tempo? = nil) {
        guard !didInit else { return }
        didInit = true
        if let edit = editing {
            reps = edit.reps; rpt = edit.rpt; rpe = edit.rpe; rpd = edit.rpd
            notes = edit.notes; decision = edit.decision
            isometric = edit.isometric; sliceCount = edit.sliceCount
            payload = edit.payload
            loggedAt = edit.loggedAt ?? Date()
            tempoEccentric = edit.tempoEccentric; tempoBottomPause = edit.tempoBottomPause
            tempoConcentric = edit.tempoConcentric; tempoTopPause = edit.tempoTopPause
        } else {
            if let last = priorSets.sorted(by: { $0.loggedAt < $1.loggedAt }).last {
                reps = last.reps; rpt = last.rpt; rpe = last.rpe; rpd = last.rpd
            }
            decision = suggestedDecision
            isometric = initialIsometric
            sliceCount = defaultSliceCount
            let seed = suggestedTempo ?? lastTempo
            tempoEccentric = seed.eccentric
            tempoBottomPause = seed.bottomPause
            tempoConcentric = seed.concentric
            tempoTopPause = seed.topPause
        }
    }

    /// The value Save emits. An untouched equipment field leaves `payload`
    /// nil, in which case the suggested payload stands in — that's what makes
    /// "leave it empty to keep last time's weight" work.
    func entry(fallbackPayload: Payload?) -> RatedSetEntry<Payload> {
        RatedSetEntry(
            reps: reps, rpt: rpt, rpe: rpe, rpd: rpd, notes: notes,
            decision: decision, isometric: isometric, sliceCount: sliceCount,
            payload: payload ?? fallbackPayload, loggedAt: loggedAt,
            tempoEccentric: tempoEccentric, tempoBottomPause: tempoBottomPause,
            tempoConcentric: tempoConcentric, tempoTopPause: tempoTopPause
        )
    }

    var tempo: Tempo {
        Tempo(eccentric: tempoEccentric, bottomPause: tempoBottomPause,
              concentric: tempoConcentric, topPause: tempoTopPause)
    }

    /// No phase has any seconds in it — nothing for the tempo coach to call out.
    var tempoIsEmpty: Bool { tempo.isEmpty }
}
