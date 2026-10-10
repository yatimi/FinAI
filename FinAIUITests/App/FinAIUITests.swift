//
//  FinAIUITests.swift
//  FinAI
//
//  Created by Tommy on 26.09.26.
//

import XCTest

final class FinAIUITests: XCTestCase {
    @MainActor
    func testDemoAndTransactionDetails() throws {
        try exerciseDemoAndDetails(appearance: .light, appearanceArguments: [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL"
        ])
    }

    @MainActor
    func testDemoAndDetailsWithLargeTextInDarkMode() throws {
        try exerciseDemoAndDetails(appearance: .dark, appearanceArguments: [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ])
    }

    @MainActor
    private func exerciseDemoAndDetails(
        appearance: XCUIDevice.Appearance,
        appearanceArguments: [String]
    ) throws {
        let previousAppearance = XCUIDevice.shared.appearance
        XCUIDevice.shared.appearance = appearance
        defer { XCUIDevice.shared.appearance = previousAppearance }
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"] + appearanceArguments
        app.launch()
        let demoButton = app.buttons[AccessibilityID.loadDemo]
        XCTAssertTrue(demoButton.waitForExistence(timeout: 15))
        let emptyImage = XCTAttachment(screenshot: app.screenshot())
        emptyImage.name = "Empty overview"
        emptyImage.lifetime = .keepAlways
        add(emptyImage)
        demoButton.tap()
        app.alerts.buttons["Cancel"].tap()
        XCTAssertTrue(demoButton.exists)
        demoButton.tap()
        app.alerts.buttons["Load demo data"].tap()
        XCTAssertTrue(app.staticTexts["Demo data · stored on this device"].waitForExistence(timeout: 15))
        let dashboard = app.scrollViews[AccessibilityID.dashboard]
        XCTAssertTrue(dashboard.waitForExistence(timeout: 5))
        XCTAssertTrue(dashboard.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Net spending")).firstMatch.exists)
        XCTAssertTrue(dashboard.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Income")).firstMatch.exists)
        dashboard.swipeUp()
        XCTAssertTrue(dashboard.staticTexts["USD"].waitForExistence(timeout: 5))
        let overviewImage = XCTAttachment(screenshot: app.screenshot())
        overviewImage.name = "Overview"
        overviewImage.lifetime = .keepAlways
        add(overviewImage)
        app.tabBars.buttons["Transactions"].tap()
        let list = app.collectionViews[AccessibilityID.transactionList]
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        list.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Transaction details"].waitForExistence(timeout: 5))
        let provenance = app.staticTexts["Synthetic demo data"]
        for _ in 0..<6 where !provenance.exists {
            app.swipeUp()
        }
        XCTAssertTrue(provenance.exists)
        let detailImage = XCTAttachment(screenshot: app.screenshot())
        detailImage.name = "Transaction details"
        detailImage.lifetime = .keepAlways
        add(detailImage)
        app.buttons["Done"].tap()
        app.tabBars.buttons["Accounts"].tap()
        XCTAssertTrue(app.staticTexts["Demo current account"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Demo savings"].exists)
    }
}
