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
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let demoButton = app.buttons["loadDemo"]
        XCTAssertTrue(demoButton.waitForExistence(timeout: 15))
        demoButton.tap()
        app.alerts.buttons["Cancel"].tap()
        XCTAssertTrue(demoButton.exists)
        demoButton.tap()
        app.alerts.buttons["Load demo data"].tap()
        XCTAssertTrue(app.staticTexts["Demo data · stored on this device"].waitForExistence(timeout: 15))
        let overviewImage = XCTAttachment(screenshot: app.screenshot())
        overviewImage.name = "Overview"
        overviewImage.lifetime = .keepAlways
        add(overviewImage)
        app.tabBars.buttons["Transactions"].tap()
        let list = app.collectionViews["transactionList"]
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        list.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Transaction details"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Synthetic demo data"].exists)
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
