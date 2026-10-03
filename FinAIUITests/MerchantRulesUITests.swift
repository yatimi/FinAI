//
//  MerchantRulesUITests.swift
//  FinAIUITests
//
//  Created by Tommy on 02.10.26.
//

import XCTest

final class MerchantRulesUITests: XCTestCase {
    @MainActor
    func testSaveCorrectionApplyOnRebuiltPreviewAndDeleteRule() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["FINAI_TEST_CSV"] = "date,description,amount,currency,type\n2026-09-01,REWE MARKT 123,-12.50,EUR,expense"
        app.launch()
        let account = app.textFields["importAccountName"]
        XCTAssertTrue(account.waitForExistence(timeout: 15))
        account.tap()
        account.typeText("Test bank")
        app.keyboards.buttons["Done"].tap()
        let preview = app.buttons["previewImport"]
        reveal(preview, app: app)
        preview.tap()
        XCTAssertTrue(app.navigationBars["Review import"].waitForExistence(timeout: 10))
        let saveRule = app.buttons["saveRule-2"]
        reveal(saveRule, app: app)
        saveRule.tap()
        XCTAssertTrue(app.navigationBars["Merchant rules"].waitForExistence(timeout: 10))
        let merchant = app.textFields["ruleMerchant"]
        reveal(merchant, app: app)
        merchant.tap()
        merchant.typeText(" Family")
        app.keyboards.buttons["Done"].tap()
        let save = app.buttons["saveMerchantRule"]
        reveal(save, app: app)
        save.tap()
        XCTAssertTrue(app.buttons["Add rule"].waitForExistence(timeout: 10))
        app.navigationBars["Merchant rules"].buttons["Close"].tap()
        for _ in 0..<10 where !app.buttons["Edit mapping"].isHittable { app.swipeDown() }
        app.buttons["Edit mapping"].tap()
        reveal(preview, app: app)
        preview.tap()
        XCTAssertTrue(app.navigationBars["Review import"].waitForExistence(timeout: 10))
        let suggested = app.textFields["Merchant or payee"].firstMatch
        reveal(suggested, app: app)
        XCTAssertEqual(suggested.value as? String, "REWE Family")
        app.navigationBars["Review import"].buttons["Close"].tap()
        app.tabBars.buttons["Accounts"].tap()
        app.buttons["Merchant rules"].tap()
        XCTAssertTrue(app.navigationBars["Merchant rules"].waitForExistence(timeout: 10))
        let delete = app.buttons["Delete rule"]
        reveal(delete, app: app)
        delete.tap()
        app.alerts.buttons["Cancel"].tap()
        XCTAssertTrue(delete.exists)
        delete.tap()
        app.alerts.buttons["Delete rule"].tap()
        XCTAssertTrue(app.staticTexts["No merchant rules saved."].waitForExistence(timeout: 10))
    }

    @MainActor
    private func reveal(_ element: XCUIElement, app: XCUIApplication) {
        for _ in 0..<12 where !element.isHittable { app.swipeUp() }
        XCTAssertTrue(element.isHittable)
    }
}
