import XCTest
@testable import SetLogKit

final class VsLastSetTests: XCTestCase {

    func testIncreaseOnAddedLoad() throws {
        let pct = try XCTUnwrap(WeightSetupEquipment.percentChange(fromLbs: 100, toLbs: 103.2, bodyweightLbs: 200))
        XCTAssertEqual(pct, 3.2, accuracy: 1e-9)
        XCTAssertEqual(WeightSetupEquipment.changeLabel(pct), "+3.2% vs last")
    }

    func testDecrease() throws {
        let pct = try XCTUnwrap(WeightSetupEquipment.percentChange(fromLbs: 100, toLbs: 98.5, bodyweightLbs: 0))
        XCTAssertEqual(pct, -1.5, accuracy: 1e-9)
        XCTAssertEqual(WeightSetupEquipment.changeLabel(pct), "−1.5% vs last")
    }

    func testNoChange() {
        XCTAssertEqual(WeightSetupEquipment.percentChange(fromLbs: 100, toLbs: 100, bodyweightLbs: 0), 0)
        XCTAssertEqual(WeightSetupEquipment.changeLabel(0), "0% vs last")
        // Rounds to zero → reads as no change, no sign.
        XCTAssertEqual(WeightSetupEquipment.changeLabel(0.04), "0% vs last")
        XCTAssertEqual(WeightSetupEquipment.changeLabel(-0.04), "0% vs last")
    }

    func testNilWithoutPreviousLoad() {
        XCTAssertNil(WeightSetupEquipment.percentChange(fromLbs: 0, toLbs: 20, bodyweightLbs: 200))
        XCTAssertNil(WeightSetupEquipment.percentChange(fromLbs: -10, toLbs: 20, bodyweightLbs: 200))
    }

    func testBodyweightLiftComparesTotal() throws {
        // 200 + 20 → 200 + 42 = 220 → 242 = +10%
        let pct = try XCTUnwrap(WeightSetupEquipment.percentChange(fromLbs: 20, toLbs: 42, bodyweightLbs: 200,
                                                                   countsBodyweight: true))
        XCTAssertEqual(pct, 10, accuracy: 1e-9)
    }

    func testBodyweightLiftFromZeroAddedLoad() throws {
        // Bodyweight only → 10 lb added at 200 lb = +5%, not undefined.
        let pct = try XCTUnwrap(WeightSetupEquipment.percentChange(fromLbs: 0, toLbs: 10, bodyweightLbs: 200,
                                                                   countsBodyweight: true))
        XCTAssertEqual(pct, 5, accuracy: 1e-9)
    }

    func testBodyweightLiftAssistReduced() throws {
        // assist 40 → assist 20 at 200 lb: 160 → 180 = +12.5%
        let pct = try XCTUnwrap(WeightSetupEquipment.percentChange(fromLbs: -40, toLbs: -20, bodyweightLbs: 200,
                                                                   countsBodyweight: true))
        XCTAssertEqual(pct, 12.5, accuracy: 1e-9)
    }

    func testBodyweightLiftUsesPreviousSetsBodyweight() throws {
        // Last set at 190 lb bodyweight, now 200, same added load: 190 → 200
        let pct = try XCTUnwrap(WeightSetupEquipment.percentChange(fromLbs: 0, toLbs: 0, bodyweightLbs: 200,
                                                                   previousBodyweightLbs: 190,
                                                                   countsBodyweight: true))
        XCTAssertEqual(pct, 10 / 190 * 100, accuracy: 1e-9)
    }

    func testContextDefaultsToNoPreviousSet() {
        XCTAssertNil(WeightSetupContext().previousSet)
        let ctx = WeightSetupContext(previousSet: .init(weightLbs: 100, reps: 8))
        XCTAssertEqual(ctx.previousSet, WeightSetupPreviousSet(weightLbs: 100, reps: 8, bodyweightLbs: 0))
    }

    // MARK: - Compounding

    func testCompoundsAddedLoad() {
        let lbs = WeightSetupEquipment.compounded(addedLbs: 7.25, percent: 3.6, times: 3, bodyweightLbs: 197)
        XCTAssertEqual(lbs, 7.25 * pow(1.036, 3), accuracy: 1e-9)
        XCTAssertEqual(WeightSetupEquipment.compoundLabel(addedLbs: 7.25, percent: 3.6, bodyweightLbs: 197),
                       "+3.6%/set → 8.1 · 9 · 10 lb in 3 · 6 · 9 sets")
    }

    func testCompoundLabelAtWholeRate() {
        // 70 lb at +2%/set: 74.3, 78.8, 83.7.
        XCTAssertEqual(WeightSetupEquipment.compoundLabel(addedLbs: 70, percent: 2, bodyweightLbs: 197),
                       "+2%/set → 74.3 · 78.8 · 83.7 lb in 3 · 6 · 9 sets")
    }

    func testBodyweightLiftCompoundsTotalButReportsAdded() {
        // 200 total → +10% twice = 242 total = 42 added.
        let lbs = WeightSetupEquipment.compounded(addedLbs: 0, percent: 10, times: 2,
                                                  bodyweightLbs: 200, countsBodyweight: true)
        XCTAssertEqual(lbs, 42, accuracy: 1e-9)
    }

    func testCompoundsADecrease() {
        let lbs = WeightSetupEquipment.compounded(addedLbs: 100, percent: -10, times: 2, bodyweightLbs: 0)
        XCTAssertEqual(lbs, 81, accuracy: 1e-9)
    }
}
