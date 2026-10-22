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

    func testPercentWithoutBodyweightIsAddedLoadOnly() {
        // 60 lb bench at 200 lb bodyweight = 30%
        XCTAssertEqual(WeightSetupEquipment.percentOfBodyweight(addedLbs: 60, bodyweightLbs: 200,
                                                                countsBodyweight: false), 30)
    }

    func testStepWithoutBodyweight() {
        // 30% → 31% of 200 lb = 62 lb; 30% → 29% = 58 lb
        XCTAssertEqual(WeightSetupEquipment.addedLoad(steppingPercent: 1, from: 60, bodyweightLbs: 200,
                                                      countsBodyweight: false), 62)
        XCTAssertEqual(WeightSetupEquipment.addedLoad(steppingPercent: -1, from: 60, bodyweightLbs: 200,
                                                      countsBodyweight: false), 58)
    }

    func testStepWithoutBodyweightNeverNegative() {
        XCTAssertEqual(WeightSetupEquipment.addedLoad(steppingPercent: -1, from: 0, bodyweightLbs: 200,
                                                      countsBodyweight: false), 0)
    }

    func testRepeatedTapsKeepClimbingWhenRoundingLandsBelowGrid() {
        // 41% of 197.4 lb = 80.934 → 80.9 lb, i.e. 40.98% — just under the grid.
        // The next +1 must reach 42%, not re-snap to 41% and stall.
        let bw = 197.4
        var added = WeightSetupEquipment.addedLoad(steppingPercent: 1, from: bw * 0.40, bodyweightLbs: bw,
                                                   countsBodyweight: false)
        XCTAssertEqual(added, 80.9)
        for expected in 42...300 {
            added = WeightSetupEquipment.addedLoad(steppingPercent: 1, from: added, bodyweightLbs: bw,
                                                   countsBodyweight: false)
            let pct = WeightSetupEquipment.percentOfBodyweight(addedLbs: added, bodyweightLbs: bw,
                                                               countsBodyweight: false)!
            XCTAssertEqual(pct, Double(expected), accuracy: 0.05)
        }
    }

    func testRepeatedDecrementsKeepFallingWhenRoundingLandsAboveGrid() {
        let bw = 197.4
        var added = 150.0
        var last = WeightSetupEquipment.percentOfBodyweight(addedLbs: added, bodyweightLbs: bw,
                                                            countsBodyweight: false)!
        for _ in 0..<70 {
            added = WeightSetupEquipment.addedLoad(steppingPercent: -1, from: added, bodyweightLbs: bw,
                                                   countsBodyweight: false)
            let pct = WeightSetupEquipment.percentOfBodyweight(addedLbs: added, bodyweightLbs: bw,
                                                               countsBodyweight: false)!
            XCTAssertLessThan(pct, last - 0.5)
            last = pct
        }
    }
}
