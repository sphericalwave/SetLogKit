//
//  WeightSetupEquipment.swift
//  SetLogKit
//
//  Shared EquipmentModel: added load (lbs), a free-text setup note (box
//  height, band, deficit), and an optional equipment angle (degrees).
//  Plugs into RatedSetForm. Payload is a transport only — host apps store
//  the fields on their own SetLog (no persistence opinion here).
//  `weightLbs` is signed: positive is added load, negative is assistance
//  (band/machine-assisted reps). `angleDeg` is signed: positive is incline,
//  negative is decline.
//

import SwiftUI
import EquipmentKit
import SwKeyboard

/// Context for the weight/angle input, injected by the host app's set-log
/// sheet. `bodyweightLoaded` shows a total-with-bodyweight readout and an
/// Added/Assist toggle for lifts where you hoist your own bodyweight.
/// `trackAngle` shows the Incline/Decline angle field for equipment where
/// angle matters (incline/decline bench press).
public struct WeightSetupContext: Equatable {
    public var bodyweightLoaded: Bool
    public var bodyweightLbs: Double
    public var trackAngle: Bool

    public init(bodyweightLoaded: Bool = false, bodyweightLbs: Double = 0, trackAngle: Bool = false) {
        self.bodyweightLoaded = bodyweightLoaded
        self.bodyweightLbs = bodyweightLbs
        self.trackAngle = trackAngle
    }
}

private struct WeightSetupContextKey: EnvironmentKey {
    static let defaultValue = WeightSetupContext()
}

public extension EnvironmentValues {
    var weightSetupContext: WeightSetupContext {
        get { self[WeightSetupContextKey.self] }
        set { self[WeightSetupContextKey.self] = newValue }
    }
}

public enum WeightSetupEquipment: EquipmentModel {
    // nonisolated: host app targets typically default to MainActor isolation,
    // which would make the Codable conformance main-actor-isolated and
    // unable to satisfy EquipmentModel.Payload's Sendable requirement.
    public nonisolated struct Payload: Codable, Equatable, Sendable {
        public var weightLbs: Double
        public var setupNotes: String
        public var angleDeg: Double

        public init(weightLbs: Double, setupNotes: String, angleDeg: Double = 0) {
            self.weightLbs = weightLbs
            self.setupNotes = setupNotes
            self.angleDeg = angleDeg
        }
    }

    public static let equipmentID = "weightsetup"
    public static let displayName = "Weight & setup"
    public static let inputTitle = "Weight"

    /// Human label for a signed added load: "assist 30 lb" when negative,
    /// "30 lb" when positive. Empty for zero.
    public static func loadLabel(_ lbs: Double) -> String {
        guard lbs != 0 else { return "" }
        let mag = abs(lbs).formatted(.number.precision(.fractionLength(0...2)))
        return lbs < 0 ? "assist \(mag) lb" : "\(mag) lb"
    }

    /// Human label for a signed equipment angle: "15° decline" when negative,
    /// "30° incline" when positive. Empty for flat (zero).
    public static func angleLabel(_ deg: Double) -> String {
        guard deg != 0 else { return "" }
        let mag = abs(deg).formatted(.number.precision(.fractionLength(0...1)))
        return deg < 0 ? "\(mag)° decline" : "\(mag)° incline"
    }

    public static func summary(_ p: Payload) -> String {
        var parts: [String] = []
        if p.weightLbs != 0 { parts.append(loadLabel(p.weightLbs)) }
        if p.angleDeg != 0 { parts.append(angleLabel(p.angleDeg)) }
        if !p.setupNotes.isEmpty { parts.append(p.setupNotes) }
        return parts.joined(separator: " · ")
    }

    @MainActor
    public static func inputView(payload: Binding<Payload?>, suggested: Payload?) -> WeightSetupInput {
        WeightSetupInput(payload: payload, suggested: suggested)
    }
}

public struct WeightSetupInput: View {
    @Binding var payload: WeightSetupEquipment.Payload?
    let suggested: WeightSetupEquipment.Payload?

    @Environment(\.weightSetupContext) private var weightContext
    /// Whether the entered magnitude counts as assistance (negative load).
    /// Held separately from the payload so the choice survives an empty field.
    @State private var assistMode = false
    /// Whether the entered angle magnitude counts as decline (negative).
    /// Held separately from the payload so the choice survives an empty field.
    @State private var declineMode = false
    @State private var didInit = false

    init(payload: Binding<WeightSetupEquipment.Payload?>, suggested: WeightSetupEquipment.Payload?) {
        self._payload = payload
        self.suggested = suggested
    }

    private var current: WeightSetupEquipment.Payload {
        payload ?? .init(weightLbs: 0, setupNotes: "")
    }
    private func update(_ transform: (inout WeightSetupEquipment.Payload) -> Void) {
        var p = current
        transform(&p)
        payload = (p.weightLbs != 0 || !p.setupNotes.isEmpty || p.angleDeg != 0) ? p : nil
    }

