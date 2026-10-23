//
//  ForecastUITests.swift
//  FinAIUITests
//
//  Created by Tommy on 23.10.26.
//

import XCTest

final class ForecastUITests: XCTestCase {
    @MainActor
    func testForecastShowsAmountsAssumptionsAndCalculationDetails() throws {
        let appearance = XCUIDevice.shared.appearance
        XCUIDevice.shared.appearance = .light
        defer { XCUIDevice.shared.appearance = appearance }
        try exerciseForecast(largeText: false)
    }

    @MainActor
    func testForecastInDarkModeWithAccessibilityText() throws {
        let appearance = XCUIDevice.shared.appearance
        XCUIDevice.shared.appearance = .dark
        defer { XCUIDevice.shared.appearance = appearance }
        try exerciseForecast(largeText: true)
    }

    @MainActor
    func testEmptyHistoryDoesNotShowZeroForecast() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Plan"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Plan"].tap()
        app.buttons[AccessibilityID.openMonthForecast].tap()
        XCTAssertTrue(app.staticTexts["Import last month’s transactions to build a forecast."].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Estimated month-end net flow"].exists)
        app.navigationBars["Month-end forecast"].buttons["Done"].tap()
        XCTAssertTrue(app.buttons[AccessibilityID.openMonthForecast].waitForExistence(timeout: 10))
    }

    @MainActor
    private func exerciseForecast(largeText: Bool) throws {
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
            2026-09-30,Synthetic future record,-999.00,EUR,expense
            """
        app.launch()
        XCTAssertTrue(app.navigationBars["Import transactions"].waitForExistence(timeout: 15))
        let account = app.textFields[AccessibilityID.importAccountName]
        for _ in 0..<12 where !account.isHittable { app.swipeUp() }
        XCTAssertTrue(account.waitForExistence(timeout: 10))
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
        XCTAssertTrue(app.navigationBars["Month-end forecast"].waitForExistence(timeout: 10))
        let spending = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@",
                                                           "Estimated month-end net spending", "€90.00")).firstMatch
        for _ in 0..<12 where !spending.isHittable || spending.frame.maxY > app.frame.maxY - 40 { app.swipeUp() }
        XCTAssertTrue(spending.exists)
        XCTAssertTrue(spending.isHittable)
        XCTAssertLessThanOrEqual(spending.frame.maxY, app.frame.maxY - 40)
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = largeText ? "Forecast-dark-accessibility" : "Forecast-regular"
        image.lifetime = .keepAlways
        add(image)
        let flow = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@",
                                                       "Estimated month-end net flow", "1,910.00")).firstMatch
        for _ in 0..<8 where !flow.isHittable { app.swipeUp() }
        XCTAssertTrue(flow.exists)
        let details = app.buttons["How this is calculated"]
        for _ in 0..<10 where !details.isHittable { app.swipeUp() }
        details.tap()
        let variable = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@",
                                                           "Estimated remaining ordinary expenses", "€40.00")).firstMatch
        for _ in 0..<10 where !variable.isHittable { app.swipeUp() }
        XCTAssertTrue(variable.exists)
        app.navigationBars["Month-end forecast"].buttons["Done"].tap()
        XCTAssertTrue(app.buttons[AccessibilityID.openMonthForecast].waitForExistence(timeout: 10))
    }
}
