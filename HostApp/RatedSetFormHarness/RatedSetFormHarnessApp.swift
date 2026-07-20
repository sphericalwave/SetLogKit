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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
