//
//  PrivacyUITests.swift
//  FinAIUITests
//
//  Created by Tommy on 31.10.26.
//

import XCTest

final class PrivacyUITests: XCTestCase {
    @MainActor
    func testForegroundRestoresPresentedEditorAndUnsavedInput() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Plan"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Plan"].tap()
        app.buttons["Add to plan"].tap()
        app.buttons["Add goal"].tap()
        let name = app.textFields[AccessibilityID.goalName]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        name.tap(); name.typeText("Synthetic private goal")
        app.buttons["Done"].tap()
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        XCTAssertEqual(name.value as? String, "Synthetic private goal")
        XCTAssertTrue(name.isHittable)
        app.buttons["Close"].tap()
        XCTAssertTrue(app.alerts.buttons["Discard changes"].waitForExistence(timeout: 10))
        app.alerts.buttons["Discard changes"].tap()
        XCTAssertTrue(app.buttons[AccessibilityID.openGoals].waitForExistence(timeout: 10))
    }
}
