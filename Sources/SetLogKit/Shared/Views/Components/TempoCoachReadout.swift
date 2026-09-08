//
//  TempoCoachReadout.swift
//  SetLogKit
//
//  What the tempo coach shows on both platforms: the rep count, big enough to
//  read from across a room mid-set, the phase being called, and progress
//  toward the target. The Start/Stop chrome around it is per-platform.
//

import SwiftUI

struct TempoCoachReadout: View {
    let model: TempoCoachModel

    private var phaseLine: String {
        guard model.isRunning else { return "Ready" }
        if model.isPaused { return "Paused" }
        guard let phase = model.phase else { return "Ready" }
        return "\(model.phaseNames.name(for: phase)) · \(model.beatIndex)"
    }

    private var overrun: Int { max(0, model.completedReps - model.targetReps) }

    private var progressLabel: String {
        overrun > 0
            ? "\(model.completedReps) / \(model.targetReps)  +\(overrun)"
            : "\(model.completedReps) / \(model.targetReps)"
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("\(model.currentRep)")
                .font(.system(size: 140, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .contentTransition(.numericText())
                .animation(.snappy, value: model.currentRep)
                .accessibilityIdentifier("tempoCoach.rep")

            Text(phaseLine)
                .font(.title2)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("tempoCoach.phase")

            VStack(spacing: 6) {
                TempoProgressBar(fraction: model.progress, exceeded: overrun > 0)
                Text(progressLabel)
                    .font(.callout)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// Progress toward the target rep count. Past the target the bar fills solid
/// and switches tint rather than clamping silently — going over is the good
/// outcome and should read as one.
private struct TempoProgressBar: View {
    let fraction: Double
    let exceeded: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                Capsule()
                    .fill(exceeded ? Color.green : Color.accentColor)
                    .frame(width: geo.size.width * min(1, max(0, fraction)))
            }
        }
        .frame(height: 10)
        .animation(.snappy, value: fraction)
    }
}
