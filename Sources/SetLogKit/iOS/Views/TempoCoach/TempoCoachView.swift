//
//  TempoCoachView.swift
//  SetLogKit
//
//  iOS chrome for the tempo coach: a navigation stack with the readout
//  filling the screen and one large action button in thumb reach. The screen
//  stays awake while the coach runs — it's read mid-set, not touched.
//

#if os(iOS)
import SwiftUI
import UIKit

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
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()
                TempoCoachReadout(model: model)
                Spacer()
                actions
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .navigationTitle("Tempo Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { model.stop(); dismiss() }
                }
            }
        }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            model.stop()
        }
    }

    @ViewBuilder
    private var actions: some View {
        VStack(spacing: 12) {
            if model.isRunning {
                Button("Stop", action: finish)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("tempoCoach.stop")

                Button(model.isPaused ? "Resume" : "Pause") {
                    model.isPaused ? model.resume() : model.pause()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            } else {
                Button("Start") { model.start() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .disabled(!model.isAvailable)
                    .accessibilityIdentifier("tempoCoach.start")
            }
        }
    }

    private func finish() {
        let reps = model.completedReps
        model.stop()
        onFinish(reps)
        dismiss()
    }
}
#endif
