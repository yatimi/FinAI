//
//  SpendingAnalyticsUITests.swift
//  FinAI
//
//  Created by Tommy on 28.09.26.
//

import XCTest

final class SpendingAnalyticsUITests: XCTestCase {
    @MainActor
    func testPreviousMonthOnlyCurrencyHasEmptyStateAndZeroNetActivityKeepsBreakdowns() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["FINAI_TEST_CSV"] = "date,description,amount,currency,type\n2026-08-01,Previous USD purchase,-120,USD,expense\n2026-09-01,Current EUR purchase,-10,EUR,expense\n2026-09-02,Current EUR purchase,10,EUR,refund"
        app.launch()
        let account = app.textFields[AccessibilityID.importAccountName]
        XCTAssertTrue(account.waitForExistence(timeout: 15))
        account.tap()
        account.typeText("Test bank")
        app.keyboards.buttons["Done"].tap()
        let preview = app.buttons[AccessibilityID.previewImport]
        for _ in 0..<8 where !preview.isHittable { app.swipeUp() }
        XCTAssertTrue(preview.isHittable)
        preview.tap()
        XCTAssertTrue(app.navigationBars["Review import"].waitForExistence(timeout: 10))
        app.buttons[AccessibilityID.confirmSelectedImport].tap()
        app.alerts.buttons["Confirm import"].tap()
        XCTAssertTrue(app.navigationBars["Transactions"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Analytics"].tap()
        let list = app.collectionViews[AccessibilityID.spendingAnalytics]
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        let categories = app.staticTexts["By category · EUR"]
        for _ in 0..<8 where !categories.isHittable { list.swipeUp() }
        XCTAssertTrue(categories.isHittable)
        let merchants = app.staticTexts["By merchant · EUR"]
        for _ in 0..<8 where !merchants.isHittable { list.swipeUp() }
        XCTAssertTrue(merchants.isHittable)
        XCTAssertTrue(app.staticTexts["Current EUR purchase"].exists)
        let empty = app.staticTexts["No expenses or refunds in USD this month."]
        for _ in 0..<8 where !empty.isHittable { list.swipeUp() }
        XCTAssertTrue(empty.isHittable)
        XCTAssertTrue(app.staticTexts["Previous month net spending"].exists)
        XCTAssertFalse(app.staticTexts["By category · USD"].exists)
        XCTAssertFalse(app.staticTexts["By merchant · USD"].exists)
        XCTAssertFalse(app.staticTexts["No expenses or refunds in EUR this month."].exists)
    }

    @MainActor
    func testEmptyThenDemoAnalytics() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.buttons[AccessibilityID.loadDemo].waitForExistence(timeout: 15))
        app.tabBars.buttons["Analytics"].tap()
        XCTAssertTrue(app.staticTexts["No expenses or refunds in these two months."].waitForExistence(timeout: 5))
        app.tabBars.buttons["Overview"].tap()
        app.buttons[AccessibilityID.loadDemo].tap()
        app.alerts.buttons["Load demo data"].tap()
        XCTAssertTrue(app.staticTexts["Demo data · stored on this device"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Analytics"].tap()
        XCTAssertTrue(app.staticTexts["Current month net spending"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Previous month net spending"].exists)
        let list = app.collectionViews[AccessibilityID.spendingAnalytics]
        let categories = app.staticTexts["By category · EUR"]
        for _ in 0..<6 where !categories.isHittable { list.swipeUp() }
        XCTAssertTrue(categories.isHittable)
        let merchants = app.staticTexts["By merchant · EUR"]
        for _ in 0..<15 where !merchants.isHittable { list.swipeUp() }
        XCTAssertTrue(merchants.isHittable)
    }
}
