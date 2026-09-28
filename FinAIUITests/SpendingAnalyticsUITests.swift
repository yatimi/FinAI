//
//  SpendingAnalyticsUITests.swift
//  FinAI
//
//  Created by Tommy on 28.09.26.
//

import XCTest

final class SpendingAnalyticsUITests: XCTestCase {
    @MainActor
    func testEmptyThenDemoAnalytics() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.buttons["loadDemo"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Analytics"].tap()
        XCTAssertTrue(app.staticTexts["No expenses or refunds in these two months."].waitForExistence(timeout: 5))
        app.tabBars.buttons["Overview"].tap()
        app.buttons["loadDemo"].tap()
        app.alerts.buttons["Load demo data"].tap()
        XCTAssertTrue(app.staticTexts["Demo data · stored on this device"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Analytics"].tap()
        XCTAssertTrue(app.staticTexts["Current month net spending"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Previous month net spending"].exists)
        let list = app.collectionViews["spendingAnalytics"]
        let categories = app.staticTexts["By category · EUR"]
        for _ in 0..<6 where !categories.isHittable { list.swipeUp() }
        XCTAssertTrue(categories.isHittable)
        let merchants = app.staticTexts["By merchant · EUR"]
        for _ in 0..<15 where !merchants.isHittable { list.swipeUp() }
        XCTAssertTrue(merchants.isHittable)
    }
}
