//
//  BudgetsUITests.swift
//  FinAITests
//
//  Created by Tommy on 09.10.26.
//

import XCTest

final class BudgetsUITests: XCTestCase {
    @MainActor
    func testCreateEditReopenAndRejectDuplicateBudget() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let open = app.buttons[AccessibilityID.openBudgets]
        XCTAssertTrue(open.waitForExistence(timeout: 15))
        open.tap()
        let add = app.buttons["Add budget"]
        XCTAssertTrue(add.waitForExistence(timeout: 10))
        add.tap()
        let limit = app.textFields[AccessibilityID.budgetLimit]
        limit.tap()
        limit.typeText("500")
        app.buttons["Done"].tap()
        app.buttons[AccessibilityID.saveBudget].tap()
        let edit = app.buttons["Edit budget"]
        XCTAssertTrue(edit.waitForExistence(timeout: 10))
        if !edit.isHittable { app.swipeUp() }
        edit.tap()
        limit.tap()
        limit.typeText("0")
        app.buttons["Done"].tap()
        app.buttons[AccessibilityID.saveBudget].tap()
        XCTAssertTrue(edit.waitForExistence(timeout: 10))
        app.buttons["Close"].tap()
        open.tap()
        XCTAssertTrue(edit.waitForExistence(timeout: 10))
        if !edit.isHittable { app.swipeUp() }
        edit.tap()
        XCTAssertEqual(limit.value as? String, "5000")
        app.buttons["Cancel editing"].tap()
        if !add.isHittable { app.swipeDown() }
        add.tap()
        limit.tap()
        limit.typeText("100")
        app.buttons["Done"].tap()
        app.buttons[AccessibilityID.saveBudget].tap()
        XCTAssertTrue(app.staticTexts["A budget already exists for this category and currency. Edit that budget instead."].waitForExistence(timeout: 10))
        XCTAssertEqual(limit.value as? String, "100")
    }
}
