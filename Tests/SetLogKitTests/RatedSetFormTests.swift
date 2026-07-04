import XCTest
import SwiftUI
import EquipmentKit
@testable import SetLogKit

private struct StubSkill: RatedSetSkill {
    var displayName = "Front Lever"
    var familyName: String? = "Levers"
    var depth = 2
    var maxDepth = 4
    var priorSets: [PriorSet] = []
    var defaultSliceCount = 0
}

private enum StubWeight: EquipmentModel {
    struct Payload: Codable, Equatable, Sendable { var kg: Double }
    static let equipmentID = "stubweight"
    static let displayName = "Weight"
    static let inputTitle = "Weight"
    static func summary(_ p: Payload) -> String { "\(p.kg) kg" }
    static func isValid(_ payload: Payload?) -> Bool { (payload?.kg ?? 0) > 0 }
    @MainActor
    static func inputView(payload: Binding<Payload?>, suggested: Payload?) -> EmptyView { EmptyView() }
}

final class TEDDescriptionTests: XCTestCase {
    func testTechniqueBands() {
        XCTAssertEqual(TEDDescription.technique(1), "very sloppy form")
        XCTAssertEqual(TEDDescription.technique(6), "adequate form")
        XCTAssertEqual(TEDDescription.technique(10), "extremely good form")
    }
    func testExertionAndDiscomfortEndpoints() {
        XCTAssertEqual(TEDDescription.exertion(1), "very easy")
        XCTAssertEqual(TEDDescription.exertion(10), "extremely difficult")
        XCTAssertEqual(TEDDescription.discomfort(1), "no discomfort")
        XCTAssertEqual(TEDDescription.discomfort(10), "extremely painful")
    }
}

final class HRConfigTests: XCTestCase {
    func testEffectiveMaxUsesEstimateWhenNoOverride() {
        XCTAssertEqual(HRConfig.effectiveMax(age: 30, manualOverride: 0), 190)
    }
    func testEffectiveMaxHonorsOverride() {
        XCTAssertEqual(HRConfig.effectiveMax(age: 30, manualOverride: 175), 175)
    }
    func testEffectiveMaxNeverBelowOne() {
        XCTAssertEqual(HRConfig.effectiveMax(age: 500, manualOverride: 0), 1)
    }
}

final class RatedSetFormCompositionTests: XCTestCase {

    // The real risk in Option A was whether the 3-generic form (Skill +
    // EquipmentModel-with-associatedtypes + Header) composes at call sites.
    // These are type-level smoke tests: if they compile, the generics work.

    @MainActor
    func testComposesWithRealEquipment() {
        _ = RatedSetForm(
            skill: StubSkill(),
            equipment: StubWeight.self,
            suggestedDecision: .repeat,
            config: .init(equipmentRequired: true),
            header: { Image(systemName: "figure.strengthtraining.traditional") },
            onSave: { (_: RatedSetEntry<StubWeight.Payload>) in }
        )
    }

    @MainActor
    func testComposesWithNoEquipment() {
        _ = RatedSetForm(
            skill: StubSkill(),
            equipment: NoEquipment.self,
            suggestedDecision: .progress,
            config: .init(showsIsometric: true, showsSlices: true, tedStyle: .plain),
            header: { EmptyView() },
            onSave: { (_: RatedSetEntry<NoEquipment.Payload>) in }
        )
    }

    func testConfigDefaults() {
        let c = RatedSetFormConfig()
        XCTAssertTrue(c.showsIsometric)
        XCTAssertTrue(c.showsSlices)
        XCTAssertTrue(c.showsDecision)
        XCTAssertFalse(c.equipmentRequired)
        XCTAssertEqual(c.tedStyle, .described)
    }

    func testEntryCarriesEquipmentPayload() {
        let entry = RatedSetEntry(reps: 8, rpt: 9, rpe: 6, rpd: 1, notes: "n",
                                  decision: .progress, isometric: false, sliceCount: 0,
                                  payload: StubWeight.Payload(kg: 16))
        XCTAssertEqual(entry.payload?.kg, 16)
        XCTAssertEqual(entry.decision, .progress)
    }
}
