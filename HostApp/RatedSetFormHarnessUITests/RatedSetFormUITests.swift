//
//  RatedSetFormUITests.swift
//  RatedSetFormHarnessUITests
//
//  Drives SetLogKit's RatedSetForm directly (no consuming app in the way),
//  covering the weight-field regressions reported from kettlebell's
//  SetLogSheet: placeholder vs. real value, tap-and-type override without
//  erasing first, and keyboard dismissal.
//

import XCTest

final class RatedSetFormUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSaveEnabledOnLaunchViaSuggestedFallback() throws {
        // equipmentRequired + a suggestedPayload but no typed input yet:
        // Save must still be enabled (payload ?? suggestedPayload).
        let app = XCUIApplication()
        app.launch()

        let save = app.buttons["ratedSetForm.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertTrue(save.isEnabled)
    }

    @MainActor
    func testWeightFieldAcceptsDirectTypeWithoutErasing() throws {
        let app = XCUIApplication()
        app.launch()

        let weightField = app.textFields["ratedSetForm.weight"]
        XCTAssertTrue(weightField.waitForExistence(timeout: 5))

        weightField.tap()
        weightField.typeText("24")

        // A stale prefilled "16" would produce a mangled string like "2416"
        // or "1624" if typing inserted into existing digits instead of
        // starting clean.
        XCTAssertEqual(weightField.value as? String, "24")
    }

    @MainActor
    func testScrollDismissesKeyboard() throws {
        // No Done button by design (kettlebell feedback: don't add one to
        // decimalPad fields) — the Form itself must dismiss on drag.
        let app = XCUIApplication()
        app.launch()

        let weightField = app.textFields["ratedSetForm.weight"]
        XCTAssertTrue(weightField.waitForExistence(timeout: 5))
        weightField.tap()
        XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 5))

        app.swipeDown()

        XCTAssertFalse(app.keyboards.element.exists)
    }
}
