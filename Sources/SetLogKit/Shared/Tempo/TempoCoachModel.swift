//
//  TempoCoachModel.swift
//  SetLogKit
//
//  State and beat clock for the tempo coach: walks `TempoScript`'s beats one
//  second at a time, speaks each through a `TempoVoice`, and counts the reps
//  that finish. Platform-agnostic — no SwiftUI, no UIKit/AppKit. The views
//  own presentation.
//

import Foundation
import WorkoutAudioKit

@MainActor
@Observable
final class TempoCoachModel {
    private(set) var currentRep = 0
    private(set) var phase: TempoPhase?
    /// 1-based position within the current phase, for the beat readout.
    private(set) var beatIndex = 0
    /// Reps carried all the way through. A rep abandoned mid-way doesn't count.
    private(set) var completedReps = 0
    private(set) var isRunning = false
    private(set) var isPaused = false

    let tempo: SetTempo
    let targetReps: Int
    let phaseNames: TempoPhaseNames

    private let voice: TempoVoice
    private let beatDuration: Duration
    private let clock = ContinuousClock()

    private var task: Task<Void, Never>?
    /// Where the next beat resumes from — kept outside the run loop so pause
    /// can tear the task down and resume can pick the rep back up.
    private var nextRep = 1
    private var nextBeat = 0

    /// `beatDuration` is a seam for tests; the coach runs at one beat per
    /// second, which is what a tempo's phase counts mean.
    init(tempo: SetTempo,
         targetReps: Int,
         phaseNames: TempoPhaseNames = .default,
         voice: TempoVoice? = nil,
         beatDuration: Duration = .seconds(1)) {
        self.tempo = tempo
        self.targetReps = targetReps
        self.phaseNames = phaseNames
        self.voice = voice ?? AudioCueService()
        self.beatDuration = beatDuration
    }

    /// No beats means no coach — an all-zero tempo has nothing to call out.
    var isAvailable: Bool { !tempo.isEmpty }

    /// Reps done over reps targeted. Goes past 1 on an overrun; the views
    /// decide how to show that rather than this clamping it away.
    var progress: Double {
        targetReps > 0 ? Double(completedReps) / Double(targetReps) : 0
    }

    func start() {
        guard isAvailable, !isRunning else { return }
        voice.prepare()
        isRunning = true
        isPaused = false
        launch()
    }

    func pause() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        cancelTask()
    }

    func resume() {
        guard isRunning, isPaused else { return }
        isPaused = false
        launch()
    }

    /// Ends the set. `completedReps` is the result the caller reads. The views
    /// call this from `onDisappear` too — `deinit` can't touch the
    /// main-actor-isolated task, so dismissal is what tears the clock down.
    func stop() {
        let wasRunning = isRunning
        cancelTask()
        isRunning = false
        isPaused = false
        phase = nil
        beatIndex = 0
        if wasRunning { voice.playTerminal() }
    }

    private func launch() {
        task = Task { [weak self] in await self?.run() }
    }

    private func cancelTask() {
        task?.cancel()
        task = nil
        voice.stopSpeaking()
    }

    private func run() async {
        // The schedule is a chain of absolute deadlines, not a sleep of one
        // beat at a time — speaking and the run loop's own overhead would
        // otherwise push every beat a little later than the last.
        var deadline = clock.now
        while !Task.isCancelled {
            let beats = TempoScript.beats(for: tempo, names: phaseNames, rep: nextRep)
            guard !beats.isEmpty else { return }
            currentRep = nextRep

            while nextBeat < beats.count {
                let beat = beats[nextBeat]
                phase = beat.phase
                beatIndex = beat.index
                voice.say(beat.utterance)

                deadline = deadline.advanced(by: beatDuration)
                do { try await clock.sleep(until: deadline) } catch { return }
                nextBeat += 1
            }

            completedReps = nextRep
            // Target reached is a marker, not an ending — the set runs until
            // it's stopped, and the reps past target are the ones that count.
            if completedReps == targetReps { voice.playTargetReached() }
            nextRep += 1
            nextBeat = 0
        }
    }
}
