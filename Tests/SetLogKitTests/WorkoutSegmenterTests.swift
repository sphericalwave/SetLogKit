import XCTest
@testable import SetLogKit

private struct StubSet: SetRecord {
    var reps = 10
    var rpt = 8
    var rpe = 6
    var rpd = 2
    var durationSec: Int
    var loggedAt: Date
}

final class WorkoutSegmenterTests: XCTestCase {

    private let cal = Calendar.current

    private func date(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int = 0) -> Date {
        cal.date(from: DateComponents(year: y, month: mo, day: d, hour: h, minute: mi))!
    }

    func testEmptyLogsYieldNoSegments() {
        XCTAssertTrue(WorkoutSegmenter.segments(of: [StubSet]()).isEmpty)
    }

    func testSingleDayIsOneSegment() {
        let logs = [
            StubSet(durationSec: 60, loggedAt: date(2026, 7, 1, 9, 1)),
            StubSet(durationSec: 60, loggedAt: date(2026, 7, 1, 9, 5)),
        ]
        let segs = WorkoutSegmenter.segments(of: logs)
        XCTAssertEqual(segs.count, 1)
        XCTAssertEqual(segs[0].setLogs.count, 2)
        XCTAssertEqual(segs[0].dayStart, cal.startOfDay(for: logs[0].loggedAt))
    }

    func testMidnightCrossingSplitsIntoTwoSegments() {
        let logs = [
            StubSet(durationSec: 60, loggedAt: date(2026, 7, 1, 23, 50)),
            StubSet(durationSec: 60, loggedAt: date(2026, 7, 2, 0, 10)),
        ]
        let segs = WorkoutSegmenter.segments(of: logs)
        XCTAssertEqual(segs.count, 2)
        XCTAssertEqual(segs[0].index, 0)
        XCTAssertEqual(segs[1].index, 1)
        XCTAssertNotEqual(segs[0].dayStart, segs[1].dayStart)
    }

    func testDurationIsSumOfSetDurationsNotWallClock() {
        // Two 60s sets an hour apart: active duration must be 120s, not 1h+.
        let first = date(2026, 7, 1, 9, 1)
        let logs = [
            StubSet(durationSec: 60, loggedAt: first),
            StubSet(durationSec: 60, loggedAt: date(2026, 7, 1, 10, 1)),
        ]
        let seg = WorkoutSegmenter.segments(of: logs)[0]
        // start = first.loggedAt - its duration
        XCTAssertEqual(seg.startedAt, first.addingTimeInterval(-60))
        XCTAssertEqual(seg.endedAt.timeIntervalSince(seg.startedAt), 120)
    }

    func testUnsortedInputIsSorted() {
        let logs = [
            StubSet(durationSec: 60, loggedAt: date(2026, 7, 1, 10, 0)),
            StubSet(durationSec: 60, loggedAt: date(2026, 7, 1, 9, 0)),
        ]
        let seg = WorkoutSegmenter.segments(of: logs)[0]
        XCTAssertEqual(seg.setLogs.map(\.loggedAt), seg.setLogs.map(\.loggedAt).sorted())
    }
}
