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
}
