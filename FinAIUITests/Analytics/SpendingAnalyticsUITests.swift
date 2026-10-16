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
        app.tabBars.buttons["Home"].tap()
        app.buttons["Analytics"].tap()
        let list = app.collectionViews[AccessibilityID.spendingAnalytics]
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        let categories = app.staticTexts["By category · EUR"]
        for _ in 0..<8 where !categories.isHittable { list.swipeUp() }
        XCTAssertTrue(categories.isHittable)
        let merchants = app.staticTexts["By merchant · EUR"]
        for _ in 0..<8 where !merchants.isHittable { list.swipeUp() }
        XCTAssertTrue(merchants.isHittable)
        XCTAssertTrue(app.staticTexts["Current EUR purchase"].exists)
        let empty = app.staticTexts["No expenses or refunds in USD in the selected month."]
        for _ in 0..<8 where !empty.isHittable { list.swipeUp() }
        XCTAssertTrue(empty.isHittable)
        XCTAssertTrue(app.staticTexts["Previous month net spending"].exists)
        XCTAssertFalse(app.staticTexts["By category · USD"].exists)
        XCTAssertFalse(app.staticTexts["By merchant · USD"].exists)
        XCTAssertFalse(app.staticTexts["No expenses or refunds in EUR in the selected month."].exists)
    }

    @MainActor
    func testEmptyThenDemoAnalytics() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.buttons[AccessibilityID.loadDemo].waitForExistence(timeout: 15))
        app.tabBars.buttons["Home"].tap()
        app.buttons["Analytics"].tap()
        XCTAssertTrue(app.staticTexts["No expenses or refunds in these two months."].waitForExistence(timeout: 5))
        app.navigationBars.buttons["FinAI"].tap()
        app.buttons[AccessibilityID.loadDemo].tap()
        app.alerts.buttons["Load demo data"].tap()
        XCTAssertTrue(app.staticTexts["Demo data · stored on this device"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Home"].tap()
        app.buttons["Analytics"].tap()
        XCTAssertTrue(app.staticTexts["Selected month net spending"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Previous month net spending"].exists)
        let list = app.collectionViews[AccessibilityID.spendingAnalytics]
        let categories = app.staticTexts["By category · EUR"]
        for _ in 0..<6 where !categories.isHittable { list.swipeUp() }
        XCTAssertTrue(categories.isHittable)
        let merchants = app.staticTexts["By merchant · EUR"]
        for _ in 0..<15 where !merchants.isHittable { list.swipeUp() }
        XCTAssertTrue(merchants.isHittable)
    }

    @MainActor
    func testBrowseMonthsAndOpenContributingTransactions() throws {
        try exerciseMonthBrowsing(appearance: .light, contentSize: "UICTContentSizeCategoryL")
    }

    @MainActor
    func testBrowseMonthsWithLargestTextInDarkMode() throws {
        try exerciseMonthBrowsing(appearance: .dark, contentSize: "UICTContentSizeCategoryAccessibilityXXXL")
    }

    @MainActor
    private func exerciseMonthBrowsing(appearance: XCUIDevice.Appearance, contentSize: String) throws {
        let previousAppearance = XCUIDevice.shared.appearance
        XCUIDevice.shared.appearance = appearance
        defer { XCUIDevice.shared.appearance = previousAppearance }
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
                               "-UIPreferredContentSizeCategoryName", contentSize]
        app.launch()
        XCTAssertTrue(app.buttons[AccessibilityID.loadDemo].waitForExistence(timeout: 15))
        app.buttons[AccessibilityID.loadDemo].tap()
        app.alerts.buttons["Load demo data"].tap()
        XCTAssertTrue(app.staticTexts["Demo data · stored on this device"].waitForExistence(timeout: 15))
        app.buttons["Analytics"].tap()
        XCTAssertTrue(app.staticTexts["September 2026"].waitForExistence(timeout: 5))
        app.buttons["Previous month"].tap()
        XCTAssertTrue(app.staticTexts["August 2026"].waitForExistence(timeout: 5))
        app.buttons["Next month"].tap()
        XCTAssertTrue(app.staticTexts["September 2026"].waitForExistence(timeout: 5))
        let total = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Selected month net spending")).firstMatch
        let listBeforeDrilldown = app.collectionViews[AccessibilityID.spendingAnalytics]
        let chartHeading = app.staticTexts["Daily net spending"]
        for _ in 0..<12 where !chartHeading.isHittable { listBeforeDrilldown.swipeUp() }
        XCTAssertTrue(chartHeading.isHittable)
        chartHeading.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.05, thenDragTo: listBeforeDrilldown.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)))
        if contentSize == "UICTContentSizeCategoryAccessibilityXXXL" {
            let dailyTotals = app.buttons["Daily totals"]
            for _ in 0..<8 where !dailyTotals.isHittable { listBeforeDrilldown.swipeUp() }
            XCTAssertTrue(dailyTotals.isHittable)
            dailyTotals.tap()
        }
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Analytics-\(appearance)-\(contentSize)"
        attachment.lifetime = .keepAlways
        add(attachment)
        if contentSize == "UICTContentSizeCategoryAccessibilityXXXL" {
            app.buttons["Daily totals"].tap()
        }
        for _ in 0..<12 where !total.isHittable { listBeforeDrilldown.swipeDown() }
        XCTAssertTrue(total.isHittable)
        total.tap()
        XCTAssertTrue(app.navigationBars["Transactions"].waitForExistence(timeout: 5))
        let list = app.collectionViews.firstMatch
        let transaction = list.buttons.firstMatch
        for _ in 0..<8 where !transaction.isHittable { list.swipeUp() }
        XCTAssertTrue(transaction.isHittable)
        transaction.tap()
        XCTAssertTrue(app.buttons[AccessibilityID.editTransaction].waitForExistence(timeout: 5))
    }
}
