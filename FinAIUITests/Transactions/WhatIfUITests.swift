//
//  WhatIfUITests.swift
//  FinAIUITests
//
//  Created by Tommy on 23.10.26.
//

import XCTest

final class WhatIfUITests: XCTestCase {
    @MainActor
    func testScenarioValidationResetAndUnchangedRecordedTransactions() throws {
        let appearance = XCUIDevice.shared.appearance
        XCUIDevice.shared.appearance = .light
        defer { XCUIDevice.shared.appearance = appearance }
        try exerciseScenario(largeText: false)
    }

    @MainActor
    func testScenarioWithAccessibilityTextInDarkMode() throws {
        let appearance = XCUIDevice.shared.appearance
        XCUIDevice.shared.appearance = .dark
        defer { XCUIDevice.shared.appearance = appearance }
        try exerciseScenario(largeText: true)
    }

    @MainActor
    private func exerciseScenario(largeText: Bool) throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        if largeText {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launchEnvironment["FINAI_TEST_CSV"] = """
            date,description,amount,currency,type
            2026-08-01,Synthetic income,2000.00,EUR,income
            2026-08-10,Synthetic groceries,-310.00,EUR,expense
            2026-09-02,Synthetic groceries,-50.00,EUR,expense
            2026-09-03,Synthetic refund,10.00,EUR,refund
            """
        app.launch()
        XCTAssertTrue(app.navigationBars["Import transactions"].waitForExistence(timeout: 15))
        let account = app.textFields[AccessibilityID.importAccountName]
        for _ in 0..<12 where !account.isHittable { app.swipeUp() }
        account.tap()
        account.typeText("Synthetic account\n")
        let preview = app.buttons[AccessibilityID.previewImport]
        for _ in 0..<12 where !preview.isHittable { app.swipeUp() }
        preview.tap()
        XCTAssertTrue(app.navigationBars["Review import"].waitForExistence(timeout: 10))
        app.buttons[AccessibilityID.confirmSelectedImport].tap()
        app.alerts.buttons["Confirm import"].tap()
        XCTAssertTrue(app.collectionViews[AccessibilityID.transactionList].waitForExistence(timeout: 10))
        app.tabBars.buttons["Plan"].tap()
        app.buttons[AccessibilityID.openMonthForecast].tap()
        XCTAssertTrue(app.buttons[AccessibilityID.openWhatIf].waitForExistence(timeout: 10))
        app.buttons[AccessibilityID.openWhatIf].tap()
        let amount = app.textFields[AccessibilityID.whatIfAmount]
        for _ in 0..<12 where !amount.isHittable { app.swipeUp() }
        XCTAssertTrue(amount.waitForExistence(timeout: 10))
        amount.tap()
        amount.typeText("500")
        let keyboardDone = app.buttons[AccessibilityID.whatIfKeyboardDone]
        XCTAssertTrue(keyboardDone.waitForExistence(timeout: 5))
        keyboardDone.tap()
        let calculate = app.buttons[AccessibilityID.whatIfCalculate]
        for _ in 0..<12 where !calculate.isHittable { app.swipeUp() }
        calculate.tap()
        let flow = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@",
                                                       "Scenario net flow", "1,420.00")).firstMatch
        for _ in 0..<16 where !flow.isHittable || flow.frame.maxY > app.frame.maxY - 40 { app.swipeUp() }
        XCTAssertTrue(flow.exists)
        XCTAssertTrue(flow.isHittable)
        XCTAssertLessThanOrEqual(flow.frame.maxY, app.frame.maxY - 40)
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = largeText ? "What-if-dark-accessibility" : "What-if-light"
        image.lifetime = .keepAlways
        add(image)
        let reset = app.buttons[AccessibilityID.whatIfReset]
        for _ in 0..<16 where !reset.isHittable { app.swipeDown() }
        reset.tap()
        for _ in 0..<8 where !amount.isHittable { app.swipeDown() }
        XCTAssertEqual(amount.value as? String, "Scenario amount")
        if !largeText {
            app.buttons[AccessibilityID.whatIfChange].tap()
            app.buttons["Reduce expected expenses"].tap()
            amount.tap()
            amount.typeText("1000")
            keyboardDone.tap()
            calculate.tap()
            XCTAssertTrue(app.staticTexts[AccessibilityID.whatIfError].waitForExistence(timeout: 5))
            reset.tap()
        }
        app.navigationBars["What if?"].buttons.firstMatch.tap()
        app.navigationBars["Month-end forecast"].buttons["Done"].tap()
        app.tabBars.buttons["Transactions"].tap()
        let recorded = app.collectionViews[AccessibilityID.transactionList].buttons.matching(
            NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "Synthetic groceries", "€50.00")).firstMatch
        for _ in 0..<12 where !recorded.isHittable { app.swipeUp() }
        XCTAssertTrue(recorded.exists)
    }
}
