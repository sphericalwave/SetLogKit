import XCTest
@testable import SetLogKit

final class ProgressionEvaluatorTests: XCTestCase {

    private let evaluator = ProgressionEvaluator()

    private func rated(rpt: Int, rpe: Int = 7, rpd: Int = 2) -> RatedSet {
        RatedSet(rpt: rpt, rpe: rpe, rpd: rpd, loggedAt: Date())
    }

    func testFewerThanThreeSetsRepeats() {
        XCTAssertEqual(evaluator.suggest(from: []), .repeat)
        XCTAssertEqual(evaluator.suggest(from: [rated(rpt: 10), rated(rpt: 10)]), .repeat)
    }

    func testThreeQualifyingSetsProgress() {
        let sets = [rated(rpt: 8, rpe: 6, rpd: 3), rated(rpt: 9, rpe: 7, rpd: 1), rated(rpt: 10, rpe: 8, rpd: 0)]
        XCTAssertEqual(evaluator.suggest(from: sets), .progress)
    }

    func testOneBelowThresholdBlocksProgress() {
        let sets = [rated(rpt: 8), rated(rpt: 7), rated(rpt: 9)]  // middle rpt < 8
        XCTAssertEqual(evaluator.suggest(from: sets), .repeat)
    }

    func testHighDiscomfortRegresses() {
        let sets = [rated(rpt: 8), rated(rpt: 8, rpd: 7), rated(rpt: 8)]
        XCTAssertEqual(evaluator.suggest(from: sets), .regress)
    }

    func testVeryLowTechniqueRegresses() {
        let sets = [rated(rpt: 8), rated(rpt: 4), rated(rpt: 8)]
        XCTAssertEqual(evaluator.suggest(from: sets), .regress)
    }

    func testOnlyLastThreeSetsCount() {
        // A regress-worthy old set outside the window must not matter.
        let sets = [rated(rpt: 2), rated(rpt: 8, rpe: 6, rpd: 3), rated(rpt: 9, rpe: 7, rpd: 1), rated(rpt: 10, rpe: 8, rpd: 0)]
        XCTAssertEqual(evaluator.suggest(from: sets), .progress)
    }

    func testLowExertionBlocksProgressButDoesNotRegress() {
        let sets = [rated(rpt: 8, rpe: 5), rated(rpt: 9, rpe: 5), rated(rpt: 9, rpe: 5)]
        XCTAssertEqual(evaluator.suggest(from: sets), .repeat)
    }
}
