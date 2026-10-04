//
//  RecurringPaymentsUITests.swift
//  FinAI
//
//  Created by Tommy on 30.09.26.
//

import XCTest

final class RecurringPaymentsUITests: XCTestCase {
    @MainActor
    func testEmptyThenDemoRegularPayments() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.buttons[AccessibilityID.loadDemo].waitForExistence(timeout: 15))
        app.tabBars.buttons["Analytics"].tap()
        app.buttons[AccessibilityID.openRecurringPayments].tap()
        XCTAssertTrue(app.staticTexts["No regular payment patterns found. More transaction history may be needed."].waitForExistence(timeout: 5))
        app.tabBars.buttons["Overview"].tap()
        app.buttons[AccessibilityID.loadDemo].tap()
        app.alerts.buttons["Load demo data"].tap()
        XCTAssertTrue(app.staticTexts["Demo data · stored on this device"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Analytics"].tap()
        let list = app.collectionViews[AccessibilityID.recurringPayments]
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["No regular payment patterns found. More transaction history may be needed."].exists)
        let interval = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Monthly")).firstMatch
        for _ in 0..<3 where !interval.exists { list.swipeUp() }
        XCTAssertTrue(interval.exists, app.debugDescription)
        let subscription = app.staticTexts["Possible subscription"]
        for _ in 0..<12 where !subscription.isHittable { list.swipeUp() }
        XCTAssertTrue(subscription.isHittable)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Spotify")).firstMatch.exists)
    }
}
