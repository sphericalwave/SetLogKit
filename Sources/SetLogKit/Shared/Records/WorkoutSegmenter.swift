//
//  WorkoutSegmenter.swift
//  SetLogKit
//
//  One calendar-day's worth of work within a session. Shared by both the
//  calendar and health bridges — no EventKit or HealthKit dependency.
//

import Foundation

/// One calendar-day's worth of work. Derived by grouping `loggedAt` per
/// local-TZ day. `dayStart` is the local midnight that keys the segment;
/// `index` is chronological day order within the session.
public struct WorkoutSegment<Log: SetRecord> {
    public let index: Int
    public let dayStart: Date
    public let startedAt: Date
    public let endedAt: Date
    public let setLogs: [Log]
}

public enum WorkoutSegmenter {
    /// Group sets by `Calendar.current.startOfDay(for: loggedAt)` so the
    /// calendar shows exactly one timed bar per workout per day, even when
    /// the work spans many hours. A session that physically crosses midnight
    /// produces two segments (one per day).
    public nonisolated static func segments<Log: SetRecord>(of logs: [Log]) -> [WorkoutSegment<Log>] {
        let logs = logs.sorted { $0.loggedAt < $1.loggedAt }
        guard !logs.isEmpty else { return [] }

        let cal = Calendar.current
        var buckets: [(day: Date, logs: [Log])] = []
        for log in logs {
            let day = cal.startOfDay(for: log.loggedAt)
            if buckets.last?.day == day {
                buckets[buckets.count - 1].logs.append(log)
            } else {
                buckets.append((day, [log]))
            }
        }

        return buckets.enumerated().map { idx, b in
            let first = b.logs.first!
            let start = first.loggedAt.addingTimeInterval(-TimeInterval(first.durationSec))
            // Sum of set durations (not wall-clock) so rest between sets doesn't
            // inflate workout minutes in Health/Calendar.
            let activeDuration = b.logs.reduce(0) { $0 + TimeInterval($1.durationSec) }
            let end = start.addingTimeInterval(max(activeDuration, 1))
            return WorkoutSegment(index: idx, dayStart: b.day,
                                  startedAt: start, endedAt: end,
                                  setLogs: b.logs)
        }
    }
}
