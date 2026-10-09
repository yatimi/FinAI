//
//  GoalsUITests.swift
//  FinAIUITests
//
//  Created by Tommy on 08.10.26.
//

import XCTest

final class GoalsUITests: XCTestCase {
    @MainActor
    func testCreateAndCorrectSavingsGoal() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let open = app.buttons[AccessibilityID.openGoals]
        XCTAssertTrue(open.waitForExistence(timeout: 15))
        open.tap()
        let addButton = app.buttons["Add goal"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 10))
        addButton.tap()
        app.textFields[AccessibilityID.goalName].tap()
        app.textFields[AccessibilityID.goalName].typeText("MacBook")
        app.textFields[AccessibilityID.goalTarget].tap()
        app.textFields[AccessibilityID.goalTarget].typeText("2500")
        app.buttons["Done"].tap()
        app.buttons[AccessibilityID.saveGoal].tap()
        XCTAssertTrue(app.staticTexts["MacBook"].waitForExistence(timeout: 10))
        let edit = app.buttons["Edit goal"]
        if !edit.isHittable { app.swipeUp() }
        edit.tap()
        let saved = app.textFields[AccessibilityID.goalSaved]
        saved.tap()
        saved.typeText("500")
        app.buttons["Done"].tap()
        app.buttons[AccessibilityID.saveGoal].tap()
        XCTAssertTrue(app.buttons["Edit goal"].waitForExistence(timeout: 10))
        app.buttons["Close"].tap()
        open.tap()
        XCTAssertTrue(app.staticTexts["MacBook"].waitForExistence(timeout: 10))
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "Savings goal"
        image.lifetime = .keepAlways
        add(image)
        if !app.buttons["Edit goal"].isHittable { app.swipeUp() }
        app.buttons["Edit goal"].tap()
        XCTAssertEqual(app.textFields[AccessibilityID.goalSaved].value as? String, "500")
    }
}
