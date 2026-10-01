import XCTest
@testable import SetLogKit

final class BodyweightPercentTests: XCTestCase {

    func testPercentCountsBodyweight() {
        XCTAssertEqual(WeightSetupEquipment.percentOfBodyweight(addedLbs: 0, bodyweightLbs: 200), 100)
        XCTAssertEqual(WeightSetupEquipment.percentOfBodyweight(addedLbs: 200, bodyweightLbs: 200), 200)
        XCTAssertEqual(WeightSetupEquipment.percentOfBodyweight(addedLbs: -50, bodyweightLbs: 200), 75)
    }

    func testPercentNilWithoutBodyweight() {
        XCTAssertNil(WeightSetupEquipment.percentOfBodyweight(addedLbs: 20, bodyweightLbs: 0))
    }

    func testStepUpFromGrid() {
        // 150% → 155% of 200 lb = 310 total = 110 added
        XCTAssertEqual(WeightSetupEquipment.addedLoad(steppingPercent: 5, from: 100, bodyweightLbs: 200), 110)
    }

    func testStepDownFromGrid() {
        XCTAssertEqual(WeightSetupEquipment.addedLoad(steppingPercent: -5, from: 100, bodyweightLbs: 200), 90)
    }

    func testOffGridSnapsToNextMultiple() {
        // 153% steps up to 155%, down to 150%
        XCTAssertEqual(WeightSetupEquipment.addedLoad(steppingPercent: 5, from: 106, bodyweightLbs: 200), 110)
        XCTAssertEqual(WeightSetupEquipment.addedLoad(steppingPercent: -5, from: 106, bodyweightLbs: 200), 100)
    }

    func testOnePointStep() {
        // 150% → 151% of 200 lb = 2 lb more; 150.5% snaps to 151% / 150%
        XCTAssertEqual(WeightSetupEquipment.addedLoad(steppingPercent: 1, from: 100, bodyweightLbs: 200), 102)
        XCTAssertEqual(WeightSetupEquipment.addedLoad(steppingPercent: 1, from: 101, bodyweightLbs: 200), 102)
        XCTAssertEqual(WeightSetupEquipment.addedLoad(steppingPercent: -1, from: 101, bodyweightLbs: 200), 100)
    }

    func testCrossingBodyweightBecomesAssist() {
        // 100% → 95% of 200 lb = 10 lb assist
        XCTAssertEqual(WeightSetupEquipment.addedLoad(steppingPercent: -5, from: 0, bodyweightLbs: 200), -10)
    }

    func testStepToExactlyBodyweight() {
        XCTAssertEqual(WeightSetupEquipment.addedLoad(steppingPercent: -5, from: 10, bodyweightLbs: 200), 0)
    }

    func testNeverBelowZeroTotal() {
        XCTAssertEqual(WeightSetupEquipment.addedLoad(steppingPercent: -5, from: -200, bodyweightLbs: 200), -200)
    }

    func testRoundsToTenthPound() {
        // 100% → 105% of 183.3 lb = 9.165 added → 9.2
        XCTAssertEqual(WeightSetupEquipment.addedLoad(steppingPercent: 5, from: 0, bodyweightLbs: 183.3), 9.2)
    }

    func testNoBodyweightLeavesLoadUnchanged() {
        XCTAssertEqual(WeightSetupEquipment.addedLoad(steppingPercent: 5, from: 20, bodyweightLbs: 0), 20)
    }
}
