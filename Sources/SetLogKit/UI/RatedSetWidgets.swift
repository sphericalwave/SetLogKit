//
//  RatedSetWidgets.swift
//  SetLogKit
//
//  The per-widget building blocks the logging form is assembled from. Public
//  so an app with a bespoke sheet (clubs' simpler layout, a future design)
//  can reuse individual pieces without adopting the whole `RatedSetForm`.
//

import SwiftUI

/// A labelled 1–10 TED stepper: value (color-coded) + stepper + optional
/// plain-language description underneath. `.plain` style hides the
/// description (clubs' simpler layout).
public struct TEDMetricStepper: View {
    public enum Style: Sendable { case described, plain }

    let label: String
    @Binding var value: Int
    let colorFor: (Int) -> Color
    let describe: (Int) -> String
    let style: Style

    public init(label: String, value: Binding<Int>,
                colorFor: @escaping (Int) -> Color,
                describe: @escaping (Int) -> String = { _ in "" },
                style: Style = .described) {
        self.label = label
        self._value = value
        self.colorFor = colorFor
        self.describe = describe
        self.style = style
    }

    public var body: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack(spacing: 4) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Text("\(value)").font(.caption).monospacedDigit()
                    .foregroundStyle(colorFor(value))
            }
            Stepper(value: $value, in: 1...10) { EmptyView() }
                .labelsHidden()
            if style == .described {
                Text(describe(value))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.vertical, 2)
    }
}

/// A stepper row for a whole-number metric (reps, slices) with an optional
/// info popover and trailing value + suffix.
public struct MetricStepperRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let suffix: String
    let info: String
    @State private var showInfo = false

    public init(label: String, value: Binding<Int>, range: ClosedRange<Int>,
                step: Int = 1, suffix: String = "", info: String = "") {
        self.label = label
        self._value = value
        self.range = range
        self.step = step
        self.suffix = suffix
        self.info = info
    }

    public var body: some View {
        Stepper(value: $value, in: range, step: step) {
            HStack(spacing: 8) {
                Text(label).font(.callout)
                if !info.isEmpty {
                    Button { showInfo = true } label: {
                        Image(systemName: "info.circle").imageScale(.medium)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(Color.accentColor)
                    .popover(isPresented: $showInfo) {
                        Text(info)
                            .font(.callout)
                            .padding(.horizontal, 20).padding(.vertical, 16)
                            .frame(maxWidth: 280)
                            .fixedSize(horizontal: false, vertical: true)
                            .presentationCompactAdaptation(.popover)
                    }
                }
                Spacer()
                Text("\(value)\(suffix)")
                    .monospacedDigit().font(.title3.bold())
                    .frame(minWidth: 44, alignment: .trailing)
            }
        }
    }
}

/// One heart-rate stat row: label, bpm, and % of max.
public struct HRStatRow: View {
    let label: String
    let bpm: Int
    let maxHR: Int

    public init(label: String, bpm: Int, maxHR: Int) {
        self.label = label
        self.bpm = bpm
        self.maxHR = maxHR
    }

    public var body: some View {
        HStack(spacing: 12) {
            Text(label).font(.callout)
            Spacer()
            Text("\(bpm) bpm").monospacedDigit().font(.title3.bold())
            Text("\(maxHR > 0 ? bpm * 100 / maxHR : 0)%")
                .monospacedDigit().font(.caption).foregroundStyle(.secondary)
                .frame(minWidth: 44, alignment: .trailing)
        }
    }
}
