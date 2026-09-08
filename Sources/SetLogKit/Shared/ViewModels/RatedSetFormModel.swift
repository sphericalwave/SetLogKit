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

    /// Four tempo phases carried forward from the last saved set, whatever the
    /// skill — the views read them from `@AppStorage` and pass them in.
    struct Tempo {
        var eccentric: Int
        var bottomPause: Int
        var concentric: Int
        var topPause: Int
    }

    /// Seeds the form once: from the set being edited, or from the skill's
    /// last set plus the carried-forward tempo when logging a new one.
    /// Re-entrant on purpose — `onAppear` can fire more than once.
    func initIfNeeded(editing: RatedSetDraft<Payload>?,
                      priorSets: [PriorSet],
                      defaultSliceCount: Int,
                      suggestedDecision: ProgressionDecision,
                      initialIsometric: Bool,
                      lastTempo: Tempo) {
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
            tempoEccentric = lastTempo.eccentric
            tempoBottomPause = lastTempo.bottomPause
            tempoConcentric = lastTempo.concentric
            tempoTopPause = lastTempo.topPause
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
    var tempoIsEmpty: Bool {
        SetTempo(eccentric: tempoEccentric, bottomPause: tempoBottomPause,
                 concentric: tempoConcentric, topPause: tempoTopPause).isEmpty
    }
}
