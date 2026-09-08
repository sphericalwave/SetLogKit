import XCTest
@testable import SetLogKit

final class TempoScriptTests: XCTestCase {

    private func utterances(_ tempo: SetTempo,
                            names: TempoPhaseNames = .default,
                            rep: Int = 1) -> [String] {
        TempoScript.beats(for: tempo, names: names, rep: rep).map(\.utterance)
    }

    // MARK: The script

    func testFourOneTwoZeroSpeaksTheWholeRep() {
        let tempo = SetTempo(eccentric: 4, bottomPause: 1, concentric: 2, topPause: 0)
        XCTAssertEqual(
            utterances(tempo, rep: 3),
            ["rep three, lower", "two", "three", "four", "hold", "extend", "two"]
        )
    }

    func testBeatCountIsSecondsPerRep() {
        let tempo = SetTempo(eccentric: 4, bottomPause: 1, concentric: 2, topPause: 0)
        XCTAssertEqual(tempo.secondsPerRep, 7)
        XCTAssertEqual(TempoScript.beats(for: tempo, rep: 1).count, 7)
    }

    func testZeroCountPhasesAreSkippedEntirely() {
        let tempo = SetTempo(eccentric: 2, bottomPause: 0, concentric: 1, topPause: 0)
        let beats = TempoScript.beats(for: tempo, rep: 1)
        XCTAssertEqual(beats.map(\.phase), [.eccentric, .eccentric, .concentric])
        XCTAssertEqual(beats.map(\.utterance), ["rep one, lower", "two", "extend"])
    }

    func testAllZeroTempoProducesNoBeats() {
        let tempo = SetTempo(eccentric: 0, bottomPause: 0, concentric: 0, topPause: 0)
        XCTAssertTrue(tempo.isEmpty)
        XCTAssertTrue(TempoScript.beats(for: tempo, rep: 1).isEmpty)
    }

    func testRepPrefixOnlyLandsOnTheFirstBeatOfTheRep() {
        let tempo = SetTempo(eccentric: 0, bottomPause: 0, concentric: 2, topPause: 1)
        // The eccentric is skipped, so the concentric carries the announcement.
        XCTAssertEqual(utterances(tempo, rep: 5), ["rep five, extend", "two", "hold"])
    }

    func testPhaseIndexIsOneBasedWithinEachPhase() {
        let tempo = SetTempo(eccentric: 2, bottomPause: 2, concentric: 0, topPause: 0)
        XCTAssertEqual(TempoScript.beats(for: tempo, rep: 1).map(\.index), [1, 2, 1, 2])
    }

    func testCustomPhaseNamesSubstitute() {
        let names = TempoPhaseNames(eccentric: "descend", bottomPause: "pause",
                                    concentric: "press", topPause: "lock")
        let tempo = SetTempo(eccentric: 1, bottomPause: 1, concentric: 1, topPause: 1)
        XCTAssertEqual(utterances(tempo, names: names, rep: 2),
                       ["rep two, descend", "pause", "press", "lock"])
    }

    // MARK: Number words

    func testNumberWordsThroughTen() {
        XCTAssertEqual(TempoScript.word(1), "one")
        XCTAssertEqual(TempoScript.word(7), "seven")
        XCTAssertEqual(TempoScript.word(10), "ten")
    }

    func testNumbersPastTenFallBackToDigits() {
        XCTAssertEqual(TempoScript.word(11), "11")
        XCTAssertEqual(TempoScript.word(23), "23")
    }

    func testLongPhaseCountsPastTen() {
        let tempo = SetTempo(eccentric: 12, bottomPause: 0, concentric: 0, topPause: 0)
        XCTAssertEqual(utterances(tempo, rep: 1).last, "12")
    }

    // MARK: Tempo arithmetic

    func testNegativePhaseCountsClampToZero() {
        let tempo = SetTempo(eccentric: -3, bottomPause: 0, concentric: 2, topPause: 0)
        XCTAssertEqual(tempo.secondsPerRep, 2)
        XCTAssertEqual(utterances(tempo, rep: 1), ["rep one, extend", "two"])
    }
}
