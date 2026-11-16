//
//  PlanUITests.swift
//  FinAIUITests
//
//  Created by Tommy on 10.10.26.
//

import XCTest

final class PlanUITests: XCTestCase {
    @MainActor
    func testPlanWithLargeTextInDarkMode() {
        let previousAppearance = XCUIDevice.shared.appearance
        XCUIDevice.shared.appearance = .dark
        defer { XCUIDevice.shared.appearance = previousAppearance }
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Plan"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Plan"].tap()
        let goals = app.buttons[AccessibilityID.openGoals]
        for _ in 0..<5 where !goals.isHittable || goals.frame.maxY > app.tabBars.firstMatch.frame.minY { app.swipeUp() }
        XCTAssertTrue(goals.waitForExistence(timeout: 10))
        XCTAssertTrue(goals.isHittable)
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "Plan dark accessibility"
        image.lifetime = .keepAlways
        add(image)
        goals.tap()
        XCTAssertTrue(app.navigationBars["Savings goals"].waitForExistence(timeout: 10))
        let addGoal = app.buttons["Add goal"]
        for _ in 0..<5 where !addGoal.isHittable { app.swipeUp() }
        XCTAssertTrue(addGoal.isHittable)
    }

    @MainActor
    func testDirectAddDiscardAndReopenSavedGoalFromPlan() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Plan"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.tabBars.buttons.count, 3)
        app.tabBars.buttons["Plan"].tap()
        XCTAssertTrue(app.staticTexts["No savings goals yet."].waitForExistence(timeout: 10))
        app.buttons["Add to plan"].tap()
        app.buttons["Add goal"].tap()
        let name = app.textFields[AccessibilityID.goalName]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        name.tap()
        name.typeText("Laptop")
        app.buttons["Done"].tap()
        app.buttons["Close"].tap()
        app.alerts.buttons["Cancel"].tap()
        XCTAssertEqual(name.value as? String, "Laptop")
        let target = app.textFields[AccessibilityID.goalTarget]
        target.tap()
        target.typeText("1500")
        app.buttons["Done"].tap()
        app.buttons[AccessibilityID.saveGoal].tap()
        XCTAssertTrue(app.buttons["Edit goal"].waitForExistence(timeout: 10))
        app.buttons["Close"].tap()
        let saved = app.buttons.containing(.staticText, identifier: "Laptop").firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout: 10))
        saved.tap()
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        XCTAssertEqual(name.value as? String, "Laptop")
        XCTAssertEqual(target.value as? String, "1500")
    }
}
