import XCTest
@testable import SetLogKit

final class WeightProgressionTests: XCTestCase {

    func testNoStepReturnsLastUnchanged() {
        XCTAssertEqual(WeightProgression.nextWeight(last: 20, decision: .progress, stepLbs: nil), 20)
        XCTAssertEqual(WeightProgression.nextWeight(last: 20, decision: .progress, stepLbs: 0), 20)
    }

    func testProgressAddsStep() {
        XCTAssertEqual(WeightProgression.nextWeight(last: 20, decision: .progress, stepLbs: 2.5), 22.5)
    }

    func testRegressSubtractsStep() {
        XCTAssertEqual(WeightProgression.nextWeight(last: 20, decision: .regress, stepLbs: 2.5), 17.5)
    }

    func testRegressDoesNotGoNegative() {
        XCTAssertEqual(WeightProgression.nextWeight(last: 2, decision: .regress, stepLbs: 5), 0)
    }

    func testRepeatReturnsLastUnchanged() {
        XCTAssertEqual(WeightProgression.nextWeight(last: 20, decision: .repeat, stepLbs: 5), 20)
    }
}
