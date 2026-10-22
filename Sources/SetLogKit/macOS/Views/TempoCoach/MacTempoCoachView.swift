//
//  MacTempoCoachView.swift
//  SetLogKit
//
//  macOS chrome for the tempo coach: a pinned sheet size and an explicit
//  action bar along the bottom, matching `MacRatedSetForm`. No idle-timer
//  handling — that's an iOS concern.
//
//  Defines `struct TempoCoachView` for macOS; the file name differs from the
//  iOS one only because a single target can't emit two
//  `TempoCoachView.stringsdata`.
//

#if os(macOS)
import SwiftUI

public struct TempoCoachView: View {
    /// The rep count when the set ends. Not called if the coach is closed
    /// without ever starting.
    private let onFinish: (Int) -> Void

    @State private var model: TempoCoachModel
    @Environment(\.dismiss) private var dismiss

    public init(eccentric: Int, bottomPause: Int, concentric: Int, topPause: Int,
                targetReps: Int,
                phaseNames: TempoPhaseNames = .default,
                onFinish: @escaping (Int) -> Void) {
        self.onFinish = onFinish
        _model = State(initialValue: TempoCoachModel(
            tempo: SetTempo(eccentric: eccentric, bottomPause: bottomPause,
                            concentric: concentric, topPause: topPause),
            targetReps: targetReps,
            phaseNames: phaseNames
        ))
    }

    public var body: some View {
        VStack(spacing: 0) {
            Spacer()
            TempoCoachReadout(model: model)
                .padding(.horizontal, 32)
            Spacer()

            Divider()

            HStack(spacing: 12) {
                Button("Cancel", role: .cancel) { model.stop(); dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                if model.isRunning {
                    Button(model.isPaused ? "Resume" : "Pause") {
                        model.isPaused ? model.resume() : model.pause()
                    }
                    Button("Stop", action: finish)
                        .keyboardShortcut(.defaultAction)
                        .accessibilityIdentifier("tempoCoach.stop")
                } else {
                    Button("Start") { model.start() }
                        .keyboardShortcut(.defaultAction)
                        .disabled(!model.isAvailable)
                        .accessibilityIdentifier("tempoCoach.start")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(width: 420, height: 460)
        .onDisappear { model.stop() }
    }

    private func finish() {
        let reps = model.completedReps
        model.stop()
        onFinish(reps)
        dismiss()
    }
}
#endif