    /// The magnitude the user types; sign is applied from `assistMode`.
    private var magnitude: Binding<Double?> {
        Binding(get: { payload?.weightLbs.magnitudeNonZero },
                set: { newValue in
                    let mag = newValue ?? 0
                    update { $0.weightLbs = assistMode ? -mag : mag }
                })
    }
    /// The angle magnitude the user types; sign is applied from `declineMode`.
    private var angleMagnitude: Binding<Double?> {
        Binding(get: { payload?.angleDeg.magnitudeNonZero },
                set: { newValue in
                    let mag = newValue ?? 0
                    update { $0.angleDeg = declineMode ? -mag : mag }
                })
    }
    private var setup: Binding<String> {
        Binding(get: { payload?.setupNotes ?? "" },
                set: { newValue in update { $0.setupNotes = newValue } })
    }
    private var setupPlaceholder: String {
        let s = suggested?.setupNotes ?? ""
        return s.isEmpty ? "e.g. 12in box" : s
    }
    /// The last load logged for this skill, shown as the placeholder. Leaving
    /// the field empty saves exactly this value (RatedSetForm falls back to the
    /// suggested payload), so the placeholder is the real default, not a hint.
    private var weightPlaceholder: String {
        guard let last = suggested?.weightLbs.magnitudeNonZero else { return "lbs" }
        return last.formatted(.number.precision(.fractionLength(0...2)))
    }
    /// The last angle logged for this skill, shown as the placeholder — same
    /// "empty saves the placeholder value" behavior as `weightPlaceholder`.
    private var anglePlaceholder: String {
        guard let last = suggested?.angleDeg.magnitudeNonZero else { return "deg" }
        return last.formatted(.number.precision(.fractionLength(0...1)))
    }

    public var body: some View {
        if weightContext.bodyweightLoaded {
            Picker("Load", selection: $assistMode) {
                Text("Added").tag(false)
                Text("Assist").tag(true)
            }
            .pickerStyle(.segmented)
            .tint(.accentColor)
            .onChange(of: assistMode) { _, assist in
                let mag = abs(current.weightLbs)
                if mag != 0 { update { $0.weightLbs = assist ? -mag : mag } }
            }
        }

        weightRow

        if weightContext.bodyweightLoaded && weightContext.bodyweightLbs > 0 {
            totalRow
        }

        if weightContext.trackAngle {
            Picker("Angle", selection: $declineMode) {
                Text("Incline").tag(false)
                Text("Decline").tag(true)
            }
            .pickerStyle(.segmented)
            .tint(.accentColor)
            .onChange(of: declineMode) { _, decline in
                let mag = abs(current.angleDeg)
                if mag != 0 { update { $0.angleDeg = decline ? -mag : mag } }
            }

            angleRow
        }

        setupRow
    }

    private var weightRow: some View {
        HStack {
            Text("Weight").font(.callout)
            Spacer()
            TextField("lbs", value: magnitude, format: .number,
                      prompt: Text(weightPlaceholder))
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 80)
            Text("lb").foregroundStyle(.secondary)
            Button(action: { if let s = suggested?.weightLbs.magnitudeNonZero { magnitude.wrappedValue = s } }) {
                Image(systemName: "arrow.uturn.left").imageScale(.medium)
            }
            .buttonStyle(.borderless)
            .disabled(suggested?.weightLbs.magnitudeNonZero == nil)
        }
        .onAppear {
            guard !didInit else { return }
            didInit = true
            assistMode = (payload?.weightLbs ?? suggested?.weightLbs ?? 0) < 0
            declineMode = (payload?.angleDeg ?? suggested?.angleDeg ?? 0) < 0
        }
    }

    private var angleRow: some View {
        HStack {
            Text("Angle").font(.callout)
            Spacer()
            TextField("deg", value: angleMagnitude, format: .number,
                      prompt: Text(anglePlaceholder))
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 80)
            Text("°").foregroundStyle(.secondary)
            Button(action: { if let s = suggested?.angleDeg.magnitudeNonZero { angleMagnitude.wrappedValue = s } }) {
                Image(systemName: "arrow.uturn.left").imageScale(.medium)
            }
            .buttonStyle(.borderless)
            .disabled(suggested?.angleDeg.magnitudeNonZero == nil)
        }
    }

    private var totalRow: some View {
        let total = weightContext.bodyweightLbs + (payload?.weightLbs ?? 0)
        return HStack {
            Text("Total").font(.callout)
            Spacer()
            Text("\(total, format: .number.precision(.fractionLength(0...1))) lb")
                .foregroundStyle(.secondary)
        }
    }

    private var setupRow: some View {
        HStack {
            Text("Setup").font(.callout)
            Spacer()
            TextField("e.g. 12in box", text: setup, prompt: Text(setupPlaceholder))
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.secondary)
            Button(action: { if let s = suggested?.setupNotes, !s.isEmpty { update { $0.setupNotes = s } } }) {
                Image(systemName: "arrow.uturn.left").imageScale(.medium)
            }
            .buttonStyle(.borderless)
            .disabled((suggested?.setupNotes ?? "").isEmpty)
        }
    }
}

private extension Double {
    /// Absolute value, or nil when zero — for placeholder/reset off the
    /// magnitude while the sign is tracked separately.
    var magnitudeNonZero: Double? { self != 0 ? abs(self) : nil }
}
