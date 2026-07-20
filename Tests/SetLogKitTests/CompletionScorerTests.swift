import XCTest
@testable import SetLogKit

final class CompletionScorerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        CompletionSettings.resetToDefaults()
    }

    override func tearDown() {
        CompletionSettings.resetToDefaults()
        super.tearDown()
    }

    // MARK: Quality fractions

    func testTechniqueFractionIsRatingOverTen() {
        XCTAssertEqual(CompletionScorer.techniqueFraction(rpt: 10), 1.0)
        XCTAssertEqual(CompletionScorer.techniqueFraction(rpt: 8), 0.8)
        XCTAssertEqual(CompletionScorer.techniqueFraction(rpt: 4), 0.4)
        XCTAssertEqual(CompletionScorer.techniqueFraction(rpt: 0), 0.0)
    }

    func testTechniqueFractionIgnoresSettingsThreshold() {
        UserDefaults.standard.set(10, forKey: CompletionSettings.rptMinKey)
        XCTAssertEqual(CompletionScorer.techniqueFraction(rpt: 5), 0.5)
    }

    func testRomFractionClampsAtTarget() {
        // default romMin = 95
        XCTAssertEqual(CompletionScorer.romFraction(rom: 95), 1.0)
        XCTAssertEqual(CompletionScorer.romFraction(rom: 100), 1.0)
        XCTAssertEqual(CompletionScorer.romFraction(rom: 0), 0.0)
    }

    // MARK: Scores

    func testSetScoreIsQualityTimesHundred() {
        XCTAssertEqual(CompletionScorer.setScore(quality: 1.0), 100)
        XCTAssertEqual(CompletionScorer.setScore(quality: 0.5), 50)
        XCTAssertEqual(CompletionScorer.setScore(quality: 1.7), 100)  // clamped
        XCTAssertEqual(CompletionScorer.setScore(quality: -1), 0)     // clamped
    }

    func testWorkoutScoreScalesDepthByQuality() {
        // depth 2 of 4, full quality → 50%
        XCTAssertEqual(CompletionScorer.workoutScore(quality: 1.0, depth: 2, maxDepth: 4), 50)
        // top depth, full quality → 100%
        XCTAssertEqual(CompletionScorer.workoutScore(quality: 1.0, depth: 4, maxDepth: 4), 100)
        // banked depth scaled by this session's quality
        XCTAssertEqual(CompletionScorer.workoutScore(quality: 0.5, depth: 4, maxDepth: 4), 50)
    }

    func testWorkoutScoreNilWithoutMaxDepth() {
        XCTAssertNil(CompletionScorer.workoutScore(quality: 1.0, depth: 1, maxDepth: 0))
    }
}
