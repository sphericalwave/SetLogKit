//
//  ContentView.swift
//  RatedSetFormHarness
//
//  Stub Skill + Equipment models, mirroring the doubles in
//  SetLogKitTests/RatedSetFormTests.swift but with a real interactive
//  input view (not EmptyView) so UI tests can exercise the weight field.
//

import SwiftUI
import SetLogKit
import EquipmentKit

struct HarnessSkill: RatedSetSkill {
    var displayName = "Front Lever"
    var familyName: String? = "Levers"
    var depth = 2
    var maxDepth = 4
    var priorSets: [PriorSet] = []
}

enum HarnessWeight: EquipmentModel {
    struct Payload: Codable, Equatable, Sendable {
        var kg: Double
    }

    static let equipmentID = "harnessweight"
    static let displayName = "Weight"
    static let inputTitle = "Weight"

    static func summary(_ p: Payload) -> String { "\(p.kg.formatted()) kg" }
    static func isValid(_ payload: Payload?) -> Bool { (payload?.kg ?? 0) > 0 }

    @MainActor
    static func inputView(payload: Binding<Payload?>, suggested: Payload?) -> HarnessWeightInput {
        HarnessWeightInput(payload: payload, suggested: suggested)
    }
}

struct HarnessWeightInput: View {
    @Binding var payload: HarnessWeight.Payload?
    let suggested: HarnessWeight.Payload?

    private var kg: Binding<Double?> {
        Binding(
            get: { payload?.kg },
            set: { payload = ($0 ?? 0) > 0 ? .init(kg: $0!) : nil }
        )
    }

    var body: some View {
        HStack {
            Text("Weight").font(.callout)
            Spacer()
            TextField(
                "kg",
                value: kg,
                format: .number,
                prompt: suggested.map { Text($0.kg.formatted()) }
            )
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 80)
                .accessibilityIdentifier("ratedSetForm.weight")
            Text("kg").font(.callout).foregroundStyle(.secondary)
        }
    }
}

struct ContentView: View {
    var body: some View {
        RatedSetForm(
            skill: HarnessSkill(),
            equipment: HarnessWeight.self,
            suggestedDecision: .repeat,
            suggestedPayload: HarnessWeight.Payload(kg: 16),
            config: RatedSetFormConfig(equipmentRequired: true),
            header: { Image(systemName: "figure.strengthtraining.traditional") },
            onSave: { _ in }
        )
    }
}
