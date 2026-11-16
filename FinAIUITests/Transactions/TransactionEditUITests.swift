//
//  TransactionEditUITests.swift
//  FinAIUITests
//
//  Created by Tommy on 07.10.26.
//

import XCTest

final class TransactionEditUITests: XCTestCase {
    @MainActor
    func testEditFromListValidateDiscardAndSaveWithOriginals() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["FINAI_TEST_CSV"] = "date,description,amount,currency,type\n2026-09-01,REWE MARKT 123,-12.50,EUR,expense"
        app.launch()
        let account = app.textFields[AccessibilityID.importAccountName]
        XCTAssertTrue(account.waitForExistence(timeout: 15))
        account.tap()
        account.typeText("Edit bank")
        app.keyboards.buttons["Done"].tap()
        let preview = app.buttons[AccessibilityID.previewImport]
        for _ in 0..<8 where !preview.isHittable { app.swipeUp() }
        preview.tap()
        XCTAssertTrue(app.navigationBars["Review import"].waitForExistence(timeout: 10))
        app.buttons[AccessibilityID.confirmSelectedImport].tap()
        app.alerts.buttons["Confirm import"].tap()
        XCTAssertTrue(app.navigationBars["Transactions"].waitForExistence(timeout: 10))
        let list = app.collectionViews[AccessibilityID.transactionList]
        list.buttons.firstMatch.swipeLeft()
        app.buttons["Edit transaction"].tap()
        XCTAssertTrue(app.navigationBars["Edit transaction"].waitForExistence(timeout: 5))
        let save = app.buttons[AccessibilityID.saveTransaction]
        XCTAssertFalse(save.isEnabled)
        let merchant = app.textFields[AccessibilityID.editTransactionMerchant]
        merchant.tap()
        merchant.typeText(" Corrected\n")
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.alerts["Discard changes?"].waitForExistence(timeout: 5))
        app.alerts.buttons["Keep editing"].tap()
        app.buttons["Cancel"].tap()
        app.alerts.buttons["Discard changes"].tap()
        XCTAssertTrue(app.navigationBars["Transaction details"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["REWE"].exists)
        app.buttons[AccessibilityID.editTransaction].tap()
        XCTAssertTrue(app.navigationBars["Edit transaction"].waitForExistence(timeout: 5))
        merchant.tap()
        merchant.typeText(" Corrected\n")
        let currency = app.textFields[AccessibilityID.editTransactionCurrency]
        currency.tap()
        currency.typeText("X")
        save.tap()
        let validation = app.staticTexts[AccessibilityID.transactionEditError]
        XCTAssertTrue(validation.waitForExistence(timeout: 5))
        XCTAssertEqual(validation.label, "Enter a supported three-letter currency code, such as EUR or USD.", app.debugDescription)
        currency.tap()
        currency.typeText(XCUIKeyboardKey.delete.rawValue + "\n")
        let amount = app.textFields[AccessibilityID.editTransactionAmount]
        for _ in 0..<6 where !amount.isHittable { app.swipeDown() }
        XCTAssertTrue(amount.isHittable)
        amount.tap()
        let currentAmount = try XCTUnwrap(amount.value as? String)
        amount.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentAmount.count) + "25.75")
        save.tap()
        XCTAssertTrue(app.navigationBars["Transaction details"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["REWE Corrected"].exists)
        XCTAssertTrue(app.staticTexts["Original values"].exists)
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "Corrected transaction with original values"
        image.lifetime = .keepAlways
        add(image)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["REWE Corrected"].waitForExistence(timeout: 5))
        list.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Original values"].waitForExistence(timeout: 5))
        let originalDescription = app.staticTexts["REWE MARKT 123"]
        for _ in 0..<4 where !originalDescription.exists { app.swipeUp() }
        XCTAssertTrue(originalDescription.exists)
    }
}
