//
//  TransactionSearchUITests.swift
//  FinAI
//
//  Created by Tommy on 28.09.26.
//

import XCTest

final class TransactionSearchUITests: XCTestCase {
    @MainActor
    func testSearchFilterEmptyStateResetAndDetails() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let demo = app.buttons[AccessibilityID.loadDemo]
        XCTAssertTrue(demo.waitForExistence(timeout: 15))
        demo.tap()
        app.alerts.buttons["Load demo data"].tap()
        XCTAssertTrue(app.staticTexts["Demo data · stored on this device"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Transactions"].tap()
        let search = app.searchFields.firstMatch
        if !search.isHittable { app.swipeDown() }
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("amazon")
        app.keyboards.buttons["Search"].tap()
        let list = app.collectionViews[AccessibilityID.transactionList]
        XCTAssertTrue(list.staticTexts["Amazon"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(list.staticTexts["REWE"].exists)
        app.buttons[AccessibilityID.transactionFilters].tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Transaction type")).firstMatch.tap()
        app.buttons["Refund"].tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(list.staticTexts["Refund"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(list.staticTexts["Expense"].exists)
        list.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Amazon")).firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Transaction details"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        search.tap()
        search.typeText("notfound")
        app.keyboards.buttons["Search"].tap()
        XCTAssertTrue(app.staticTexts["No matching transactions"].waitForExistence(timeout: 5))
        app.buttons[AccessibilityID.resetTransactionFilters].tap()
        XCTAssertTrue(list.staticTexts["REWE"].firstMatch.waitForExistence(timeout: 5))
    }
}
