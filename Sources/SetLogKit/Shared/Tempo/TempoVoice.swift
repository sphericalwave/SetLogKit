//
//  TempoVoice.swift
//  SetLogKit
//
//  The narrow slice of audio the tempo coach needs, so `TempoCoachModel` can
//  be driven by a double in tests. WorkoutAudioKit's `AudioCueService` is the
//  real implementation — SetLogKit doesn't own a second speech synthesizer or
//  audio-session setup.
//

import Foundation
import WorkoutAudioKit

@MainActor
protocol TempoVoice: AnyObject {
    /// Starts the audio session before the first cue, so the set survives the
    /// screen locking or the app backgrounding.
    func prepare()
    /// Speaks a beat, cutting any utterance still running from the last one —
    /// the beat clock doesn't wait for speech.
    func say(_ text: String)
    func stopSpeaking()
    func playTargetReached()
    func playTerminal()
}

extension AudioCueService: TempoVoice {
    func prepare() { prepareForBackground() }

    func say(_ text: String) {
        stopSpeaking()
        speak(text)
    }

    func playTargetReached() { play(.roundEnd) }

    func playTerminal() { play(.terminal) }
}
