//
//  SetRecord.swift
//  SetLogKit
//
//  The read-only face a persisted set presents to SetLogKit's logic.
//  Host apps conform their own model class (SwiftData @Model, CoreData
//  NSManagedObject, plain struct) — SetLogKit has no persistence opinion.
//

import Foundation

public protocol SetRecord {
    var reps: Int { get }
    /// TED ratings, 1–10: technique / exertion / discomfort.
    var rpt: Int { get }
    var rpe: Int { get }
    var rpd: Int { get }
    var durationSec: Int { get }
    var loggedAt: Date { get }
}

public extension SetRecord {
    nonisolated var ratedSet: RatedSet { RatedSet(rpt: rpt, rpe: rpe, rpd: rpd, loggedAt: loggedAt) }
}
