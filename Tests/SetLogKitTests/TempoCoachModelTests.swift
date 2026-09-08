import XCTest
@testable import SetLogKit

@MainActor
final class FakeTempoVoice: TempoVoice {
    var prepared = 0
    var spoken: [String] = []
    var stops = 0
    var targetReached = 0
    var terminals = 0

    func prepare() { prepared += 1 }
    func say(_ text: String) { spoken.append(text) }
    func stopSpeaking() { stops += 1 }
    func playTargetReached() { targetReached += 1 }
    func playTerminal() { terminals += 1 }
}

@MainActor
final class TempoCoachModelTests: XCTestCase {

    /// One beat per 5ms so a whole set runs inside a test.
    private func makeCoach(tempo: SetTempo = SetTempo(eccentric: 1, bottomPause: 0,
                                                      concentric: 1, topPause: 0),
                           targetReps: Int = 3,
                           voice: FakeTempoVoice) -> TempoCoachModel {
        TempoCoachModel(tempo: tempo, targetReps: targetReps,
                        voice: voice, beatDuration: .milliseconds(5))
    }

    private func wait(upTo timeout: Duration = .seconds(5),
                      until condition: () -> Bool) async throws {
        let deadline = ContinuousClock().now.advanced(by: timeout)
        while !condition() {
            if ContinuousClock().now > deadline {
                XCTFail("timed out waiting for condition")
                return
            }
            try await Task.sleep(for: .milliseconds(1))
        }
    }

    // MARK: Rep accounting

    func testCountsCompletedReps() async throws {
        let voice = FakeTempoVoice()
        let coach = makeCoach(voice: voice)
        coach.start()
        try await wait { coach.completedReps >= 3 }
        coach.stop()
        XCTAssertGreaterThanOrEqual(coach.completedReps, 3)
    }

    func testStoppingMidRepDoesNotCountThatRep() async throws {
        let voice = FakeTempoVoice()
        let coach = makeCoach(tempo: SetTempo(eccentric: 4, bottomPause: 0,
                                              concentric: 4, topPause: 0),
                              voice: voice)
        coach.start()
        try await wait { voice.spoken.count >= 2 }   // two beats into an eight-beat rep
        coach.stop()
        XCTAssertEqual(coach.completedReps, 0)
        XCTAssertEqual(coach.currentRep, 1)
    }

    func testOverrunKeepsCountingPastTarget() async throws {
        let voice = FakeTempoVoice()
        let coach = makeCoach(targetReps: 2, voice: voice)
        coach.start()
        try await wait { coach.completedReps >= 5 }
        XCTAssertTrue(coach.isRunning)
        XCTAssertGreaterThan(coach.progress, 1.0)
        coach.stop()
    }

    func testTargetReachedCueFiresOnceAtTarget() async throws {
        let voice = FakeTempoVoice()
        let coach = makeCoach(targetReps: 2, voice: voice)
        coach.start()
        try await wait { coach.completedReps >= 5 }
        coach.stop()
        XCTAssertEqual(voice.targetReached, 1)
    }

    // MARK: Lifecycle

    func testStartPreparesAudioAndStopPlaysTerminal() async throws {
        let voice = FakeTempoVoice()
        let coach = makeCoach(voice: voice)
        coach.start()
        XCTAssertEqual(voice.prepared, 1)
        try await wait { coach.completedReps >= 1 }
        coach.stop()
        XCTAssertEqual(voice.terminals, 1)
        XCTAssertFalse(coach.isRunning)
    }

    func testStopWithoutStartPlaysNoTerminal() {
        let voice = FakeTempoVoice()
        let coach = makeCoach(voice: voice)
        coach.stop()
        XCTAssertEqual(voice.terminals, 0)
    }

    func testEmptyTempoNeverStarts() {
        let voice = FakeTempoVoice()
        let coach = makeCoach(tempo: SetTempo(eccentric: 0, bottomPause: 0,
                                              concentric: 0, topPause: 0),
                              voice: voice)
        XCTAssertFalse(coach.isAvailable)
        coach.start()
        XCTAssertFalse(coach.isRunning)
        XCTAssertEqual(voice.spoken, [])
    }

    func testPauseStopsSpeakingAndResumeContinuesTheSameRep() async throws {
        let voice = FakeTempoVoice()
        let coach = makeCoach(tempo: SetTempo(eccentric: 6, bottomPause: 0,
                                              concentric: 0, topPause: 0),
                              voice: voice)
        coach.start()
        try await wait { voice.spoken.count >= 2 }
        coach.pause()
        XCTAssertTrue(coach.isPaused)
        let atPause = voice.spoken.count

        try await Task.sleep(for: .milliseconds(30))
        XCTAssertEqual(voice.spoken.count, atPause, "no beats while paused")

        coach.resume()
        try await wait { coach.completedReps >= 1 }
        XCTAssertFalse(coach.isPaused)
        coach.stop()
    }

    // MARK: Speech

    func testSpeaksTheScriptedBeats() async throws {
        let voice = FakeTempoVoice()
        let coach = makeCoach(tempo: SetTempo(eccentric: 2, bottomPause: 1,
                                              concentric: 1, topPause: 0),
                              voice: voice)
        coach.start()
        try await wait { coach.completedReps >= 2 }
        coach.stop()
        XCTAssertEqual(Array(voice.spoken.prefix(8)),
                       ["rep one, lower", "two", "hold", "extend",
                        "rep two, lower", "two", "hold", "extend"])
    }
}
