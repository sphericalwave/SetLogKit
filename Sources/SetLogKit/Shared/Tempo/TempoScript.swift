//
//  TempoScript.swift
//  SetLogKit
//
//  Turns a four-phase tempo (eccentric-pause-concentric-pause, seconds) into
//  the ordered, one-per-second beats the tempo coach speaks aloud. Pure and
//  platform-agnostic — no audio, no timing, so the whole cue script is
//  unit-testable without listening to it.
//

import Foundation

/// The four phases of a rep, in the order they're performed.
public enum TempoPhase: CaseIterable, Equatable, Sendable {
    case eccentric, bottomPause, concentric, topPause
}

/// What the coach calls each phase. Defaults suit a lowering-first movement;
/// hosts can substitute per-exercise wording.
public struct TempoPhaseNames: Equatable, Sendable {
    public var eccentric: String
    public var bottomPause: String
    public var concentric: String
    public var topPause: String

    public init(eccentric: String = "lower",
                bottomPause: String = "hold",
                concentric: String = "extend",
                topPause: String = "hold") {
        self.eccentric = eccentric
        self.bottomPause = bottomPause
        self.concentric = concentric
        self.topPause = topPause
    }

    public static let `default` = TempoPhaseNames()

    func name(for phase: TempoPhase) -> String {
        switch phase {
        case .eccentric: return eccentric
        case .bottomPause: return bottomPause
        case .concentric: return concentric
        case .topPause: return topPause
        }
    }
}

/// The four phase durations in seconds, as `TempoPreset` and `RatedSetDraft`
/// already store them.
struct SetTempo: Equatable, Sendable {
    var eccentric: Int
    var bottomPause: Int
    var concentric: Int
    var topPause: Int

    /// Negative values can't come from the stepper, but clamp anyway so a bad
    /// host value can't produce a rep with fewer beats than phases.
    private func clamped(_ value: Int) -> Int { max(0, value) }

    var secondsPerRep: Int {
        clamped(eccentric) + clamped(bottomPause) + clamped(concentric) + clamped(topPause)
    }

    var isEmpty: Bool { secondsPerRep == 0 }

    func seconds(of phase: TempoPhase) -> Int {
        switch phase {
        case .eccentric: return clamped(eccentric)
        case .bottomPause: return clamped(bottomPause)
        case .concentric: return clamped(concentric)
        case .topPause: return clamped(topPause)
        }
    }
}

/// One second of a rep: which phase it belongs to, how far into that phase it
/// is, and what the coach says on it.
struct TempoBeat: Equatable, Sendable {
    let phase: TempoPhase
    /// 1-based position within the phase.
    let index: Int
    let utterance: String
}

enum TempoScript {

    /// The beats of a single rep. Beat 1 of each phase speaks the phase name,
    /// later beats count it out; the very first beat of the rep is prefixed
    /// with the rep number ("rep three, lower").
    ///
    /// The rep number rides along with beat 1 rather than taking a beat of its
    /// own — a separate announcement would stretch every rep by a second and
    /// the tempo would no longer be the tempo.
    static func beats(for tempo: SetTempo,
                      names: TempoPhaseNames = .default,
                      rep: Int) -> [TempoBeat] {
        var beats: [TempoBeat] = []
        for phase in TempoPhase.allCases {
            let seconds = tempo.seconds(of: phase)
            guard seconds > 0 else { continue }
            for index in 1...seconds {
                var utterance = index == 1 ? names.name(for: phase) : word(index)
                if beats.isEmpty {
                    utterance = "rep \(word(rep)), \(utterance)"
                }
                beats.append(TempoBeat(phase: phase, index: index, utterance: utterance))
            }
        }
        return beats
    }

    private static let words = ["zero", "one", "two", "three", "four", "five",
                                "six", "seven", "eight", "nine", "ten"]

    /// Spoken form of a count. Past ten the synthesizer reads the digits fine
    /// on its own, and a full number-word table isn't worth carrying.
    static func word(_ n: Int) -> String {
        n >= 0 && n < words.count ? words[n] : String(n)
    }
}
