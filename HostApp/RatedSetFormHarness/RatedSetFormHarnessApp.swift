//
//  RatedSetFormHarnessApp.swift
//  RatedSetFormHarness
//
//  UI-test host app for SetLogKit's RatedSetForm. Presents the form directly
//  at launch against stub Skill/Equipment models so XCUITest can drive real
//  taps/typing against the shared framework, independent of any consuming
//  app (kettlebell, progYog, ...).
//

import SwiftUI

@main
struct RatedSetFormHarnessApp: App {
    init() {
        // The form carries the last saved tempo forward, and a fresh harness
        // has none — register 3-1-2-0 so the tempo row and the tempo coach are
        // there to try without picking a preset first.
        UserDefaults.standard.register(defaults: [
            "setLog.lastTempo.eccentric": 3,
            "setLog.lastTempo.bottomPause": 1,
            "setLog.lastTempo.concentric": 2,
            "setLog.lastTempo.topPause": 0,
        ])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
